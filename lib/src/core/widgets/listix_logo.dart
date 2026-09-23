import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ListixLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final double? fontSize;

  const ListixLogo({
    super.key,
    this.size = 32,
    this.showWordmark = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14B8A6), // Teal 500
            AppColors.primary, // Teal 600
            AppColors.primaryDark, // Teal 700
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(painter: _ListixLogoPainter()),
    );

    if (!showWordmark) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: size * 0.32),
        RichText(
          text: TextSpan(
            text: 'List',
            style: TextStyle(
              fontSize: fontSize ?? (size * 0.72),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
            children: [
              TextSpan(
                text: 'ix',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListixLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.11;

    // Paint for checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for horizontal list bars
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round;

    // Checkmark path on the left
    final checkPath = Path();
    checkPath.moveTo(size.width * 0.24, size.height * 0.50);
    checkPath.lineTo(size.width * 0.40, size.height * 0.66);
    checkPath.lineTo(size.width * 0.76, size.height * 0.30);
    canvas.drawPath(checkPath, checkPaint);

    // Bottom decorative companion line
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.78),
      Offset(size.width * 0.70, size.height * 0.78),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
