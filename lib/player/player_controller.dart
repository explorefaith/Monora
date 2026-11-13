import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../models/track.dart';
import '../services/deezer_service.dart';
import '../services/storage_service.dart';

/// Coarse snapshot: everything the player UI needs EXCEPT position ticks,
/// so screens never rebuild 5×/second on position (§6).
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

/// Fine-grained progress snapshot — consumed only by seek bars and time
/// text (§4, §6).
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

/// Single owner of the one [AudioPlayer] (§4): queue, favorites, last-played
/// persistence. The state source of truth is the player's own streams —
/// never a local bool.
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
  final _messages = StreamController<String>.broadcast();
  StreamSubscription<int?>? _indexSub;

  // ---- streams, combined with rxdart (§4) ----

  /// Position / buffered / duration — ticks. Only seek bars listen.
  Stream<ProgressSnapshot> get progressStream => Rx.combineLatest3(
    _player.positionStream,
    _player.bufferedPositionStream,
    _player.durationStream,
    (Duration position, Duration buffered, Duration? duration) =>
        ProgressSnapshot(
          position: position,
          buffered: buffered,
          duration: duration,
        ),
  ).share();

  /// Playing / processing / queue / index — fires only on state changes.
  Stream<PlayerSnapshot> get stateStream => Rx.combineLatest3(
    _player.playerStateStream,
    _player.sequenceStateStream,
    _player.currentIndexStream,
    (PlayerState state, SequenceState? seq, int? _) => PlayerSnapshot(
      playing: state.playing,
      processingState: state.processingState,
      queue: _queueFromSequence(),
      currentIndex: seq?.currentIndex ?? 0,
      hasNext: _player.hasNext,
      hasPrevious: _player.hasPrevious,
    ),
  ).share();

  /// User-facing messages (broken URL skips, etc.) → snackbars.
  Stream<String> get messages => _messages.stream;

  // ---- derived getters ----

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

  // ---- playback control (§4) ----

  /// Loads [tracks] as the queue and starts playing from [initialIndex].
  Future<void> playQueue(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List.of(tracks);
    _tracksById = {for (final t in tracks) t.id: t};
    _refetchedIds.clear();
    try {
      await _player.setAudioSources([
        for (final t in _queue) _sourceFor(t),
      ], initialIndex: initialIndex.clamp(0, _queue.length - 1));
      await _player.play();
      await _saveLastPlayed();
      notifyListeners();
    } on PlayerException catch (e) {
      _messages.add(
        'Could not play "${_queue[initialIndex.clamp(0, _queue.length - 1)].title}".',
      );
      debugPrint(
        'playQueue PlayerException: code=${e.code} message=${e.message}',
      );
    }
  }

  /// Play/Pause from ANY surface (§4). The truth is the player state.
  Future<void> togglePlayPause() async {
    final now = DateTime.now();
    if (now.difference(_lastToggle) < const Duration(milliseconds: 300)) {
      return; // debounce rapid taps (§4)
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

  /// Previous restarts the song if position > 3s, else goes to prior track (§4).
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

  /// Queue reorder by drag (§3.D).
  Future<void> moveQueueItem(int from, int to) async {
    await _player.moveAudioSource(from, to);
    await _saveLastPlayed();
    notifyListeners();
  }

  // ---- favorites (§3.B) ----

  bool isFavorite(Track track) => _favoriteIds.contains(track.id);

  Future<void> toggleFavorite(Track track) async {
    if (_favoriteIds.remove(track.id)) {
      _favorites.removeWhere((t) => t.id == track.id);
    } else {
      _favoriteIds.add(track.id);
      _favorites = [track, ..._favorites]; // most recent first
    }
    await _storage.saveFavorites(_favorites);
    notifyListeners();
  }

  List<Track> get favorites => List.unmodifiable(_favorites);

  // ---- audio session (§4) ----

  /// Configure focus + "becoming noisy" behavior. just_audio already pauses
  /// on focus loss and headphone unplug; this tunes it for music.
  Future<void> initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('audio_session configure failed: $e');
    }
  }

  // ---- internals ----

  AudioSource _sourceFor(Track t) =>
      AudioSource.uri(Uri.parse(t.uri), tag: _mediaItemFor(t));

  MediaItem _mediaItemFor(Track t) => MediaItem(
    id: t.id,
    title: t.title,
    artist: t.artist,
    artUri: t.isLocal
        ? t.artUri
        : (t.artUrl == null ? null : Uri.tryParse(t.artUrl!)),
    duration: t.duration,
  );

  void _listen() {
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('playback error: $e');
        unawaited(_handlePlaybackError());
      },
    );
    _indexSub = _player.currentIndexStream.listen(
      (_) => _saveLastPlayedDebounced(),
    );
  }

  /// Expired Deezer preview → re-fetch once before play (§4). Broken URL →
  /// skip to next with a snackbar (§4).
  Future<void> _handlePlaybackError() async {
    final track = currentTrack;
    if (track == null) return;

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
          await _player.setAudioSources([
            for (final t in _queueFromSequence()) _sourceFor(t),
          ], initialIndex: idx);
          await _player.play();
          return;
        }
      } catch (e) {
        debugPrint('preview re-fetch failed: $e');
      }
    }

    _messages.add('Skipping "${track.title}" — could not play it.');
    await next();
  }

  Future<void> _restoreLastPlayed() async {
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
      debugPrint('restore failed: $e'); // restore is best-effort
    }
  }

  /// Persist on pause and on track change; restore happens paused (§4).
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
    _player.dispose();
    super.dispose();
  }
}
