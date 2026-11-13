import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';

/// Cream shimmer skeleton shown while Discover loads (§3.B). Hand-rolled
/// with a moving gradient — no shimmer dependency.
class ShimmerList extends StatefulWidget {
  const ShimmerList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  State<ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return _skeleton();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.0 - 2 * t, -1.0),
            end: Alignment(1.0 + 2 * t, 1.0),
            colors: const [
              AppColors.surfaceSunken,
              AppColors.surface,
              AppColors.surfaceSunken,
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child!,
        );
      },
      child: _skeleton(),
    );
  }

  Widget _skeleton() =>
      Column(children: [for (var i = 0; i < widget.itemCount; i++) _tile()]);

  Widget _tile() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: kPagePadding,
      vertical: Spacing.sm,
    ),
    child: SizedBox(
      height: kListTileHeight - Spacing.sm * 2,
      child: Row(
        children: [
          _box(kCoverSmall, kCoverSmall, 16),
          const SizedBox(width: kCoverGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(widthFactor: 0.6, child: _box(14, 16, 8)),
                const SizedBox(height: Spacing.md),
                FractionallySizedBox(widthFactor: 0.4, child: _box(10, 14, 6)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _box(double width, double height, double radius) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.divider,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
