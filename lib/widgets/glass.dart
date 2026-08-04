import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/vital_palette.dart';

Widget vitalGlassCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(18.0), BorderRadius? borderRadius}) {
  final radius = borderRadius ?? BorderRadius.circular(20);
  return ClipRRect(
    borderRadius: radius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.015)],
          ),
          borderRadius: radius,
          border: Border.all(color: VitalPalette.hairlineStrong, width: 1),
        ),
        child: child,
      ),
    ),
  );
}
