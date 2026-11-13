import 'package:material_ui/material_ui.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../screens/player_screen.dart';
import 'cover_art.dart';
import 'squish_button.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    return StreamBuilder<PlayerSnapshot>(
      stream: controller.stateStream,
      builder: (context, snap) {
        final track = snap.data?.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 0, kPagePadding, 8),
          child: GestureDetector(
            onTap: () => _expand(context),
            onVerticalDragEnd: (d) {
              if (d.primaryVelocity != null && d.primaryVelocity! < 0) {
                _expand(context);
              }
            },
            onHorizontalDragEnd: _onHorizontalDragEnd(context, controller),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(kRadiusMini),
                boxShadow: kCreamShadows,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        const SizedBox(width: Spacing.md),
                        Hero(
                          tag: 'cover-art',
                          child: CoverArt(track: track, size: 44, radius: 14),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: AppText.songTitle.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                style: AppText.artist.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _playPause(controller, track),
                        SquishIconButton(
                          icon: Icons.skip_next,
                          onTap: controller.next,
                        ),
                        const SizedBox(width: Spacing.md),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 3,
                    child: StreamBuilder<ProgressSnapshot>(
                      stream: controller.progressStream,
                      builder: (context, progress) {
                        final d = progress.data;
                        final total = d?.duration?.inMilliseconds ?? 0;
                        final fraction = total > 0
                            ? d!.position.inMilliseconds / total
                            : 0.0;
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: fraction.clamp(0.0, 1.0),
                          child: Container(color: AppColors.accentDeep),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void Function(DragEndDetails) _onHorizontalDragEnd(
    BuildContext context,
    PlayerController controller,
  ) {
    return (details) {
      final v = details.velocity.pixelsPerSecond.dx;
      if (v < -300) {
        controller.next();
      } else if (v > 300) {
        controller.previous();
      }
    };
  }

  void _expand(BuildContext context) {
    Navigator.of(context).push<void>(PlayerScreen.route());
  }
}

Widget _playPause(PlayerController controller, Track track) {
  return StreamBuilder<PlayerSnapshot>(
    stream: controller.stateStream,
    builder: (context, snap) {
      final state = snap.data;
      final processing = state?.processingState ?? ProcessingState.idle;
      final loading =
          processing == ProcessingState.loading ||
          processing == ProcessingState.buffering;
      final playing = state?.playing ?? false;

      return SquishButton(
        onTap: controller.togglePlayPause,
        width: kTapTarget,
        height: kTapTarget,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentDeep,
                ),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(end: playing ? 1.0 : 0.0),
                duration: kUi,
                builder: (context, t, _) => AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: AlwaysStoppedAnimation(t),
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
      );
    },
  );
}
