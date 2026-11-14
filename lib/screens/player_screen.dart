import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, ProcessingState;
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../core/transitions.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../widgets/cover_art.dart';
import '../widgets/squish_button.dart';
import '../widgets/seek_bar.dart';
import '../widgets/texture_overlay.dart';
import '../widgets/track_tile.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  static Route<void> route() => SheetUpRoute(page: const PlayerScreen());

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _blobs = AnimationController(
    vsync: this,
    duration: kBlobsLoop,
  );

  Color? _tint;
  String _tintedFor = '';

  @override
  void initState() {
    super.initState();
    if (!MediaQuery.of(context).disableAnimations) {
      _blobs.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations && _blobs.isAnimating) {
      _blobs.stop();
    }
  }

  @override
  void dispose() {
    _blobs.dispose();
    super.dispose();
  }

  Future<void> _computeTint(Track track) async {
    if (_tintedFor == track.id) return;
    _tintedFor = track.id;
    ImageProvider? provider;
    try {
      if (track.isLocal && track.artUri != null) {
        provider = FileImage(File(track.artUri!.toFilePath()));
      } else if (track.artUrl != null && track.artUrl!.isNotEmpty) {
        provider = NetworkImage(track.artUrl!);
      }
      if (provider == null) {
        if (mounted) setState(() => _tint = null);
        return;
      }
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        size: const Size(120, 120),
        maximumColorCount: 16,
      );
      final dominant = palette.dominantColor?.color;
      if (!mounted) return;
      setState(
        () => _tint = (dominant != null && dominant.computeLuminance() > 0.85)
            ? null
            : dominant,
      );
    } catch (_) {
      if (mounted) setState(() => _tint = null);
    }
  }

  Color get _backgroundColor =>
      Color.lerp(AppColors.background, _tint ?? AppColors.primary, 0.15)!;

  void _onVerticalDragUpdate(DragUpdateDetails details, double height) {
    final route = ModalRoute.of(context);
    if (route is! SheetUpRoute) return;
    final controller = route.controller;
    if (controller == null || details.delta.dy <= 0) return;
    controller.value = (controller.value - details.delta.dy / height).clamp(
      0.0,
      1.0,
    );
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final route = ModalRoute.of(context);
    if (route is! SheetUpRoute) return;
    final controller = route.controller;
    if (controller == null || controller.status != AnimationStatus.forward) {
      return;
    }
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity > 800 || controller.value < 0.65) {
      Navigator.of(context).pop();
    } else {
      controller.animateTo(1, duration: kPage, curve: kEnter);
    }
  }

  void _openQueue() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    final size = MediaQuery.of(context).size;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, size.height),
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            const Positioned.fill(child: _Blobs()),
            const Positioned.fill(child: TextureOverlay()),
            SafeArea(
              child: StreamBuilder<PlayerSnapshot>(
                stream: controller.stateStream,
                builder: (context, snap) {
                  final state = snap.data;
                  final track = state?.currentTrack;
                  if (track != null) {
                    _computeTint(track);
                  }
                  if (track == null) {
                    return Center(
                      child: Text('Nothing playing', style: AppText.artist),
                    );
                  }
                  final playing = state?.playing ?? false;
                  final buffering =
                      state?.processingState == ProcessingState.loading ||
                      state?.processingState == ProcessingState.buffering;
                  final coverSize =
                      (size.width - 2 * kPagePadding - 2 * Spacing.xl).clamp(
                        200.0,
                        340.0,
                      );

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kPagePadding,
                          vertical: Spacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SquishIconButton(
                              icon: Icons.keyboard_arrow_down,
                              iconSize: 26,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Text(
                              'NOW PLAYING',
                              style: AppText.caption.copyWith(
                                letterSpacing: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SquishIconButton(
                              icon: Icons.queue_music,
                              onTap: _openQueue,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: reduceMotion
                              ? const ClampingScrollPhysics()
                              : const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: Spacing.lg),

                              Hero(
                                tag: 'cover-art',
                                child: RepaintBoundary(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(end: playing ? 1.0 : 0.92),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, scale, child) =>
                                        Transform.scale(
                                          scale: scale,
                                          child: child,
                                        ),
                                    child: Container(
                                      width: coverSize,
                                      height: coverSize,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          Radii.coverLarge,
                                        ),
                                        boxShadow: creamShadows(deep: true),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Radii.coverLarge,
                                        ),
                                        child: CoverArt(
                                          track: track,
                                          size: coverSize,
                                          radius: Radii.coverLarge,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacing.xl),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kPagePadding,
                                ),
                                child: AnimatedSwitcher(
                                  duration: kPage,
                                  switchInCurve: kEnter,
                                  switchOutCurve: kExit,
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.05),
                                            end: Offset.zero,
                                          ).animate(anim),
                                          child: child,
                                        ),
                                      ),
                                  child: KeyedSubtree(
                                    key: ValueKey('meta_${track.id}'),
                                    child: Column(
                                      children: [
                                        Text(
                                          track.title,
                                          style: AppText.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: Spacing.xs + 2),
                                        Text(
                                          track.artist,
                                          style: AppText.artist,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacing.md),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kPagePadding + Spacing.sm,
                                ),
                                child: _FavoriteHeart(
                                  track: track,
                                  controller: controller,
                                ),
                              ),
                              const SizedBox(height: Spacing.md),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kPagePadding,
                                ),
                                child: SeekBar(controller: controller),
                              ),
                              const SizedBox(height: Spacing.lg),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kPagePadding,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SquishIconButton(
                                      icon: Icons.shuffle,
                                      selected: controller.shuffleOn,
                                      onTap: controller.toggleShuffle,
                                    ),
                                    SquishIconButton(
                                      icon: Icons.skip_previous,
                                      iconSize: 30,
                                      onTap: controller.previous,
                                    ),
                                    _BigPlayButton(
                                      controller: controller,
                                      buffering:
                                          buffering || controller.isPreparing,
                                      playing: playing,
                                    ),
                                    SquishIconButton(
                                      icon: Icons.skip_next,
                                      iconSize: 30,
                                      onTap: controller.next,
                                    ),
                                    SquishIconButton(
                                      icon: switch (controller.repeatMode) {
                                        LoopMode.one => Icons.repeat_one,
                                        LoopMode.all => Icons.repeat,
                                        _ => Icons.repeat,
                                      },
                                      selected:
                                          controller.repeatMode != LoopMode.off,
                                      onTap: controller.cycleRepeat,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Spacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({
    required this.controller,
    required this.buffering,
    required this.playing,
  });

  final PlayerController controller;
  final bool buffering;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return SquishButton(
      onTap: controller.togglePlayPause,
      width: kPlayButtonSize,
      height: kPlayButtonSize,
      deepShadow: true,
      child: buffering
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accentDeep,
              ),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween(end: playing ? 1.0 : 0.0),
              duration: kUi,
              builder: (context, t, _) => AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: AlwaysStoppedAnimation(t),
                size: 32,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.track, required this.controller});

  final Track track;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final fav = controller.isFavorite(track);
    return TweenAnimationBuilder<double>(
      key: ValueKey('heart_${track.id}_$fav'),
      tween: Tween(end: 1.0),
      duration: kUi,
      curve: kSpring,
      builder: (context, t, child) =>
          Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      child: SquishIconButton(
        icon: fav ? Icons.favorite : Icons.favorite_outline,
        iconColor: fav ? null : AppColors.textPrimary,
        onTap: () => controller.toggleFavorite(track),
      ),
    );
  }
}

