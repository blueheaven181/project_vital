// Regression test: onboarding should seed a history entry for today so the
// dashboard shows the just-entered weight immediately, instead of 0.0 kg
// until the first daily log.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_vital/main.dart';

import 'test_helpers.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('vital_test');
    Hive.init(tempDir.path);
    await Hive.openBox('vitals_box');
    await Hive.openBox('history_box');
    await Hive.openBox('presets_box');
  });

  testWidgets('onboarding seeds a history entry so the dashboard shows the initial weight', (WidgetTester tester) async {
    growViewport(tester);
    await tester.pumpWidget(const ProjectVitalApp());
    await tester.pumpAndSettle();

    // Onboarding fields start empty; the user must type their own weight.
    await tester.enterText(find.widgetWithText(TextField, 'Current Weight (kg)'), '72.5');
    await tester.pumpAndSettle();

    await tester.tap(find.text('INITIALIZE DASHBOARD'));
    await tester.pumpAndSettle();

    expect(find.text('72.5 kg'), findsOneWidget);
  });
}
