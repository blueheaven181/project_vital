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

  ({int imported, int skipped}) importCsv(String raw) {
    int imported = 0;
    int skipped = 0;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final cols = line.split(',').map((c) => c.trim()).toList();
      final dateKey = cols.isNotEmpty ? cols[0] : '';
      if (!_dateKeyRegex.hasMatch(dateKey)) continue; // header row or junk line

      try {
        DateTime.parse(dateKey);
      } catch (_) {
        skipped++;
        continue;
      }

      final updates = <String, dynamic>{};
      if (cols.length > 1 && cols[1].isNotEmpty) {
        final v = double.tryParse(cols[1]);
        if (v != null) updates['weight'] = v;
      }
      if (cols.length > 2 && cols[2].isNotEmpty) {
        final v = double.tryParse(cols[2]);
        if (v != null) updates['waist'] = v;
      }
      if (cols.length > 3 && cols[3].isNotEmpty) {
        final v = int.tryParse(cols[3]);
        if (v != null) updates['calories'] = v;
      }
      if (cols.length > 4 && cols[4].isNotEmpty) {
        final v = int.tryParse(cols[4]);
        if (v != null) updates['protein'] = v;
      }
      if (cols.length > 5 && cols[5].isNotEmpty) {
        final v = double.tryParse(cols[5]);
        if (v != null) updates['fasting'] = v;
      }
      if (cols.length > 6 && cols[6].isNotEmpty) {
        final v = int.tryParse(cols[6]);
        if (v != null) updates['steps'] = v;
      }
      if (cols.length > 7 && cols[7].isNotEmpty) {
        final v = int.tryParse(cols[7]);
        if (v != null) updates['systolic'] = v;
      }
      if (cols.length > 8 && cols[8].isNotEmpty) {
        final v = int.tryParse(cols[8]);
        if (v != null) updates['diastolic'] = v;
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
