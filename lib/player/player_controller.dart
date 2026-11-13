import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../models/track.dart';
import '../services/deezer_service.dart';
import '../services/storage_service.dart';

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.playing,
    required this.processingState,
    required this.queue,
    required this.currentIndex,
    required this.hasNext,
    required this.hasPrevious,
  });

  final bool playing;
  final ProcessingState processingState;
  final List<Track> queue;
  final int currentIndex;
  final bool hasNext;
  final bool hasPrevious;

  Track? get currentTrack => currentIndex >= 0 && currentIndex < queue.length
      ? queue[currentIndex]
      : null;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.position,
    required this.buffered,
    required this.duration,
  });

  final Duration position;
  final Duration buffered;
  final Duration? duration;
}

class PlayerController extends ChangeNotifier {
  PlayerController({required this._storage, required this._deezer}) {
    _favorites = _storage.loadFavorites();
    _favoriteIds = _favorites.map((t) => t.id).toSet();
    _listen();
    unawaited(_restoreLastPlayed());
  }

  final StorageService _storage;
  final DeezerService _deezer;
  final AudioPlayer _player = AudioPlayer();

  List<Track> _queue = const [];
  Map<String, Track> _tracksById = const {};
  List<Track> _favorites = const [];
  Set<String> _favoriteIds = const {};
  LoopMode repeatMode = LoopMode.off;
  bool shuffleOn = false;

  DateTime _lastToggle = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<String> _refetchedIds = {};
  final Set<String> _retryIds = {};
  Future<void> _loadChain = Future.value();
  int _loadGeneration = 0;
  bool _isPreparing = false;

  bool get isPreparing => _isPreparing;

  Future<void> _enqueueLoad(Future<void> Function() task) {
    final generation = ++_loadGeneration;
    Future<void> run() async {
      try {
        if (generation != _loadGeneration) return;
        await task();
      } finally {
        if (generation == _loadGeneration && _isPreparing) {
          _isPreparing = false;
          notifyListeners();
        }
      }
    }

    _loadChain = _loadChain.then((_) => run());
    return _loadChain;
  }

  final _messages = StreamController<String>.broadcast();
  StreamSubscription<int?>? _indexSub;

  ValueStream<ProgressSnapshot> get progressStream => Rx.combineLatest3(
    _player.positionStream,
    _player.bufferedPositionStream,
    _player.durationStream,
    (Duration position, Duration buffered, Duration? duration) =>
        ProgressSnapshot(
          position: position,
          buffered: buffered,
          duration: duration,
        ),
  ).shareValue();

  ValueStream<PlayerSnapshot> get stateStream => Rx.combineLatest4(
    _player.playingStream,
    _player.processingStateStream,
    _player.sequenceStateStream,
    _player.currentIndexStream,
    (bool playing, ProcessingState processing, SequenceState? seq, int? _) =>
        PlayerSnapshot(
          playing: playing,
          processingState: processing,
          queue: _queueFromSequence(),
          currentIndex: seq?.currentIndex ?? 0,
          hasNext: _player.hasNext,
          hasPrevious: _player.hasPrevious,
        ),
  ).shareValue();

  Stream<String> get messages => _messages.stream;

  bool get isPlaying => _player.playing;
  bool get isBuffering =>
      _player.processingState == ProcessingState.loading ||
      _player.processingState == ProcessingState.buffering;
  bool get isCompleted => _player.processingState == ProcessingState.completed;

  List<Track> get queue => _queueFromSequence();

  Track? get currentTrack {
    final seq = _player.sequenceState;
    final i = seq.currentIndex;
    if (i == null || i < 0 || i >= seq.effectiveSequence.length) {
      return null;
    }
    final tag = seq.effectiveSequence[i].tag;
    if (tag is MediaItem) return _tracksById[tag.id];
    return null;
  }

  List<Track> _queueFromSequence() {
    final seq = _player.sequenceState;
    final effective = seq.effectiveSequence;
    if (effective.isEmpty) return _queue;
    return [
      for (final source in effective)
        if (source.tag is MediaItem)
          if (_tracksById[(source.tag as MediaItem).id] != null)
            _tracksById[(source.tag as MediaItem).id]!,
    ];
  }

  Future<void> playQueue(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;
    if (!_isPreparing) {
      _isPreparing = true;
      notifyListeners();
    }
    final startAt = initialIndex.clamp(0, tracks.length - 1);
    final startTitle = tracks[startAt].title;
    return _enqueueLoad(() async {
      _queue = List.of(tracks);
      _tracksById = {for (final t in tracks) t.id: t};
      _refetchedIds.clear();
      _retryIds.clear();
      try {
        await _player.setAudioSources([
          for (final t in _queue) _sourceFor(t),
        ], initialIndex: startAt);
        await _player.play();
        await _saveLastPlayed();
        notifyListeners();
      } on PlayerException catch (e) {
        _messages.add('Could not play "$startTitle".');
        debugPrint(
          'playQueue PlayerException: code=${e.code} message=${e.message}',
        );
      }
    });
  }

