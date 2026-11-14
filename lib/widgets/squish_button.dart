import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../core/palette.dart';

List<BoxShadow> creamShadows({bool deep = false}) {
  final t = Palette.current;
  if (t.hardShadows) {
    return [
      BoxShadow(
        color: t.shadowLight,
        offset: deep ? const Offset(-5, -5) : const Offset(-3, -3),
        blurRadius: 0,
      ),
      BoxShadow(
        color: t.shadowWarm,
        offset: deep ? const Offset(7, 7) : const Offset(4, 4),
        blurRadius: 0,
      ),
    ];
  }
  return [
    BoxShadow(
      color: t.shadowLight,
      offset: deep ? const Offset(-6, -6) : const Offset(-4, -4),
      blurRadius: deep ? 14 : 10,
    ),
    BoxShadow(
      color: t.shadowWarm,
      offset: deep ? const Offset(9, 9) : const Offset(6, 6),
      blurRadius: deep ? 22 : 16,
    ),
  ];
}

const List<BoxShadow> kCreamShadowsPressed = [
  BoxShadow(color: Colors.transparent, offset: Offset(-1, -1), blurRadius: 1),
  BoxShadow(color: Colors.transparent, offset: Offset(1, 1), blurRadius: 1),
];

class SquishButton extends StatefulWidget {
  const SquishButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.deepShadow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;
  final bool deepShadow;

  @override
  State<SquishButton> createState() => _SquishButtonState();
}

class _SquishButtonState extends State<SquishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kMicro,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: kEnter,
    reverseCurve: kSpring,
  );

  bool get _pressable => widget.onTap != null;

  void _down(TapDownDetails _) {
    if (_pressable) _controller.forward();
  }

  void _up() {
    if (_pressable) _controller.reverse();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final baseColor = widget.color ?? AppColors.surface;
    final deep = widget.deepShadow;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: reduceMotion ? null : _down,
      onTapUp: reduceMotion ? null : (_) => _up(),
      onTapCancel: _up,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final t = reduceMotion ? 0.0 : _curve.value;
          return Transform.scale(
            scale: 1 - 0.04 * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(baseColor, AppColors.surfaceSunken, t * 0.7),
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? Radii.pill,
                ),
                boxShadow: BoxShadow.lerpList(
                  creamShadows(deep: deep),
                  kCreamShadowsPressed,
                  t,
                ),
              ),
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class SquishIconButton extends StatelessWidget {
  const SquishIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = kTapTarget,
    this.iconSize = 22,
    this.iconColor,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SquishButton(
      onTap: onTap,
      width: size,
      height: size,
      color: selected ? AppColors.surfaceSunken : AppColors.surface,
      child: Icon(
        icon,
        size: iconSize,
        color:
            iconColor ??
            (selected ? AppColors.accentDeep : AppColors.textPrimary),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final target = _pressed && !reduceMotion ? widget.pressedScale : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: target,
        duration: kMicro,
        curve: kEnter,
        child: widget.child,
      ),
    );
  }
}

class SquishFilledButton extends StatelessWidget {
  const SquishFilledButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SquishButton(
      onTap: onTap,
      width: 220,
      height: 52,
      color: AppColors.primary,
      child: Text(
        label,
        style: AppText.songTitle.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
