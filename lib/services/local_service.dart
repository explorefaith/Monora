import 'dart:io';
import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';

class AlbumInfo {
  const AlbumInfo({
    required this.id,
    required this.title,
    required this.artist,
    required this.songCount,
  });
  final int id;
  final String title;
  final String artist;
  final int songCount;
}

class ArtistInfo {
  const ArtistInfo({
    required this.id,
    required this.name,
    required this.trackCount,
  });
  final int id;
  final String name;
  final int trackCount;
}

class LocalService {
  final OnAudioQuery _query = OnAudioQuery();

  final Map<int, Uri?> _artworkCache = {};

  Future<List<Track>> loadSongs() async {
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
    );
    final tracks = <Track>[];
    for (final song in songs) {
      if (song.data.isEmpty) continue;
      final ms = song.duration ?? 0;
      tracks.add(
        Track(
          id: 'local_${song.id}',
          title: song.title,
          artist: song.artist ?? 'Unknown artist',
          uri: song.data,
          artUri: await artworkUri(song.id),
          localId: song.id,
          isLocal: true,
          isPreview: false,
          duration: ms > 0 ? Duration(milliseconds: ms) : null,
        ),
      );
    }
    return tracks;
  }

  Future<List<AlbumInfo>> loadAlbums() async {
    final albums = await _query.queryAlbums();
    return [
      for (final a in albums)
        AlbumInfo(
          id: a.id,
          title: a.album,
          artist: a.artist ?? 'Unknown artist',
          songCount: a.numOfSongs,
        ),
    ];
  }

  Future<List<ArtistInfo>> loadArtists() async {
    final artists = await _query.queryArtists();
    return [
      for (final a in artists)
        ArtistInfo(id: a.id, name: a.artist, trackCount: a.numberOfTracks ?? 0),
    ];
  }

  Future<List<Track>> songsOfAlbum(int albumId) async {
    final songs = await _query.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      albumId,
    );
    return songs.map(_songToTrack).toList();
  }

  Future<List<Track>> songsOfArtist(int artistId) async {
    final songs = await _query.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      artistId,
    );
    return songs.map(_songToTrack).toList();
  }

  Future<Uint8List?> artworkBytes(int id, ArtworkType type) =>
      _query.queryArtwork(id, type, size: 300);

  Future<Uri?> artworkUri(int songId) async {
    if (_artworkCache.containsKey(songId)) return _artworkCache[songId];

    Uri? uri;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/artwork_$songId.jpg');
      if (await file.exists() && await file.length() > 0) {
        uri = Uri.file(file.path);
      } else {
        final bytes = await _query.queryArtwork(
          songId,
          ArtworkType.AUDIO,
          size: 300,
        );
        if (bytes != null && bytes.isNotEmpty) {
          await file.writeAsBytes(bytes, flush: true);
          uri = Uri.file(file.path);
        }
      }
    } catch (_) {
      uri = null;
    }
    _artworkCache[songId] = uri;
    return uri;
  }

  Track _songToTrack(SongModel song) {
    final id = song.id;
    final ms = song.duration ?? 0;
    return Track(
      id: 'local_$id',
      title: song.title,
      artist: song.artist ?? 'Unknown artist',
      uri: song.data,
      localId: song.id,
      isLocal: true,
      isPreview: false,
      duration: ms > 0 ? Duration(milliseconds: ms) : null,
    );
  }
}