  Future<void> togglePlayPause() async {
    final now = DateTime.now();
    if (now.difference(_lastToggle) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastToggle = now;
    try {
      if (isCompleted) {
        await _player.seek(
          Duration.zero,
          index: _player.sequenceState.currentIndex,
        );
        await _player.play();
        return;
      }
      if (_queue.isEmpty) return;
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      await _saveLastPlayed();
    } on PlayerException catch (e) {
      debugPrint('togglePlayPause PlayerException: code=${e.code}');
      await _handlePlaybackError();
    }
  }

  Future<void> next() async {
    try {
      if (_player.hasNext) {
        await _player.seekToNext();
      } else {
        await _player.seek(Duration.zero);
      }
      await _saveLastPlayed();
    } on PlayerException {
      await _handlePlaybackError();
    }
  }

  Future<void> previous() async {
    try {
      if (_player.position > const Duration(seconds: 3)) {
        await _player.seek(Duration.zero);
      } else if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else {
        await _player.seek(Duration.zero);
      }
      await _saveLastPlayed();
    } on PlayerException {
      await _handlePlaybackError();
    }
  }

  Future<void> jumpTo(int index) async {
    try {
      await _player.seek(Duration.zero, index: index);
      await _saveLastPlayed();
    } on PlayerException {
      await _handlePlaybackError();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> toggleShuffle() async {
    shuffleOn = !shuffleOn;
    await _player.setShuffleModeEnabled(shuffleOn);
    await _saveLastPlayed();
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    repeatMode = switch (repeatMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(repeatMode);
    notifyListeners();
  }

  Future<void> moveQueueItem(int from, int to) async {
    await _player.moveAudioSource(from, to);
    await _saveLastPlayed();
    notifyListeners();
  }

  bool isFavorite(Track track) => _favoriteIds.contains(track.id);

  Future<void> toggleFavorite(Track track) async {
    if (_favoriteIds.remove(track.id)) {
      _favorites.removeWhere((t) => t.id == track.id);
    } else {
      _favoriteIds.add(track.id);
      _favorites = [track, ..._favorites];
    }
    await _storage.saveFavorites(_favorites);
    notifyListeners();
  }

  List<Track> get favorites => List.unmodifiable(_favorites);

  Future<void> initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('audio_session configure failed: $e');
    }
  }

  AudioSource _sourceFor(Track t) =>
      AudioSource.uri(Uri.parse(t.uri), tag: _mediaItemFor(t));

  MediaItem _mediaItemFor(Track t) => MediaItem(
    id: t.id,
    title: t.title,
    artist: t.artist,
    artUri: t.isLocal
        ? t.artUri
        : (t.artUrl == null ? null : Uri.tryParse(t.artUrl!)),
    duration: t.duration ?? (t.isPreview ? const Duration(seconds: 30) : null),
  );

  void _listen() {
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('playback error: $e');
        unawaited(_handlePlaybackError());
      },
    );
    _indexSub = _player.currentIndexStream.listen((_) {
      _saveLastPlayedDebounced();
      notifyListeners();
    });
  }

  Future<void> _handlePlaybackError() async {
    final track = currentTrack;
    if (track == null) return;

    if (_retryIds.add(track.id)) {
      try {
        await _player.seek(
          Duration.zero,
          index: _player.sequenceState.currentIndex,
        );
        await _player.play();
        return;
      } on PlayerException {
        // transient recovery failed — fall through to refetch / skip
      }
    }

    if (!track.isLocal && !_refetchedIds.contains(track.id)) {
      _refetchedIds.add(track.id);
      try {
        final fresh = await _deezer.trackById(track.id);
        if (fresh.uri.isNotEmpty) {
          final i = _queue.indexWhere((t) => t.id == track.id);
          if (i >= 0) {
            _queue[i] = fresh;
            _tracksById[fresh.id] = fresh;
          }
          final idx = (_player.sequenceState.currentIndex ?? 0).clamp(
            0,
            _queue.length - 1,
          );
          await _enqueueLoad(() async {
            await _player.setAudioSources([
              for (final t in _queueFromSequence()) _sourceFor(t),
            ], initialIndex: idx);
            await _player.play();
          });
          return;
        }
      } catch (e) {
        debugPrint('preview re-fetch failed: $e');
      }
    }

    _messages.add('Skipping "${track.title}" — could not play it.');
    await next();
  }

  Future<void> _restoreLastPlayed() {
    return _enqueueLoad(() async {
      try {
        final last = _storage.loadLastPlayed();
        if (last == null || last.queue.isEmpty) return;
        _queue = last.queue;
        _tracksById = {for (final t in last.queue) t.id: t};
        await _player.setAudioSources(
          [for (final t in last.queue) _sourceFor(t)],
          initialIndex: last.index,
          initialPosition: last.position,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('restore failed: $e');
      }
    });
  }

  Future<void> _saveLastPlayed() async {
    final queue = _queueFromSequence();
    if (queue.isEmpty) return;
    final index = (_player.sequenceState.currentIndex ?? 0).clamp(
      0,
      queue.length - 1,
    );
    try {
      await _storage.saveLastPlayed(
        LastPlayed(queue: queue, index: index, position: _player.position),
      );
    } catch (e) {
      debugPrint('saveLastPlayed failed: $e');
    }
  }

  Timer? _saveDebounce;
  void _saveLastPlayedDebounced() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () => _saveLastPlayed());
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _saveDebounce?.cancel();
    _messages.close();
    super.dispose();
  }
}
