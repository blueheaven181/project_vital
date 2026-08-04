import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The quick-log sheet and other dialogs are taller than the default
// 800x600 test surface, which pushes action buttons off-screen. Use a
// taller surface so every widget in these tests is actually reachable.
void growViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
