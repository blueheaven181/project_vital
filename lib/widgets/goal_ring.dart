import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vital_palette.dart';

class GoalRing extends StatelessWidget {
  final double progress;
  final double size;
  const GoalRing({super.key, required this.progress, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RingPainter(progress: progress)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 7) / 2;

    final track = Paint()
      ..color = VitalPalette.hairlineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, track);

    final value = Paint()
      ..color = VitalPalette.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, value);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
