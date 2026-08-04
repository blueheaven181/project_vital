// Regression test for JSON backup restore: it must fully replace existing
// vitals/history/presets data, not merge alongside it.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_vital/main.dart';

import 'test_helpers.dart';

void main() {
  late Directory tempDir;
  late Box vitalsBox;
  late Box historyBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('vital_test');
    Hive.init(tempDir.path);
    vitalsBox = await Hive.openBox('vitals_box');
    historyBox = await Hive.openBox('history_box');
    await Hive.openBox('presets_box');
  });

  testWidgets('restore from backup replaces existing data with the backup contents', (WidgetTester tester) async {
    growViewport(tester);
    await tester.runAsync(() async {
      await vitalsBox.put('profile_setup_complete', true);
      await vitalsBox.put('user_name', 'Old Name');
      await vitalsBox.put('user_goal_weight', 63.0);
      await historyBox.put('2026-07-01', {'weight': 100.0});
    });

    await tester.pumpWidget(const ProjectVitalApp());
    await tester.pumpAndSettle();

    final backupJson = jsonEncode({
      'vitals': {'user_name': 'Restored Name', 'user_goal_weight': 60.0, 'profile_setup_complete': true},
      'history': {
        '2026-08-02': {'weight': 70.0, 'waist': 80, 'calories': 1700, 'protein': 140, 'fasting': 16.0, 'steps': 6000},
      },
      'presets': {
        'Test Meal': {'cals': 300, 'protein': 20},
      },
    });

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESTORE FROM BACKUP'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, backupJson);
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESTORE'));
    await tester.pumpAndSettle();

    expect(find.text('Backup restored!'), findsOneWidget);
    expect(find.textContaining('Restored Name'), findsOneWidget);
    expect(find.text('70.0 kg'), findsOneWidget);
    expect(historyBox.get('2026-07-01'), isNull);
  });
}
