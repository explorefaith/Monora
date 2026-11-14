import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../models/track.dart';
import 'cover_art.dart';
import 'squish_button.dart';

class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kUi,
    value: 0,
  );

  bool get _staggered => widget.index < kStaggerMaxItems;

  @override
  void initState() {
    super.initState();
    if (!_staggered) {
      _controller.value = 1;
      return;
    }
    final step = kStaggerStep * widget.index;
    if (step == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(step, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.index = 0,
    this.stagger = true,
    this.onTap,
    this.leading,
    this.trailing,
  });

  final Track track;
  final int index;
  final bool stagger;
  final VoidCallback? onTap;

  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final row = PressableScale(
      onTap: onTap,
      child: Container(
        height: kListTileHeight,
        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(
                width: kTapTarget - 12,
                child: Center(child: leading),
              ),
              const SizedBox(width: Spacing.xs),
            ],
            CoverArt(track: track, size: kCoverSmall),
            const SizedBox(width: kCoverGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.title,
                          style: AppText.songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (track.isPreview) ...[
                        const SizedBox(width: Spacing.sm),
                        _previewChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: AppText.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            if (trailing != null)
              SizedBox(width: kTapTarget, height: kTapTarget, child: trailing),
          ],
        ),
      ),
    );

    if (!stagger) return row;
    return StaggeredReveal(index: index, child: row);
  }

  Widget _previewChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.surfaceSunken,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Text(
      '30s',
      style: AppText.caption.copyWith(color: AppColors.accentDeep, fontSize: 9),
    ),
  );
}
