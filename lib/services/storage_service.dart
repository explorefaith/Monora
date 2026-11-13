import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class LastPlayed {
  const LastPlayed({
    required this.queue,
    required this.index,
    required this.position,
  });

  final List<Track> queue;
  final int index;
  final Duration position;
}

class StorageService {
  static const String _favoritesKey = 'monora.favorites.v1';
  static const String _lastPlayedKey = 'monora.last_played.v1';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('StorageService.init() has not completed');
    }
    return p;
  }

  List<Track> loadFavorites() {
    final raw = _p.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveFavorites(List<Track> tracks) {
    return _p.setString(
      _favoritesKey,
      jsonEncode(tracks.map((t) => t.toJson()).toList()),
    );
  }

  LastPlayed? loadLastPlayed() {
    final raw = _p.getString(_lastPlayedKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final queue = (json['queue'] as List<dynamic>? ?? const [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
      if (queue.isEmpty) return null;
      return LastPlayed(
        queue: queue,
        index: (json['index'] as int? ?? 0).clamp(0, queue.length - 1),
        position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> saveLastPlayed(LastPlayed last) {
    return _p.setString(
      _lastPlayedKey,
      jsonEncode({
        'queue': last.queue.map((t) => t.toJson()).toList(),
        'index': last.index,
        'positionMs': last.position.inMilliseconds,
      }),
    );
  }

  bool get batteryHintDismissed =>
      _p.getBool('monora.battery_hint.v1') ?? false;

  Future<void> dismissBatteryHint() =>
      _p.setBool('monora.battery_hint.v1', true);
}
