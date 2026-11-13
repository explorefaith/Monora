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

  final String id;
  final String title;
  final String artist;

  final String uri;

  final String? artUrl;

  final Uri? artUri;

  final int? localId;
  final bool isLocal;

  final bool isPreview;

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
