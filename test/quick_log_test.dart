// Regression test for the dashboard-shows-0 bug: the quick-log FAB must
// write the same Map shape to history_box that _loadData() reads back.
//
// Note: Hive's real file I/O does not reliably complete inside
// testWidgets' fake-async zone once a frame has been pumped, so seeding
// data before the first pumpWidget goes through tester.runAsync().

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

  testWidgets('quick-log FAB save updates the dashboard and stores a Map', (WidgetTester tester) async {
    growViewport(tester);
    await tester.runAsync(() async {
      await vitalsBox.put('profile_setup_complete', true);
      await vitalsBox.put('user_name', 'Test User');
      await vitalsBox.put('user_goal_weight', 63.0);
    });

    await tester.pumpWidget(const ProjectVitalApp());
    await tester.pumpAndSettle();

    // Before logging anything today, the card shows the placeholder.
    expect(find.text('-- kg'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '80');
    await tester.pumpAndSettle();

    await tester.tap(find.text('SAVE RECORD'));
    await tester.pumpAndSettle();

    // The dashboard must reflect the new weight immediately, not 0 or --.
    expect(find.text('80.0 kg'), findsOneWidget);
    expect(find.text('-- kg'), findsNothing);

    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final entry = historyBox.get(todayKey);

    expect(entry, isA<Map>());
    expect((entry as Map)['weight'], 80.0);
  });
}
