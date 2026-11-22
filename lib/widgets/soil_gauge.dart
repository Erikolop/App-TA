import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../core/theme.dart';

/// Semicircular soil moisture gauge with animated needle.
class SoilGauge extends StatefulWidget {
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
  State<SoilGauge> createState() => _SoilGaugeState();
}

class _SoilGaugeState extends State<SoilGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fillAnim;
  late Animation<Color?> _flashAnim;
  double _prevFraction = 0;
  int? _prevValue;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final fraction = widget.value != null ? (widget.value! / 100).clamp(0.0, 1.0) : 0.0;
    _fillAnim = Tween<double>(begin: 0, end: fraction).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _flashAnim = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_ctrl);
    _prevFraction = fraction;
    _prevValue = widget.value;
    if (widget.value != null) _ctrl.forward();
  }

  @override
  void didUpdateWidget(SoilGauge old) {
    super.didUpdateWidget(old);
    final newFraction = widget.value != null ? (widget.value! / 100).clamp(0.0, 1.0) : 0.0;
    if (widget.value != _prevValue) {
      _fillAnim = Tween<double>(begin: _prevFraction, end: newFraction).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      // Flash highlight on value change (not on first paint)
      if (_prevValue != null) {
        _flashAnim = ColorTween(
          begin: AppColors.accent.withValues(alpha: 0.12),
          end: Colors.transparent,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      }
      _prevFraction = newFraction;
      _prevValue = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: _flashAnim.value,
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size * 0.65,
            child: CustomPaint(
              painter: _GaugePainter(
                fraction: _fillAnim.value,
                dryThreshold: widget.dryThreshold,
                wetThreshold: widget.wetThreshold,
              ),
              child: Align(
                alignment: const Alignment(0, 0.4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        widget.value != null ? '${widget.value}%' : '--',
                        key: ValueKey(widget.value),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1,
                        ),
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
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction; // 0.0 – 1.0, already animated
  final int dryThreshold;
  final int wetThreshold;

  const _GaugePainter({
    required this.fraction,
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

    // Fill arc — uses pre-animated fraction
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        _sweepAngle * fraction,
        false,
        Paint()
          ..color = _fillColor(fraction * 100)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Threshold tick marks
    _drawTick(canvas, cx, cy, radius, dryThreshold / 100, AppColors.textSecondary);
    _drawTick(canvas, cx, cy, radius, wetThreshold / 100, AppColors.textSecondary);
  }

  Color _fillColor(double percent) {
    if (percent < dryThreshold) return Colors.orange;
    if (percent > wetThreshold) return Colors.blue;
    return AppColors.accent;
  }

  void _drawTick(Canvas canvas, double cx, double cy, double radius,
      double frac, Color color) {
    final angle = _startAngle + _sweepAngle * frac;
    final inner = radius - 10;
    final outer = radius + 10;
    canvas.drawLine(
      Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
      Offset(cx + outer * math.cos(angle), cy + outer * math.sin(angle)),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      fraction != old.fraction ||
      dryThreshold != old.dryThreshold ||
      wetThreshold != old.wetThreshold;
}
