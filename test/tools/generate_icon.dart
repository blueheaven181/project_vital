// Not a real test — a headless render script for the app icon, run once
// manually via `flutter test test/tools/generate_icon.dart`. Uses the
// flutter_tester engine to rasterize a CustomPainter to PNG, since a plain
// `dart run` has no engine to back dart:ui's Canvas with.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _inkNavyDark = Color(0xFF0B0D12);
const _inkNavyLight = Color(0xFF171B24);
const _amber = Color(0xFFE8A23D);
const _amberDim = Color(0xFFB97A22);
const _violet = Color(0xFF9C8AD1);

class _AppIconPainter extends CustomPainter {
  final bool paintBackground;
  final double scale;
  _AppIconPainter({required this.paintBackground, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    if (paintBackground) {
      // Full-bleed square, unrounded: Android applies its own per-launcher
      // icon mask (circle/squircle/rounded-square), so pre-rounding here
      // would leave visible corner artifacts once masked.
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_inkNavyLight, _inkNavyDark],
        ).createShader(rect);
      canvas.drawRect(rect, bgPaint);

      canvas.save();
      canvas.clipRect(rect);

      final glowAmber = Paint()
        ..color = _amber.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.16);
      canvas.drawCircle(Offset(w * 0.86, h * 0.12), w * 0.28, glowAmber);

      final glowViolet = Paint()
        ..color = _violet.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.18);
      canvas.drawCircle(Offset(w * 0.08, h * 0.92), w * 0.26, glowViolet);

      canvas.restore();
    }

    // Everything below is scaled/centered so it still reads correctly once
    // Android's adaptive-icon mask crops to the safe zone (~66% of size).
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(scale);
    canvas.translate(-w / 2, -h / 2);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.34, ringPaint);

    final pulsePath = Path()
      ..moveTo(w * 0.13, h * 0.55)
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(w * 0.40, h * 0.37)
      ..lineTo(w * 0.48, h * 0.68)
      ..lineTo(w * 0.56, h * 0.45)
      ..lineTo(w * 0.63, h * 0.55)
      ..lineTo(w * 0.87, h * 0.55);

    final pulseShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(pulsePath.shift(Offset(0, h * 0.012)), pulseShadowPaint);

    final pulsePaint = Paint()
      ..shader = const LinearGradient(colors: [_amber, _amberDim]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pulsePath, pulsePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) => false;
}

Future<void> _renderTo(WidgetTester tester, String path, {required bool paintBackground, required double scale}) async {
  const size = 1024.0;
  final key = GlobalKey();

  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _AppIconPainter(paintBackground: paintBackground, scale: scale)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

void main() {
  testWidgets('generate app icon PNGs', (tester) async {
    await _renderTo(tester, 'assets/icon/icon.png', paintBackground: true, scale: 1.0);
    await _renderTo(tester, 'assets/icon/icon_foreground.png', paintBackground: false, scale: 0.62);
  });
}
