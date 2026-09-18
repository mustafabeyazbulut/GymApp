import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 0.0–1.0 arasındaki bir değeri yüzde olarak gösteren, altında ortalanmış
/// bir etiket bulunan küçük bir halka gösterge. Progress ekranının üç
/// gelişim alanı istatistiği tarafından kullanılır. `value`, hem çizimden
/// hem etiketlemeden önce [0, 1] aralığına sıkıştırılır (clamp).
class CircularStatGauge extends StatelessWidget {
  const CircularStatGauge({
    required this.value,
    required this.color,
    required this.label,
    this.size = 56,
    super.key,
  });

  final double value;
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(value: clamped, color: color),
            child: Center(
              child: Text(
                '%${(clamped * 100).round()}',
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.textTheme.bodyMedium?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 6) / 2;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const startAngle = -1.5707963267948966; // -90 derece, saat 12 yönü
    final sweepAngle = 6.283185307179586 * value; // value * 2*pi
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
