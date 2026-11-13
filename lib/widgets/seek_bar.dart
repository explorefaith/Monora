import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../player/player_controller.dart';

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inHours > 0 ? '${d.inHours}:$m' : m}:$s';
}

class SeekBar extends StatefulWidget {
  const SeekBar({super.key, required this.controller});

  final PlayerController controller;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  void _updateFromDx(double dx) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    if (width <= 0) return;
    setState(() => _dragValue = (dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgressSnapshot>(
      stream: widget.controller.progressStream,
      builder: (context, snap) {
        final data = snap.data;
        final duration = data?.duration ?? Duration.zero;
        final totalMs = duration.inMilliseconds.toDouble();
        final position = _dragValue != null && totalMs > 0
            ? Duration(milliseconds: (_dragValue! * totalMs).round())
            : data?.position ?? Duration.zero;
        final buffered = data?.buffered ?? Duration.zero;
        final bufferedFraction = totalMs > 0
            ? buffered.inMilliseconds / totalMs
            : 0.0;
        final fraction = totalMs > 0 ? position.inMilliseconds / totalMs : 0.0;

        return Column(
          children: [
            RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragDown: (d) => _updateFromDx(d.localPosition.dx),
                onHorizontalDragUpdate: (d) =>
                    _updateFromDx(d.localPosition.dx),
                onHorizontalDragEnd: (_) => _commit(duration),
                onHorizontalDragCancel: () => setState(() => _dragValue = null),
                child: SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SeekBarPainter(
                      fraction: fraction,
                      bufferedFraction: bufferedFraction,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(position), style: AppText.caption),
                Text(
                  '-${formatDuration(duration - position)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _commit(Duration duration) {
    final v = _dragValue;
    setState(() => _dragValue = null);
    if (v == null) return;
    final target = Duration(
      milliseconds: (v * duration.inMilliseconds).round(),
    );
    widget.controller.seek(target);
  }
}

class _SeekBarPainter extends CustomPainter {
  _SeekBarPainter({required this.fraction, required this.bufferedFraction});

  final double fraction;
  final double bufferedFraction;

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 8.0;
    final trackRadius = Radius.circular(trackHeight / 2);
    final y = size.height / 2;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - trackHeight / 2, size.width, trackHeight),
      trackRadius,
    );

    canvas.drawRRect(trackRect, Paint()..color = AppColors.surfaceSunken);

    if (bufferedFraction > fraction) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            y - trackHeight / 2,
            size.width * bufferedFraction.clamp(0.0, 1.0),
            trackHeight,
          ),
          trackRadius,
        ),
        Paint()..color = AppColors.primary.withValues(alpha: 0.45),
      );
    }

    final elapsed = size.width * fraction.clamp(0.0, 1.0);
    if (elapsed > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y - trackHeight / 2, elapsed, trackHeight),
          trackRadius,
        ),
        Paint()..color = AppColors.accentDeep,
      );
    }

    final thumb = Offset(elapsed, y);
    final glow = Paint()
      ..color = AppColors.accentDeep.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(thumb, 10, glow);
    canvas.drawCircle(thumb, 8, Paint()..color = AppColors.accentDeep);
    canvas.drawCircle(
      thumb,
      8,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_SeekBarPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.bufferedFraction != bufferedFraction;
}
