import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../core/transitions.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../services/local_service.dart';
import '../widgets/shimmer_list.dart';
import '../widgets/squish_button.dart';
import '../widgets/track_tile.dart';

enum _PermState { unknown, granted, denied, permanentlyDenied }

/// Library tab (§3.B.1): Songs / Albums / Artists from device storage,
/// with the friendly cream permission explainer flow.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with SingleTickerProviderStateMixin {
  _PermState _perm = _PermState.unknown;
  bool _loading = false;

  List<Track>? _songs;
  List<AlbumInfo>? _albums;
  List<ArtistInfo>? _artists;
  String _query = '';

  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    // Permission.audio maps to READ_MEDIA_AUDIO on Android 13+ and
    // READ_EXTERNAL_STORAGE below (§3.B.1, §5).
    final status = await Permission.audio.status;
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      setState(() => _perm = _PermState.granted);
      await _loadLibrary();
    } else if (status.isPermanentlyDenied) {
      setState(() => _perm = _PermState.permanentlyDenied);
    } else {
      setState(() => _perm = _PermState.denied);
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.audio.request();
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      setState(() => _perm = _PermState.granted);
      await _loadLibrary();
    } else if (status.isPermanentlyDenied) {
      setState(() => _perm = _PermState.permanentlyDenied);
    } else {
      setState(() => _perm = _PermState.denied);
    }
  }

  Future<void> _loadLibrary() async {
    final service = context.read<LocalService>();
    setState(() => _loading = true);
    try {
      final songs = await service.loadSongs();
      final albums = await service.loadAlbums();
      final artists = await service.loadArtists();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _albums = albums;
        _artists = artists;
        _loading = false;
      });
    } catch (e) {
      debugPrint('library load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Track> _filterSongs(List<Track> songs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return songs;
    return songs
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  void _play(List<Track> tracks, int index) {
    context.read<PlayerController>().playQueue(tracks, initialIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    switch (_perm) {
      case _PermState.unknown:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accentDeep),
        );
      case _PermState.denied:
      case _PermState.permanentlyDenied:
        return _explainer();
      case _PermState.granted:
        return _library();
    }
  }

  // ---- permission flow (§3.B.1): friendly cream explainer card ----

  Widget _explainer() {
    final permanentlyDenied = _perm == _PermState.permanentlyDenied;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(kRadiusCard),
              boxShadow: kCreamShadows,
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.library_music,
                      size: 32,
                      color: AppColors.accentDeep,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  Text('Your music, unlocked', style: AppText.title),
                  const SizedBox(height: Spacing.md),
                  Text(
                    permanentlyDenied
                        ? 'Monora needs your permission to see the songs on this device. It was denied earlier — please allow it in Settings.'
                        : 'Monora can play the songs already on this device. To see your library, allow access to music and audio.',
                    textAlign: TextAlign.center,
                    style: AppText.artist.copyWith(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: Spacing.xl),
                  SquishFilledButton(
                    label: permanentlyDenied ? 'Open settings' : 'Allow access',
                    onTap: permanentlyDenied
                        ? openAppSettings
                        : _requestPermission,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- library (permission granted) ----

  Widget _library() {
    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                kPagePadding,
                Spacing.lg,
                kPagePadding,
                Spacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Library', style: AppText.display),
                  const SizedBox(height: Spacing.lg),
                  _searchBar(),
                  const SizedBox(height: Spacing.md),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Artists'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_songsList(), _albumsGrid(), _artistsList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() => TextField(
    onChanged: (v) => setState(() => _query = v),
    style: AppText.body,
    decoration: InputDecoration(
      hintText: 'Search songs, artists…',
      hintStyle: AppText.artist,
      prefixIcon: const Icon(
        Icons.search,
        color: AppColors.textSecondary,
        size: 20,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: Spacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _songsList() {
    if (_loading && _songs == null) return const ShimmerList();
    final songs = _filterSongs(_songs ?? const []);
    if (songs.isEmpty) return _emptyState('No songs found on this device.');
    return RefreshIndicator(
      color: AppColors.accentDeep,
      onRefresh: _loadLibrary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        scrollCacheExtent: const ScrollCacheExtent.pixels(500), // §6
        itemCount: songs.length,
        itemBuilder: (context, i) =>
            TrackTile(track: songs[i], index: i, onTap: () => _play(songs, i)),
      ),
    );
  }

  Widget _albumsGrid() {
    if (_loading && _albums == null) return const ShimmerList();
    final albums = _albums ?? const <AlbumInfo>[];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? albums
        : albums
              .where(
                (a) =>
                    a.title.toLowerCase().contains(q) ||
                    a.artist.toLowerCase().contains(q),
              )
              .toList();
    if (filtered.isEmpty) return _emptyState('No albums found.');
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        kPagePadding,
        Spacing.md,
        kPagePadding,
        Spacing.lg,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.lg,
        crossAxisSpacing: Spacing.lg,
        childAspectRatio: 0.8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _AlbumCard(
        album: filtered[i],
        onTap: () => _openDetail(
          title: filtered[i].title,
          subtitle: filtered[i].artist,
          artworkId: filtered[i].id,
          artworkType: ArtworkType.ALBUM,
          load: () => context.read<LocalService>().songsOfAlbum(filtered[i].id),
        ),
      ),
    );
  }

  Widget _artistsList() {
    if (_loading && _artists == null) return const ShimmerList();
    final artists = _artists ?? const <ArtistInfo>[];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? artists
        : artists.where((a) => a.name.toLowerCase().contains(q)).toList();
    if (filtered.isEmpty) return _emptyState('No artists found.');
    return ListView.builder(
      padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.lg),
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final a = filtered[i];
        return _EntityRow(
          index: i,
          title: a.name,
          subtitle: '${a.trackCount} songs',
          artworkId: a.id,
          artworkType: ArtworkType.ARTIST,
          fallbackIcon: Icons.person,
          onTap: () => _openDetail(
            title: a.name,
            subtitle: '${a.trackCount} songs',
            artworkId: a.id,
            artworkType: ArtworkType.ARTIST,
            load: () => context.read<LocalService>().songsOfArtist(a.id),
          ),
        );
      },
    );
  }

  void _openDetail({
    required String title,
    required String subtitle,
    required int artworkId,
    required ArtworkType artworkType,
    required Future<List<Track>> Function() load,
  }) {
    Navigator.of(context).push<void>(
      FadeThroughRoute(
        page: _EntityDetailScreen(
          title: title,
          subtitle: subtitle,
          artworkId: artworkId,
          artworkType: artworkType,
          load: load,
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(kPagePadding),
      child: Text(
        message,
        style: AppText.artist.copyWith(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// ---- small shared pieces ----

/// Entity cover loaded as raw bytes (on_audio_query returns no URI here).
class _EntityCover extends StatelessWidget {
  const _EntityCover({required this.id, required this.type});

  final int id;
  final ArtworkType type;

  @override
  Widget build(BuildContext context) {
    final service = context.read<LocalService>();
    return FutureBuilder<Uint8List?>(
      future: service.artworkBytes(id, type),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
        }
        return const ColoredBox(
          color: AppColors.surfaceSunken,
          child: Center(
            child: Icon(Icons.music_note, color: AppColors.accentDeep),
          ),
        );
      },
    );
  }
}

/// 72px row for albums/artists that mirrors [TrackTile]'s layout (§2).
class _EntityRow extends StatelessWidget {
  const _EntityRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.artworkId,
    required this.artworkType,
    required this.fallbackIcon,
    this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final int artworkId;
  final ArtworkType artworkType;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StaggeredReveal(
      index: index,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          height: kListTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: kCoverSmall,
                  height: kCoverSmall,
                  child: _EntityCover(id: artworkId, type: artworkType),
                ),
              ),
              const SizedBox(width: kCoverGap),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.songTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              const SizedBox(
                width: kTapTarget,
                height: kTapTarget,
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, this.onTap});

  final AlbumInfo album;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusCard),
              child: _EntityCover(id: album.id, type: ArtworkType.ALBUM),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            album.title,
            style: AppText.songTitle.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            album.artist,
            style: AppText.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Album / artist detail: full-screen list of that entity's tracks.
class _EntityDetailScreen extends StatelessWidget {
  const _EntityDetailScreen({
    required this.title,
    required this.subtitle,
    required this.artworkId,
    required this.artworkType,
    required this.load,
  });

  final String title;
  final String subtitle;
  final int artworkId;
  final ArtworkType artworkType;
  final Future<List<Track>> Function() load;

  @override
  Widget build(BuildContext context) {
    final future = load(); // computed once per screen instance
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<Track>>(
          future: future,
          builder: (context, snap) {
            final loaded = snap.connectionState == ConnectionState.done;
            final tracks = snap.data ?? const <Track>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kPagePadding,
                    Spacing.md,
                    kPagePadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      SquishIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.display.copyWith(fontSize: 26),
                      ),
                      Text(subtitle, style: AppText.artist),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Expanded(
                  child: !loaded
                      ? const ShimmerList()
                      : tracks.isEmpty
                      ? Center(
                          child: Text(
                            'Nothing here yet.',
                            style: AppText.artist,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: Spacing.lg),
                          scrollCacheExtent: const ScrollCacheExtent.pixels(
                            500,
                          ),
                          itemCount: tracks.length,
                          itemBuilder: (context, i) => TrackTile(
                            track: tracks[i],
                            index: i,
                            stagger: false,
                            onTap: () => context
                                .read<PlayerController>()
                                .playQueue(tracks, initialIndex: i),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
