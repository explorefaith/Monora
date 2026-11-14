import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../core/transitions.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!_reduceMotion && !_wave.isAnimating) _wave.repeat();
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), _goHome);
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushReplacement<void, void>(FadeThroughRoute(page: const HomeScreen()));
  }

  @override
  void dispose() {
    _intro.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppColors.surface, AppColors.gradientEdge],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _reduceMotion
                ? const AlwaysStoppedAnimation(1)
                : CurvedAnimation(parent: _intro, curve: kEnter),
            child: ScaleTransition(
              scale: _reduceMotion
                  ? const AlwaysStoppedAnimation(1)
                  : Tween<double>(
                      begin: 0.85,
                      end: 1,
                    ).animate(CurvedAnimation(parent: _intro, curve: kSpring)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Monora', style: AppText.display),
                  const SizedBox(height: Spacing.lg),
                  SizedBox(
                    width: 120,
                    height: 20,
                    child: _reduceMotion
                        ? const SizedBox.shrink()
                        : AnimatedBuilder(
                            animation: _wave,
                            builder: (context, _) => CustomPaint(
                              painter: _WavePainter(
                                phase: _wave.value * 2 * math.pi,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    var first = true;
    for (double x = 0; x <= size.width; x += 3) {
      final t = x / size.width;

      final envelope = 3.5 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
      final y = size.height / 2 + envelope * math.sin(t * 4 * math.pi - phase);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.phase != phase;
}
