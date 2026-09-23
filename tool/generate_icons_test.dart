import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/theme/app_colors.dart';

void main() {
  test('generate icon files from Flutter painter', () async {
    // 1. App Icon (1024x1024) - full bleed gradient with centered symbol
    final iconRecorder = ui.PictureRecorder();
    final iconCanvas = Canvas(iconRecorder);
    const size = Size(1024, 1024);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF14B8A6), // Teal 500
          AppColors.primary, // Teal 600
          AppColors.primaryDark, // Teal 700
        ],
      ).createShader(Offset.zero & size);
    iconCanvas.drawRect(Offset.zero & size, bgPaint);

    _paintSymbol(iconCanvas, size);

    final iconPic = iconRecorder.endRecording();
    final iconImg = await iconPic.toImage(1024, 1024);
    final iconBytes = await iconImg.toByteData(format: ui.ImageByteFormat.png);
    File(
      'assets/icons/app_icon.png',
    ).writeAsBytesSync(iconBytes!.buffer.asUint8List());

    // 2. Background only (1024x1024)
    final bgRecorder = ui.PictureRecorder();
    final bgCanvas = Canvas(bgRecorder);
    bgCanvas.drawRect(Offset.zero & size, bgPaint);
    final bgPic = bgRecorder.endRecording();
    final bgImg = await bgPic.toImage(1024, 1024);
    final bgBytes = await bgImg.toByteData(format: ui.ImageByteFormat.png);
    File(
      'assets/icons/app_icon_background.png',
    ).writeAsBytesSync(bgBytes!.buffer.asUint8List());

    // 3. Foreground only (1024x1024) for Adaptive Icon (scaled 0.72 inside safe circle)
    final fgRecorder = ui.PictureRecorder();
    final fgCanvas = Canvas(fgRecorder);
    fgCanvas.save();
    // Scale around center (512, 512)
    fgCanvas.translate(512, 512);
    fgCanvas.scale(0.72, 0.72);
    fgCanvas.translate(-512, -512);
    _paintSymbol(fgCanvas, size);
    fgCanvas.restore();

    final fgPic = fgRecorder.endRecording();
    final fgImg = await fgPic.toImage(1024, 1024);
    final fgBytes = await fgImg.toByteData(format: ui.ImageByteFormat.png);
    File(
      'assets/icons/app_icon_foreground.png',
    ).writeAsBytesSync(fgBytes!.buffer.asUint8List());

    // 4. In-app Logo with rounded corners and shadow (1024x1024)
    final logoRecorder = ui.PictureRecorder();
    final logoCanvas = Canvas(logoRecorder);

    // Draw rounded rect with subtle padding for shadow
    const logoPadding = 80.0;
    const logoInnerSize = 1024.0 - (logoPadding * 2);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(logoPadding, logoPadding, logoInnerSize, logoInnerSize),
      const Radius.circular(logoInnerSize * 0.28),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48.0);
    logoCanvas.drawRRect(rrect.shift(const Offset(0, 24)), shadowPaint);

    // Gradient background
    final logoBgPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF14B8A6),
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ).createShader(
            Rect.fromLTWH(
              logoPadding,
              logoPadding,
              logoInnerSize,
              logoInnerSize,
            ),
          );
    logoCanvas.drawRRect(rrect, logoBgPaint);

    // Symbol inside logo
    logoCanvas.save();
    logoCanvas.translate(logoPadding, logoPadding);
    _paintSymbol(logoCanvas, const Size(logoInnerSize, logoInnerSize));
    logoCanvas.restore();

    final logoPic = logoRecorder.endRecording();
    final logoImg = await logoPic.toImage(1024, 1024);
    final logoBytes = await logoImg.toByteData(format: ui.ImageByteFormat.png);
    File(
      'assets/images/app_logo.png',
    ).writeAsBytesSync(logoBytes!.buffer.asUint8List());
  });
}

void _paintSymbol(Canvas canvas, Size size) {
  final strokeWidth = size.width * 0.11;

  final checkPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final linePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth * 0.85
    ..strokeCap = StrokeCap.round;

  final checkPath = Path();
  checkPath.moveTo(size.width * 0.24, size.height * 0.50);
  checkPath.lineTo(size.width * 0.40, size.height * 0.66);
  checkPath.lineTo(size.width * 0.76, size.height * 0.30);
  canvas.drawPath(checkPath, checkPaint);

  canvas.drawLine(
    Offset(size.width * 0.30, size.height * 0.78),
    Offset(size.width * 0.70, size.height * 0.78),
    linePaint,
  );
}
