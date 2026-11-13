/// One shared model for every playable song — local or online (§1).
/// The UI and [PlayerController] never care where a track came from.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    this.artUrl,
    this.artUri,
    this.localId,
    this.isLocal = false,
    this.isPreview = false,
    this.duration,
  });

  /// Stable identity across queue, favorites and persistence.
  final String id;
  final String title;
  final String artist;

  /// Playable location: a local file path or an https URL
  /// (30s preview for Deezer tracks).
  final String uri;

  /// Network cover art (Deezer album covers).
  final String? artUrl;

  /// Local artwork file URI for the lock screen / notification (§4).
  final Uri? artUri;

  /// on_audio_query song id, for local tracks only.
  final int? localId;
  final bool isLocal;

  /// True for Deezer tracks — their uri is a 30s preview.
  final bool isPreview;

  /// Known duration (local files); online previews resolve on load.
  final Duration? duration;

  Track copyWith({String? uri, Uri? artUri, Duration? duration}) => Track(
    id: id,
    title: title,
    artist: artist,
    uri: uri ?? this.uri,
    artUrl: artUrl,
    artUri: artUri ?? this.artUri,
    localId: localId,
    isLocal: isLocal,
    isPreview: isPreview,
    duration: duration ?? this.duration,
  );

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    uri: json['uri'] as String,
    artUrl: json['artUrl'] as String?,
    artUri: json['artUri'] is String
        ? Uri.parse(json['artUri'] as String)
        : null,
    localId: json['localId'] as int?,
    isLocal: json['isLocal'] as bool? ?? false,
    isPreview: json['isPreview'] as bool? ?? false,
    duration: json['durationMs'] is int
        ? Duration(milliseconds: json['durationMs'] as int)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'uri': uri,
    'artUrl': artUrl,
    'artUri': artUri?.toString(),
    'localId': localId,
    'isLocal': isLocal,
    'isPreview': isPreview,
    'durationMs': duration?.inMilliseconds,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Track && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
