import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';

import '../models/vitals_entry.dart';
import '../utils/units.dart';

final _dateKeyRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

// Owns the three Hive boxes and every read/write path over them. Screens
// talk to this instead of touching boxes directly, and drive their UI off
// vitalsBox.listenable() / historyBox.listenable() rather than caching
// values in State fields and manually reloading them after every write.
class VitalsRepository {
  VitalsRepository({Box? vitalsBox, Box? historyBox, Box? presetsBox})
      : vitalsBox = vitalsBox ?? Hive.box('vitals_box'),
        historyBox = historyBox ?? Hive.box('history_box'),
        presetsBox = presetsBox ?? Hive.box('presets_box');

  final Box vitalsBox;
  final Box historyBox;
  final Box presetsBox;

  WeightUnit get weightUnit => weightUnitFromStored(vitalsBox.get('user_weight_unit', defaultValue: 'kg'));

  void setWeightUnit(WeightUnit unit) => vitalsBox.put('user_weight_unit', unit.label);

  bool get isFasting => vitalsBox.get('fasting_active', defaultValue: false) as bool;

  DateTime? get lastMealAt {
    final raw = vitalsBox.get('last_meal_at');
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  void startFasting(DateTime at) {
    vitalsBox.put('fasting_active', true);
    vitalsBox.put('last_meal_at', at.toIso8601String());
  }

  // Ends the current fast and records its total duration as today's
  // 'fasting' hours, so historical trend charts and CSV/PDF export keep
  // working the same way whether that field came from a live-tracked fast
  // or a manually typed/imported number.
  void endFasting() {
    final start = lastMealAt;
    if (start != null) {
      final hours = DateTime.now().difference(start).inMinutes / 60.0;
      final todayKey = DateTime.now().toIso8601String().split('T')[0];
      upsertHistoryEntry(todayKey, {'fasting': double.parse(hours.toStringAsFixed(1))});
    }
    vitalsBox.put('fasting_active', false);
  }

  void seedDefaultPresetsIfEmpty() {
    if (presetsBox.isEmpty) {
      presetsBox.put('Morning Oats', {'cals': 420, 'protein': 35});
      presetsBox.put('Usual Lunch', {'cals': 650, 'protein': 45});
    }
  }

  List<String> get sortedDateKeys {
    final keys = historyBox.keys.where((k) => k is String && _dateKeyRegex.hasMatch(k)).cast<String>().toList();
    keys.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    return keys;
  }

  VitalsEntry? get latestEntry {
    final keys = sortedDateKeys;
    if (keys.isEmpty) return null;
    final raw = historyBox.get(keys.last);
    if (raw is! Map) return null;
    return VitalsEntry.fromMap(raw);
  }

  VitalsEntry? entryForDate(String dateKey) {
    final raw = historyBox.get(dateKey);
    if (raw is! Map) return null;
    return VitalsEntry.fromMap(raw);
  }

  // Single source of truth for writing a day's metrics: always a Map, merged
  // with whatever is already stored for that date so partial updates (e.g. a
  // preset macro stack) don't clobber the other fields.
  void upsertHistoryEntry(String dateKey, Map<String, dynamic> updates) {
    final existing = historyBox.get(dateKey);
    final merged = <String, dynamic>{
      if (existing is Map) ...Map<String, dynamic>.from(existing),
      ...updates,
    };
    historyBox.put(dateKey, merged);
  }

  List<FlSpot> chronologicalWeightSpots({double fallback = 0.0}) {
    try {
      final keys = sortedDateKeys;
      final spots = <FlSpot>[];
      for (var i = 0; i < keys.length; i++) {
        final entry = historyBox.get(keys[i]);
        if (entry is Map) {
          final val = double.tryParse(entry['weight']?.toString() ?? '');
          if (val != null) spots.add(FlSpot(i.toDouble(), val));
        }
      }
      if (spots.length == 1) {
        return [FlSpot(0, spots[0].y), FlSpot(1, spots[0].y)];
      }
      if (spots.isNotEmpty) return spots;
    } catch (_) {}
    return [FlSpot(0, fallback), FlSpot(1, fallback)];
  }

  List<FlSpot> metricSpots(String key) {
    try {
      final keys = sortedDateKeys;
      final spots = <FlSpot>[];
      for (var i = 0; i < keys.length; i++) {
        final entry = historyBox.get(keys[i]);
        if (entry is Map && entry[key] != null) {
          final val = double.tryParse(entry[key].toString());
          if (val != null) spots.add(FlSpot(i.toDouble(), val));
        }
      }
      if (spots.isNotEmpty) return spots;
    } catch (_) {}
    return const [FlSpot(0, 0), FlSpot(1, 0)];
  }

  // Column names accepted in an optional header row, mapped to the field
  // key stored in history_box. Lets a user import just the metric(s) they
  // care about (e.g. "date,steps") instead of the full fixed column set.
  static const _csvColumnAliases = {
    'date': 'date',
    'weight': 'weight',
    'waist': 'waist',
    'waistline': 'waist',
    'calories': 'calories',
    'cal': 'calories',
    'protein': 'protein',
    'fasting': 'fasting',
    'fast': 'fasting',
    'steps': 'steps',
    'systolic': 'systolic',
    'sys': 'systolic',
    'diastolic': 'diastolic',
    'dia': 'diastolic',
  };

  static const _doubleFields = {'weight', 'waist', 'fasting'};

  ({int imported, int skipped}) importCsv(String raw) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return (imported: 0, skipped: 0);

    // No header row means the classic fixed column order; a header row
    // lets columns appear in any order/subset via _csvColumnAliases.
    List<String> columnKeys = ['date', 'weight', 'waist', 'calories', 'protein', 'fasting', 'steps', 'systolic', 'diastolic'];
    int startIndex = 0;
    final firstCols = lines.first.split(',').map((c) => c.trim().toLowerCase()).toList();
    if (firstCols.isEmpty || !_dateKeyRegex.hasMatch(firstCols.first)) {
      columnKeys = firstCols.map((c) => _csvColumnAliases[c] ?? '').toList();
      startIndex = 1;
    }

    final dateColIndex = columnKeys.indexOf('date');

    int imported = 0;
    int skipped = 0;

    for (var i = startIndex; i < lines.length; i++) {
      final cols = lines[i].split(',').map((c) => c.trim()).toList();
      final dateKey = (dateColIndex >= 0 && dateColIndex < cols.length) ? cols[dateColIndex] : '';
      if (!_dateKeyRegex.hasMatch(dateKey)) {
        skipped++;
        continue;
      }
      try {
        DateTime.parse(dateKey);
      } catch (_) {
        skipped++;
        continue;
      }

      final updates = <String, dynamic>{};
      for (var c = 0; c < cols.length && c < columnKeys.length; c++) {
        final key = columnKeys[c];
        if (key.isEmpty || key == 'date' || cols[c].isEmpty) continue;
        if (_doubleFields.contains(key)) {
          final v = double.tryParse(cols[c]);
          if (v != null) updates[key] = v;
        } else {
          final v = int.tryParse(cols[c]);
          if (v != null) updates[key] = v;
        }
      }

      if (updates.isEmpty) {
        skipped++;
        continue;
      }

      upsertHistoryEntry(dateKey, updates);
      imported++;
    }

    return (imported: imported, skipped: skipped);
  }

