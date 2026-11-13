import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/track.dart';

class DeezerException implements Exception {
  const DeezerException(this.message);
  final String message;

  @override
  String toString() => 'DeezerException: $message';
}

class OfflineException implements Exception {
  const OfflineException();
}

class DeezerService {
  DeezerService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Track>> trending({int limit = kDiscoverLimit}) async {
    final data = await _getJson(
      Uri.https(kDeezerHost, '/chart/0/tracks', {'limit': '$limit'}),
    );
    return _mapList(data['data'] as List<dynamic>?);
  }

  Future<List<Track>> search(String query, {int limit = kDiscoverLimit}) async {
    final data = await _getJson(
      Uri.https(kDeezerHost, '/search', {'q': query, 'limit': '$limit'}),
    );
    return _mapList(data['data'] as List<dynamic>?);
  }

  Future<Track> trackById(String id) async {
    final numeric = int.tryParse(id.replaceFirst('deezer_', ''));
    if (numeric == null) throw DeezerException('bad id: $id');
    final data = await _getJson(Uri.https(kDeezerHost, '/track/$numeric'));
    return _mapTrack(data);
  }

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    http.Response res;
    try {
      res = await _client.get(url).timeout(const Duration(seconds: 12));
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    }
    if (res.statusCode != 200) {
      throw DeezerException('HTTP ${res.statusCode} for $url');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  List<Track> _mapList(List<dynamic>? items) => <Track>[
    for (final item in items ?? const <dynamic>[])
      _mapTrack(item as Map<String, dynamic>),
  ];

  Track _mapTrack(Map<String, dynamic> t) {
    final album = t['album'] as Map<String, dynamic>?;
    final artUrl =
        album?['cover_big'] as String? ?? album?['cover_medium'] as String?;
    return Track(
      id: 'deezer_${t['id']}',
      title: (t['title'] ?? 'Unknown title') as String,
      artist:
          (t['artist'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown artist',
      uri: (t['preview'] ?? '') as String,
      artUrl: (artUrl != null && artUrl.isNotEmpty) ? artUrl : null,
      isLocal: false,
      isPreview: true,
      duration: null,
    );
  }
}
