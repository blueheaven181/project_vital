// Regression test for CSV bulk-import: one row per day, columns
// date,weight,waist,calories,protein,fasting,steps, merged into
// history_box via the same _upsertHistoryEntry path daily logs use.

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

  testWidgets('CSV import via the More menu bulk-loads multiple days', (WidgetTester tester) async {
    growViewport(tester);
    await tester.runAsync(() async {
      await vitalsBox.put('profile_setup_complete', true);
      await vitalsBox.put('user_name', 'Test User');
      await vitalsBox.put('user_goal_weight', 63.0);
    });

    await tester.pumpWidget(const ProjectVitalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();

    const csv = 'date,weight,waist,calories,protein,fasting,steps\n'
        '2026-08-01,78.0,90,1900,120,15,7000\n'
        '2026-08-04,75.5,87,1800,135,14,9100\n';

    await tester.enterText(find.byType(TextField).last, csv);
    await tester.pumpAndSettle();

    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Imported 2 day(s)'), findsOneWidget);

    final entry1 = historyBox.get('2026-08-01');
    final entry2 = historyBox.get('2026-08-04');
    expect(entry1, isA<Map>());
    expect((entry1 as Map)['weight'], 78.0);
    expect(entry2, isA<Map>());
    expect((entry2 as Map)['steps'], 9100);

    // Dashboard reflects the chronologically latest imported date, not 0/--.
    expect(find.text('75.5 kg'), findsOneWidget);
  });
}
