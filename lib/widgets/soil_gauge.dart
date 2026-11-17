import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../core/theme.dart';

/// Semicircular soil moisture gauge.
class SoilGauge extends StatelessWidget {
  final int? value; // 0–100, null = no reading yet
  final int dryThreshold;
  final int wetThreshold;
  final double size;

  const SoilGauge({
    super.key,
    required this.value,
    this.dryThreshold = 35,
    this.wetThreshold = 60,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        painter: _GaugePainter(
          value: value,
          dryThreshold: dryThreshold,
          wetThreshold: wetThreshold,
        ),
        child: Align(
          alignment: const Alignment(0, 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value != null ? '$value%' : '--',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Soil Moisture',
                style: const TextStyle(
                  fontSize: 12,
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

class _GaugePainter extends CustomPainter {
  final int? value;
  final int dryThreshold;
  final int wetThreshold;

  const _GaugePainter({
    this.value,
    required this.dryThreshold,
    required this.wetThreshold,
  });

  static const double _startAngle = math.pi;       // 180° — left
  static const double _sweepAngle = math.pi;       // 180° — half circle

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.92;
    final radius = size.width * 0.44;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track (background arc)
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..color = AppColors.divider
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Fill arc
    if (value != null) {
      final fraction = (value! / 100).clamp(0.0, 1.0);
      canvas.drawArc(
        rect,
        _startAngle,
        _sweepAngle * fraction,
        false,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dry threshold marker
    _drawMarker(canvas, cx, cy, radius, dryThreshold / 100,
        AppColors.accent.withValues(alpha: 0.45));

    // Wet threshold marker
    _drawMarker(canvas, cx, cy, radius, wetThreshold / 100, AppColors.accent);

    // Range labels
    _drawLabel(canvas, size, '0%', 0.0, cx, cy, radius);
    _drawLabel(canvas, size, '100%', 1.0, cx, cy, radius);
  }

  void _drawMarker(
      Canvas canvas, double cx, double cy, double r, double fraction, Color color) {
    final angle = _startAngle + _sweepAngle * fraction;
    final mx = cx + r * math.cos(angle);
    final my = cy + r * math.sin(angle);
    canvas.drawCircle(
      Offset(mx, my),
      5,
      Paint()..color = color,
    );
  }

  void _drawLabel(Canvas canvas, Size size, String text, double fraction,
      double cx, double cy, double r) {
    final angle = _startAngle + _sweepAngle * fraction;
    final lx = cx + (r + 18) * math.cos(angle);
    final ly = cy + (r + 18) * math.sin(angle);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.dryThreshold != dryThreshold ||
      old.wetThreshold != wetThreshold;
}