class _Blobs extends StatefulWidget {
  const _Blobs();

  @override
  State<_Blobs> createState() => _BlobsState();
}

class _BlobsState extends State<_Blobs> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kBlobsLoop,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) return const _BlobLayout(t: 0);
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) => _BlobLayout(t: _controller.value),
    );
  }
}

class _BlobLayout extends StatelessWidget {
  const _BlobLayout({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: _blob(AppColors.blobCaramel, 280, Offset(t * 30, t * 20)),
          ),
          Positioned(
            bottom: -40,
            right: -60,
            child: _blob(AppColors.blobBlush, 320, Offset(-t * 24, -t * 16)),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size, Offset offset) => Transform.translate(
    offset: offset,
    child: RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 50),
          ],
        ),
      ),
    ),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    return StreamBuilder<PlayerSnapshot>(
      stream: controller.stateStream,
      builder: (context, snap) {
        final state = snap.data;
        final queue = state?.queue ?? const <Track>[];
        final current = state?.currentIndex ?? 0;

        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.4,
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          builder: (context, scrollController) => DecoratedBox(
            decoration: BoxDecoration(color: AppColors.surface),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kPagePadding,
                    vertical: Spacing.md,
                  ),
                  child: Row(
                    children: [
                      Text('Queue', style: AppText.title),
                      const Spacer(),
                      Text('${queue.length} songs', style: AppText.caption),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    buildDefaultDragHandles: false,
                    itemCount: queue.length,
                    onReorderItem: (from, to) {
                      controller.moveQueueItem(from, to);
                    },
                    itemBuilder: (context, i) {
                      final track = queue[i];
                      final isCurrent = i == current;
                      return ReorderableDragStartListener(
                        key: ValueKey(track.id),
                        index: i,
                        child: Container(
                          color: AppColors.surface,
                          child: TrackTile(
                            track: track,
                            stagger: false,
                            onTap: () => controller.jumpTo(i),
                            leading: isCurrent
                                ? Icon(
                                    Icons.graphic_eq,
                                    size: 18,
                                    color: AppColors.accentDeep,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: AppText.caption.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                            trailing: Icon(
                              Icons.drag_handle,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