  // Replaces a box's contents key-by-key rather than via clear()/putAll(),
  // which are bulk lifecycle operations rather than the simple synchronous
  // keystore mutations put()/delete() are — mixing clear() with an
  // immediately-following putAll() does not reliably guarantee the clear
  // has taken effect first.
  void _replaceBoxContents(Box box, Map<String, dynamic> newData) {
    for (final key in box.keys.toList()) {
      box.delete(key);
    }
    for (final entry in newData.entries) {
      box.put(entry.key, entry.value);
    }
  }

  bool restoreFromBackupJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['vitals'] is! Map || decoded['history'] is! Map || decoded['presets'] is! Map) {
        return false;
      }
      _replaceBoxContents(vitalsBox, Map<String, dynamic>.from(decoded['vitals']));
      _replaceBoxContents(historyBox, Map<String, dynamic>.from(decoded['history']));
      _replaceBoxContents(presetsBox, Map<String, dynamic>.from(decoded['presets']));
      return true;
    } catch (_) {
      return false;
    }
  }

  String exportBackupJson() {
    final Map<String, dynamic> exportData = {
      'vitals': vitalsBox.toMap(),
      'history': historyBox.toMap(),
      'presets': presetsBox.toMap(),
      'export_date': DateTime.now().toIso8601String(),
    };
    return jsonEncode(exportData);
  }
}
