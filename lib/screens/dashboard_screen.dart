import 'dart:io';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/vitals_entry.dart';
import '../services/pdf_report.dart';
import '../services/vitals_repository.dart';
import '../theme/vital_palette.dart';
import '../utils/units.dart';
import '../widgets/glass.dart';
import '../widgets/goal_ring.dart';
import 'onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final VitalsRepository repo;

  @override
  void initState() {
    super.initState();
    repo = VitalsRepository();
    repo.seedDefaultPresetsIfEmpty();
  }

  ({double changeKg, DateTime fromDate})? _weightChangeSince(int days) {
    final keys = repo.sortedDateKeys;
    if (keys.isEmpty) return null;
    final latestDate = DateTime.parse(keys.last);
    final latestEntry = repo.entryForDate(keys.last);
    if (latestEntry?.weight == null) return null;
    final cutoff = latestDate.subtract(Duration(days: days));
    for (final k in keys) {
      final d = DateTime.parse(k);
      if (d.isBefore(cutoff)) continue;
      final e = repo.entryForDate(k);
      if (e?.weight != null) {
        return (changeKg: latestEntry!.weight! - e!.weight!, fromDate: d);
      }
    }
    return null;
  }

  int _loggingStreak() {
    final keys = repo.sortedDateKeys;
    if (keys.isEmpty) return 0;
    int streak = 1;
    DateTime cursor = DateTime.parse(keys.last);
    for (int i = keys.length - 2; i >= 0; i--) {
      final d = DateTime.parse(keys[i]);
      if (cursor.difference(d).inDays == 1) {
        streak++;
        cursor = d;
      } else {
        break;
      }
    }
    return streak;
  }

  ({double? highKg, double? lowKg}) _weightRange() {
    double? high;
    double? low;
    for (final k in repo.sortedDateKeys) {
      final w = repo.entryForDate(k)?.weight;
      if (w != null) {
        high = (high == null || w > high) ? w : high;
        low = (low == null || w < low) ? w : low;
      }
    }
    return (highKg: high, lowKg: low);
  }

  int _daysLoggedThisMonth() {
    final now = DateTime.now();
    return repo.sortedDateKeys.where((k) {
      final d = DateTime.parse(k);
      return d.year == now.year && d.month == now.month;
    }).length;
  }

  void _showAnalyticsDialog(BuildContext context) {
    final unit = repo.weightUnit;
    final totalLogs = repo.historyBox.length;
    final streak = _loggingStreak();
    final change7 = _weightChangeSince(7);
    final change30 = _weightChangeSince(30);
    final range = _weightRange();
    final monthLogged = _daysLoggedThisMonth();
    final monthTotal = DateTime.now().day;

    String changeLabel(({double changeKg, DateTime fromDate})? change) {
      if (change == null) return 'Not enough data';
      final displayChange = kgToDisplay(change.changeKg, unit);
      final arrow = displayChange < 0 ? '↓' : (displayChange > 0 ? '↑' : '→');
      return '$arrow ${displayChange.abs().toStringAsFixed(1)} ${unit.label}';
    }

    Color changeColor(({double changeKg, DateTime fromDate})? change) {
      if (change == null) return VitalPalette.textMuted;
      if (change.changeKg < 0) return VitalPalette.sage;
      if (change.changeKg > 0) return VitalPalette.flame;
      return VitalPalette.textMuted;
    }

    Widget statTile(String label, String value, {Color? valueColor}) {
      return Container(
        width: 195,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: VitalPalette.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontFamily: VitalPalette.numeralFont, color: valueColor ?? VitalPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('PROGRESS ANALYSIS', style: TextStyle(color: VitalPalette.amber, fontSize: 14, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: totalLogs == 0
                  ? const Text('No logs recorded yet. Start tracking your daily weight to see trends here.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4))
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        statTile('LOGGING STREAK', '$streak day${streak == 1 ? '' : 's'}'),
                        statTile('TOTAL LOGS', '$totalLogs'),
                        statTile('7-DAY CHANGE', changeLabel(change7), valueColor: changeColor(change7)),
                        statTile('30-DAY CHANGE', changeLabel(change30), valueColor: changeColor(change30)),
                        statTile('HIGHEST WEIGHT', range.highKg != null ? '${kgToDisplay(range.highKg!, unit).toStringAsFixed(1)} ${unit.label}' : '--'),
                        statTile('LOWEST WEIGHT', range.lowKg != null ? '${kgToDisplay(range.lowKg!, unit).toStringAsFixed(1)} ${unit.label}' : '--'),
                        statTile('LOGGED THIS MONTH', '$monthLogged / $monthTotal days'),
                      ],
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportClinicalReport(BuildContext context) async {
    await Printing.layoutPdf(onLayout: (format) => buildClinicalReportPdf(repo));
  }

  // Also copies to the clipboard (the Restore flow's paste button expects
  // that), but leads with a share-sheet prompt so the backup lands
  // somewhere durable instead of silently sitting in the clipboard where
  // it's easy to forget about and lose to the next copy/paste.
  Future<void> _shareBackup(BuildContext context) async {
    final jsonString = repo.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: jsonString));

    final dir = await Directory.systemTemp.createTemp('vital_backup');
    final dateStamp = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${dir.path}/project_vital_backup_$dateStamp.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'Project Vital Backup — $dateStamp',
      text: 'Project Vital data backup. Save this somewhere safe (Drive, email to yourself, Files) — it also copied to your clipboard for the in-app Restore flow.',
    ));
  }

  Future<void> _exportCsvData(BuildContext context) async {
    final unit = repo.weightUnit;
    final buffer = StringBuffer('date,weight_${unit.label},waist_cm,calories,protein_g,fasting_hours,steps,systolic,diastolic\n');
    for (final key in repo.sortedDateKeys) {
      final e = repo.entryForDate(key);
      if (e == null) continue;
      final w = e.weight != null ? kgToDisplay(e.weight!, unit).toStringAsFixed(1) : '';
      buffer.writeln('$key,$w,${e.waist ?? ''},${e.calories ?? ''},${e.protein ?? ''},${e.fasting ?? ''},${e.steps ?? ''},${e.systolic ?? ''},${e.diastolic ?? ''}');
    }

    final dir = await Directory.systemTemp.createTemp('vital_export');
    final dateStamp = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${dir.path}/project_vital_export_$dateStamp.csv');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'Project Vital Data Export — $dateStamp',
      text: 'Your logged Project Vital data, opens directly in Excel/Google Sheets.',
    ));
  }

  void _showTrendsDialog(BuildContext context) {
    final unit = repo.weightUnit;
    final metrics = <String, ({String label, Color color, List<FlSpot> Function() spots})>{
      'weight': (label: 'WEIGHT (${unit.label.toUpperCase()})', color: VitalPalette.amber, spots: () => repo.chronologicalWeightSpots().map((s) => FlSpot(s.x, kgToDisplay(s.y, unit))).toList()),
      'waist': (label: 'WAISTLINE (CM)', color: VitalPalette.rose, spots: () => repo.metricSpots('waist')),
      'calories': (label: 'CALORIES', color: VitalPalette.flame, spots: () => repo.metricSpots('calories')),
      'protein': (label: 'PROTEIN (G)', color: VitalPalette.violet, spots: () => repo.metricSpots('protein')),
      'fasting': (label: 'FASTING (HOURS)', color: VitalPalette.teal, spots: () => repo.metricSpots('fasting')),
      'steps': (label: 'STEPS', color: VitalPalette.sky, spots: () => repo.metricSpots('steps')),
      'systolic': (label: 'SYSTOLIC BP', color: VitalPalette.violet, spots: () => repo.metricSpots('systolic')),
    };

    String selected = 'weight';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final metric = metrics[selected]!;
            final spots = metric.spots();
            final dateKeys = repo.sortedDateKeys;
            final rangeLabel = dateKeys.isEmpty
                ? 'No data yet'
                : dateKeys.length == 1
                    ? dateKeys.first
                    : '${dateKeys.first}  →  ${dateKeys.last}';

            return AlertDialog(
              backgroundColor: VitalPalette.ink800,
              title: const Text('TRENDS & GRAPHS', style: TextStyle(color: VitalPalette.amber, fontSize: 14, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: metrics.entries.map((entry) {
                        final isSelected = entry.key == selected;
                        return InkWell(
                          onTap: () => setDialogState(() => selected = entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? entry.value.color.withValues(alpha: 0.18) : Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? entry.value.color : Colors.white24),
                            ),
                            child: Text(entry.value.label, style: TextStyle(color: isSelected ? entry.value.color : Colors.white54, fontWeight: FontWeight.w800, fontSize: 10)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(rangeLabel, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: null, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem(s.y.toStringAsFixed(1), TextStyle(color: metric.color, fontWeight: FontWeight.w800, fontSize: 12))).toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: metric.color,
                              barWidth: 2.5,
                              dotData: FlDotData(show: spots.length <= 30),
                              belowBarData: BarAreaData(show: true, color: metric.color.withValues(alpha: 0.12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMoreMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VitalPalette.ink800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        Widget menuTile(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
          return ListTile(
            leading: Icon(icon, color: color, size: 24),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              onTap();
            },
          );
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        menuTile(Icons.history, VitalPalette.flame, 'Timeline History', 'Every logged day, chronologically', () => _showHistoryDialog(context)),
                        menuTile(Icons.insights, VitalPalette.amber, 'Progress Analysis', 'Weekly / monthly trend summary', () => _showAnalyticsDialog(context)),
                        menuTile(Icons.show_chart, VitalPalette.sky, 'Trends & Graphs', 'Full chart for any tracked metric', () => _showTrendsDialog(context)),
                        menuTile(Icons.breakfast_dining, VitalPalette.violet, 'Meal Macro Presets', 'Stack saved meals into today', () => _showPresetLibraryDialog(context)),
                        menuTile(Icons.cloud_upload_outlined, VitalPalette.sky, 'Backup & Restore', 'Export or restore a full JSON backup', () => _showBackupCloudDialog(context)),
                        menuTile(Icons.file_upload_outlined, VitalPalette.sage, 'Import CSV', 'Bulk-import multiple days at once', () => _showImportCsvDialog(context)),
                        menuTile(Icons.picture_as_pdf_outlined, VitalPalette.flame, 'Clinical Report (PDF)', 'Patient info + 30-day weight/BP table', () => _exportClinicalReport(context)),
                        menuTile(Icons.table_chart_outlined, VitalPalette.sage, 'Export Data (CSV)', 'Excel/Sheets-compatible spreadsheet export', () => _exportCsvData(context)),
                        menuTile(Icons.help_outline, VitalPalette.teal, 'Help', 'How to use Project Vital', () => _showHelpDialog(context)),
                        menuTile(Icons.swap_horiz, VitalPalette.rose, 'Weight Unit', 'Currently ${repo.weightUnit.label.toUpperCase()} — tap to switch', () => _showUnitsDialog(context)),
                        menuTile(Icons.info_outline, VitalPalette.textSecondary, 'About', 'App info & disclaimer', () => _showAboutDialog(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileSettingsDialog(BuildContext context) {
    final unit = repo.weightUnit;
    final goalKg = (repo.vitalsBox.get('user_goal_weight', defaultValue: 63.0) as num).toDouble();
    final TextEditingController nameController = TextEditingController(text: repo.vitalsBox.get('user_name', defaultValue: 'Athlete'));
    final TextEditingController goalController = TextEditingController(text: kgToDisplay(goalKg, unit).toStringAsFixed(1));
    final TextEditingController heightController = TextEditingController(text: repo.vitalsBox.get('user_height', defaultValue: '5.45'));
    String gender = repo.vitalsBox.get('user_gender', defaultValue: 'Male');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: VitalPalette.ink800,
              title: const Text('PROFILE & GOAL SETTINGS', style: TextStyle(color: VitalPalette.amber, fontSize: 16, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Profile Name', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => gender = 'Male'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: gender == 'Male' ? VitalPalette.amber.withValues(alpha: 0.15) : Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: gender == 'Male' ? VitalPalette.amber : Colors.white24),
                              ),
                              child: Text('MALE', style: TextStyle(color: gender == 'Male' ? VitalPalette.amber : Colors.white54, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => gender = 'Female'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: gender == 'Female' ? VitalPalette.rose.withValues(alpha: 0.15) : Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: gender == 'Female' ? VitalPalette.rose : Colors.white24),
                              ),
                              child: Text('FEMALE', style: TextStyle(color: gender == 'Female' ? VitalPalette.rose : Colors.white54, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: heightController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Height (e.g. 5.45 or cm)', labelStyle: const TextStyle(color: VitalPalette.amber), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: goalController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Target Goal Weight (${unit.label})', labelStyle: const TextStyle(color: VitalPalette.rose), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VitalPalette.flame),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh, color: VitalPalette.flame, size: 18),
                        label: const Text('RE-RUN FULL ONBOARDING', style: TextStyle(color: VitalPalette.flame, fontWeight: FontWeight.w900, fontSize: 12)),
                        onPressed: () {
                          repo.vitalsBox.put('profile_setup_complete', false);
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.amber, foregroundColor: Colors.black),
                  onPressed: () {
                    repo.vitalsBox.put('user_name', nameController.text.trim());
                    repo.vitalsBox.put('user_height', heightController.text.trim());
                    repo.vitalsBox.put('user_gender', gender);
                    final goalInput = double.tryParse(goalController.text);
                    repo.vitalsBox.put('user_goal_weight', goalInput != null ? displayToKg(goalInput, unit) : goalKg);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _applyPresetMeal(String mealName, int addCals, int addProtein) async {
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final todayEntry = repo.historyBox.get(todayKey);
    final baseCals = todayEntry is Map ? (int.tryParse(todayEntry['calories']?.toString() ?? '') ?? 0) : 0;
    final baseProt = todayEntry is Map ? (int.tryParse(todayEntry['protein']?.toString() ?? '') ?? 0) : 0;

    repo.upsertHistoryEntry(todayKey, {
      'calories': baseCals + addCals,
      'protein': baseProt + addProtein,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $mealName (+$addCals kcal, +${addProtein}g protein)!')),
      );
    }
  }

  void _showPresetLibraryDialog(BuildContext context) {
    final TextEditingController mealNameController = TextEditingController();
    final TextEditingController calsController = TextEditingController();
    final TextEditingController proteinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final presetKeys = repo.presetsBox.keys.toList();
            return AlertDialog(
              backgroundColor: VitalPalette.ink800,
              title: const Text('CUSTOM MEAL MACRO STACKER', style: TextStyle(color: VitalPalette.violet, fontSize: 16, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tap any meal to instantly stack its macros into todays total:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: presetKeys.isEmpty
                          ? const Center(child: Text('No meal presets saved yet.', style: TextStyle(color: Colors.white54, fontSize: 12)))
                          : ListView.builder(
                              itemCount: presetKeys.length,
                              itemBuilder: (context, index) {
                                final name = presetKeys[index];
                                final data = Map<String, dynamic>.from(repo.presetsBox.get(name));
                                return ListTile(
                                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text('${data['cals']} kcal | ${data['protein']}g Protein', style: const TextStyle(color: VitalPalette.violet, fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.violet, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16)),
                                    onPressed: () {
                                      _applyPresetMeal(name, data['cals'], data['protein']);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('STACK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    const Text('Add New Custom Meal Preset:', style: TextStyle(color: VitalPalette.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: mealNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Meal Name (e.g. Usual Lunch)', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: calsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Calories (kcal)', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: proteinController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Protein (g)', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: VitalPalette.amber)),
                        onPressed: () async {
                          final name = mealNameController.text.trim();
                          final cals = int.tryParse(calsController.text) ?? 0;
                          final prot = int.tryParse(proteinController.text) ?? 0;
                          if (name.isNotEmpty) {
                            await repo.presetsBox.put(name, {'cals': cals, 'protein': prot});
                            setDialogState(() {});
                            mealNameController.clear();
                            calsController.clear();
                            proteinController.clear();
                          }
                        },
                        child: const Text('SAVE NEW PRESET', style: TextStyle(color: VitalPalette.amber, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBackupCloudDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('DATA BACKUP & CLOUD SYNC', style: TextStyle(color: VitalPalette.amber, fontSize: 15, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Export your local database to save locally or upload to Google Drive/iCloud:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.download),
                    label: const Text('SHARE BACKUP FILE (.JSON)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(context);
                      _shareBackup(context);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                const Text('Restore from a previous backup file:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: VitalPalette.flame),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.upload_file, color: VitalPalette.flame, size: 18),
                    label: const Text('RESTORE FROM BACKUP', style: TextStyle(color: VitalPalette.flame, fontWeight: FontWeight.w900, fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(context);
                      _showRestoreBackupDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreBackupDialog(BuildContext context) {
    final TextEditingController jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('RESTORE FROM BACKUP', style: TextStyle(color: VitalPalette.flame, fontSize: 14, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This replaces all current profile, history, and preset data with the backup below. This cannot be undone.', style: TextStyle(color: VitalPalette.flame, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(hintText: 'Paste backup JSON here', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final clip = await Clipboard.getData('text/plain');
                    if (clip?.text != null) jsonController.text = clip!.text!;
                  },
                  icon: const Icon(Icons.paste, color: VitalPalette.amber, size: 16),
                  label: const Text('PASTE FROM CLIPBOARD', style: TextStyle(color: VitalPalette.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.flame, foregroundColor: Colors.black),
              onPressed: () {
                final restored = repo.restoreFromBackupJson(jsonController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(restored ? 'Backup restored!' : 'That backup JSON could not be read. Nothing was changed.')),
                );
              },
              child: const Text('RESTORE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  void _showImportCsvDialog(BuildContext context) {
    final TextEditingController csvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('IMPORT CSV', style: TextStyle(color: VitalPalette.sage, fontSize: 14, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('One row per day. Optionally start with a header row naming only the columns you want (date is required):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                const Text('date, weight, waist, calories, protein, fasting, steps, systolic, diastolic', style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 8),
                const Text('e.g. steps only:', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                const Text('date,steps\n2026-08-01,8200\n2026-08-02,9100', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                const Text('e.g. full row, no header needed:', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                const Text('2026-08-01,76.4,88,1840,128,14.5,8200,118,76', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                TextField(
                  controller: csvController,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(hintText: 'Paste CSV data here', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final clip = await Clipboard.getData('text/plain');
                    if (clip?.text != null) csvController.text = clip!.text!;
                  },
                  icon: const Icon(Icons.paste, color: VitalPalette.amber, size: 16),
                  label: const Text('PASTE FROM CLIPBOARD', style: TextStyle(color: VitalPalette.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.sage, foregroundColor: Colors.black),
              onPressed: () {
                final result = repo.importCsv(csvController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported ${result.imported} day(s)${result.skipped > 0 ? ', skipped ${result.skipped} invalid row(s)' : ''}.')),
                );
              },
              child: const Text('IMPORT', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String dateKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('DELETE LOG?', style: TextStyle(color: VitalPalette.flame, fontSize: 14, fontWeight: FontWeight.w900)),
          content: Text('This permanently deletes the entry for $dateKey. This cannot be undone.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.flame, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final keys = repo.historyBox.keys.toList();
            return AlertDialog(
              backgroundColor: VitalPalette.ink800,
              title: const Text('HISTORICAL TIMELINE', style: TextStyle(color: VitalPalette.amber, fontSize: 16, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 450,
                height: 300,
                child: keys.isEmpty
                    ? const Center(child: Text('No historical logs recorded yet.', style: TextStyle(color: Colors.white54, fontSize: 12)))
                    : ListView.builder(
                        itemCount: keys.length,
                        itemBuilder: (context, index) {
                          final key = keys[index];
                          final val = repo.historyBox.get(key);
                          return ListTile(
                            title: Text('$key', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Data: $val', style: const TextStyle(color: VitalPalette.amber, fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: VitalPalette.flame, size: 20),
                              tooltip: 'Delete this log',
                              onPressed: () async {
                                final confirmed = await _confirmDelete(context, key);
                                if (confirmed) {
                                  repo.historyBox.delete(key);
                                  setDialogState(() {});
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('ABOUT PROJECT VITAL', style: TextStyle(color: VitalPalette.amber, fontSize: 14, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Project Vital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Version 1.0.0', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 12),
                  const Text(
                    'A simple, private, offline-first daily health tracker for weight, waistline, calories, protein, fasting, steps, and blood pressure. All your data stays on this device unless you choose to back it up or export it.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VitalPalette.flame.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: VitalPalette.flame.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: VitalPalette.flame, size: 18),
                            SizedBox(width: 8),
                            Text('DISCLAIMER', style: TextStyle(color: VitalPalette.flame, fontWeight: FontWeight.w900, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Project Vital is a personal tracking tool. It was not built by doctors, nurses, or licensed healthcare professionals — we just track our own numbers. Nothing in this app, including the BMI classification, trend charts, or PDF reports, is medical advice, a diagnosis, or a substitute for professional care. Always consult a qualified healthcare provider about your health, weight, or blood pressure.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    Widget helpItem(IconData icon, Color color, String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('HOW TO USE PROJECT VITAL', style: TextStyle(color: VitalPalette.amber, fontSize: 14, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  helpItem(Icons.add_circle_outline, VitalPalette.amber, "Record today's vitals", 'Tap the + button to log weight, waistline, calories, protein, fasting hours, and steps for today.'),
                  helpItem(Icons.history, VitalPalette.flame, 'Timeline History', "See every day you've logged, in chronological order, from the More menu."),
                  helpItem(Icons.insights, VitalPalette.amber, 'Progress Analysis', 'A quick summary of your logging activity and trends.'),
                  helpItem(Icons.breakfast_dining, VitalPalette.violet, 'Meal Macro Presets', "Save meals you eat often, then stack their calories/protein into today's total with one tap."),
                  helpItem(Icons.cloud_upload_outlined, VitalPalette.sky, 'Backup & Restore', 'Export all your data as JSON to the clipboard, or restore from a previous backup. Restoring replaces all current data.'),
                  helpItem(Icons.file_upload_outlined, VitalPalette.sage, 'Import CSV', 'Paste multiple days of data at once, one row per day.'),
                  helpItem(Icons.person_outline, VitalPalette.rose, 'Profile & Goals', 'Tap your avatar (top right) to update your name, height, gender, or goal weight.'),
                  const Divider(color: Colors.white24, height: 24),
                  const Text('REPORT AN ISSUE OR SUGGESTION', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'help63911@gmail.com'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email address copied to clipboard')),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: VitalPalette.teal, size: 18),
                        const SizedBox(width: 10),
                        const Text('help63911@gmail.com', style: TextStyle(color: VitalPalette.teal, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, color: Colors.white38, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showUnitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final current = repo.weightUnit;
            Widget unitChip(WeightUnit unit, String label) {
              final selected = current == unit;
              return Expanded(
                child: InkWell(
                  onTap: () => setDialogState(() => repo.setWeightUnit(unit)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? VitalPalette.amber.withValues(alpha: 0.15) : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? VitalPalette.amber : Colors.white24),
                    ),
                    child: Text(label, style: TextStyle(color: selected ? VitalPalette.amber : Colors.white54, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: VitalPalette.ink800,
              title: const Text('WEIGHT UNIT', style: TextStyle(color: VitalPalette.amber, fontSize: 14, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 360,
                height: 56,
                child: Row(
                  children: [
                    unitChip(WeightUnit.kg, 'KILOGRAMS (KG)'),
                    const SizedBox(width: 12),
                    unitChip(WeightUnit.lbs, 'POUNDS (LBS)'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Average adult stride length (~0.762m) used to estimate distance walked.
  String _stepsSubtitle(int? steps) {
    if (steps == null) return "GOAL: 20k";
    final km = steps * 0.000762;
    return "≈ ${km.toStringAsFixed(2)} KM";
  }

  String _greetingLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  double _goalProgressFraction(VitalsEntry? latest, double goalWeight) {
    final spots = repo.chronologicalWeightSpots(fallback: latest?.weight ?? 0.0);
    final current = latest?.weight ?? (spots.isNotEmpty ? spots.last.y : 0.0);
    final baseline = spots.isNotEmpty ? spots.first.y : current;
    if (baseline == goalWeight) return current <= goalWeight ? 1.0 : 0.0;
    return ((baseline - current) / (baseline - goalWeight)).clamp(0.0, 1.0);
  }

  Widget _backgroundGlow() {
    Widget blob(Color color, double size, Alignment alignment) {
      return Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.18)),
        ),
      );
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Stack(
        children: [
          blob(VitalPalette.amber, 220, const Alignment(-0.9, -0.9)),
          blob(VitalPalette.teal, 200, const Alignment(1.0, -0.5)),
          blob(VitalPalette.violet, 220, const Alignment(-0.6, 1.0)),
        ],
      ),
    );
  }

  Widget _buildGridCard(String title, String value, String subtitle, IconData icon, Color accentColor, List<FlSpot> sparklineSpots) {
    return vitalGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: accentColor, size: 15),
              ),
              Text(title, style: const TextStyle(fontSize: 11, color: VitalPalette.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: VitalPalette.numeralFont,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: VitalPalette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: VitalPalette.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sparklineSpots,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot == barData.spots.last,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 2.4, color: accentColor, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(show: true, color: accentColor.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickLogForm(BuildContext context, VitalsEntry? todayEntry) {
    DateTime selectedDate = DateTime.now();
    final unit = repo.weightUnit;
    final displayWeight = todayEntry?.weight != null ? kgToDisplay(todayEntry!.weight!, unit) : null;
    final TextEditingController weightController = TextEditingController(text: displayWeight?.toStringAsFixed(1) ?? '');
    final TextEditingController waistController = TextEditingController(text: todayEntry?.waist?.toString() ?? '');
    final TextEditingController caloriesController = TextEditingController(text: todayEntry?.calories?.toString() ?? '');
    final TextEditingController proteinController = TextEditingController(text: todayEntry?.protein?.toString() ?? '');
    final TextEditingController fastingController = TextEditingController(text: todayEntry?.fasting?.toString() ?? '');
    final TextEditingController stepsController = TextEditingController(text: todayEntry?.steps?.toString() ?? '');
    final TextEditingController systolicController = TextEditingController(text: todayEntry?.systolic?.toString() ?? '');
    final TextEditingController diastolicController = TextEditingController(text: todayEntry?.diastolic?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VitalPalette.ink800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 40),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RECORD DAILY VITALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VitalPalette.amber, letterSpacing: 2.0)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          final pickedKey = picked.toIso8601String().split('T')[0];
                          final pickedEntry = repo.entryForDate(pickedKey);
                          final pickedDisplayWeight = pickedEntry?.weight != null ? kgToDisplay(pickedEntry!.weight!, unit) : null;
                          setModalState(() {
                            selectedDate = picked;
                            weightController.text = pickedDisplayWeight?.toStringAsFixed(1) ?? '';
                            waistController.text = pickedEntry?.waist?.toString() ?? '';
                            caloriesController.text = pickedEntry?.calories?.toString() ?? '';
                            proteinController.text = pickedEntry?.protein?.toString() ?? '';
                            fastingController.text = pickedEntry?.fasting?.toString() ?? '';
                            stepsController.text = pickedEntry?.steps?.toString() ?? '';
                            systolicController.text = pickedEntry?.systolic?.toString() ?? '';
                            diastolicController.text = pickedEntry?.diastolic?.toString() ?? '';
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: VitalPalette.amber.withValues(alpha: 0.4))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: VitalPalette.amber, size: 18),
                                const SizedBox(width: 12),
                                Text('Date: ${selectedDate.toIso8601String().split('T')[0]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const Text('CHANGE', style: TextStyle(color: VitalPalette.amber, fontSize: 11, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: weightController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Weight (${unit.label})', labelStyle: const TextStyle(color: VitalPalette.amber), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: waistController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Waistline (cm)', labelStyle: const TextStyle(color: VitalPalette.rose), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: caloriesController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Calories (kcal)', labelStyle: const TextStyle(color: VitalPalette.flame), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: proteinController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Protein (g)', labelStyle: const TextStyle(color: VitalPalette.violet), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: fastingController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Fasting Hours (e.g. 16)', labelStyle: const TextStyle(color: VitalPalette.flame), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: stepsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Steps', labelStyle: const TextStyle(color: VitalPalette.sky), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(controller: systolicController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Systolic (mmHg)', labelStyle: const TextStyle(color: VitalPalette.violet), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(controller: diastolicController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Diastolic (mmHg)', labelStyle: const TextStyle(color: VitalPalette.violet), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        onPressed: () async {
                          final dateKey = selectedDate.toIso8601String().split('T')[0];
                          final wRaw = double.tryParse(weightController.text);
                          final w = wRaw != null ? displayToKg(wRaw, unit) : null;
                          final waist = double.tryParse(waistController.text);
                          final cals = int.tryParse(caloriesController.text);
                          final prot = int.tryParse(proteinController.text);
                          final fast = double.tryParse(fastingController.text);
                          final stps = int.tryParse(stepsController.text);
                          final sys = int.tryParse(systolicController.text);
                          final dia = int.tryParse(diastolicController.text);

                          repo.upsertHistoryEntry(dateKey, {
                            if (w != null) 'weight': w,
                            if (waist != null) 'waist': waist,
                            if (cals != null) 'calories': cals,
                            if (prot != null) 'protein': prot,
                            if (sys != null) 'systolic': sys,
                            if (dia != null) 'diastolic': dia,
                            if (fast != null) 'fasting': fast,
                            if (stps != null) 'steps': stps,
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded vitals for $dateKey!')));
                          }
                        },
                        child: const Text('SAVE RECORD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: repo.vitalsBox.listenable(),
      builder: (context, vitalsBox, _) {
        return ValueListenableBuilder<Box>(
          valueListenable: repo.historyBox.listenable(),
          builder: (context, historyBox, __) {
            final userName = vitalsBox.get('user_name', defaultValue: 'Athlete') as String?;
            final unit = repo.weightUnit;
            final goalWeightKg = (vitalsBox.get('user_goal_weight', defaultValue: 63.0) as num).toDouble();
            final goalWeightDisplay = kgToDisplay(goalWeightKg, unit);
            final latest = repo.latestEntry;
            final todayKey = DateTime.now().toIso8601String().split('T')[0];
            final todayEntry = repo.entryForDate(todayKey);
            final displayWeight = latest?.weight != null ? kgToDisplay(latest!.weight!, unit) : null;

            String currentWeight = displayWeight != null ? "${displayWeight.toStringAsFixed(1)} ${unit.label}" : "-- ${unit.label}";
            String currentWaist = latest?.waist != null ? "${latest?.waist} cm" : "-- cm";
            String currentCalories = latest?.calories != null ? "${latest?.calories}" : "--";
            String currentProtein = latest?.protein != null ? "${latest?.protein} g" : "-- g";
            String currentFasting = latest?.fasting != null ? "${latest?.fasting}h" : "--";
            String currentSteps = latest?.steps != null ? "${latest?.steps}" : "--";
            String currentBP = (latest?.systolic != null && latest?.diastolic != null) ? "${latest?.systolic}/${latest?.diastolic}" : "--/--";

            final heightCm = parseHeightCm(vitalsBox.get('user_height', defaultValue: '5.45'));
            final bmi = latest?.weight != null ? classifyBmi(latest!.weight!, heightCm) : null;
            const bmiColors = {
              'Underweight': VitalPalette.sky,
              'Normal': VitalPalette.sage,
              'Overweight': VitalPalette.amber,
              'Obese': VitalPalette.flame,
            };

            final weightSpots = repo.chronologicalWeightSpots(fallback: latest?.weight ?? 0.0).map((s) => FlSpot(s.x, kgToDisplay(s.y, unit))).toList();
            final waistSpots = repo.metricSpots('waist');
            final calorieSpots = repo.metricSpots('calories');
            final proteinSpots = repo.metricSpots('protein');
            final fastingSpots = repo.metricSpots('fasting');
            final stepSpots = repo.metricSpots('steps');
            final bpSpots = repo.metricSpots('systolic');

            double diff = (displayWeight ?? kgToDisplay(72.0, unit)) - goalWeightDisplay;

            return Scaffold(
              appBar: AppBar(
                toolbarHeight: 92,
                title: Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_greetingLabel(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VitalPalette.amber, letterSpacing: 3.0)),
                      const SizedBox(height: 4),
                      Text(userName ?? 'Athlete', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: VitalPalette.textPrimary, letterSpacing: -0.3)),
                    ],
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => _showProfileSettingsDialog(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [VitalPalette.amber, VitalPalette.amberDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (userName?.isNotEmpty ?? false) ? userName!.substring(0, 1).toUpperCase() : 'A',
                        style: const TextStyle(color: VitalPalette.onAmber, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.more_horiz, color: VitalPalette.textSecondary, size: 26), onPressed: () => _showMoreMenuSheet(context), tooltip: 'More'),
                  const SizedBox(width: 8),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(child: IgnorePointer(child: _backgroundGlow())),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        vitalGlassCard(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
                          borderRadius: BorderRadius.circular(24),
                          child: Row(
                            children: [
                              GoalRing(progress: _goalProgressFraction(latest, goalWeightKg), size: 74),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GOAL · ${goalWeightDisplay.toStringAsFixed(1)} ${unit.label.toUpperCase()}', style: const TextStyle(color: VitalPalette.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                    const SizedBox(height: 6),
                                    Text(
                                      diff > 0 ? '${diff.toStringAsFixed(1)} ${unit.label} remaining' : 'Target reached!',
                                      style: const TextStyle(fontFamily: VitalPalette.numeralFont, color: VitalPalette.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              if (bmi != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: (bmiColors[bmi.label] ?? VitalPalette.textMuted).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(bmi.bmi.toStringAsFixed(1), style: TextStyle(fontFamily: VitalPalette.numeralFont, color: bmiColors[bmi.label] ?? VitalPalette.textMuted, fontSize: 20, fontWeight: FontWeight.w700)),
                                      Text(bmi.label.toUpperCase(), style: TextStyle(color: bmiColors[bmi.label] ?? VitalPalette.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                            children: [
                              _buildGridCard("WEIGHT", currentWeight, "GOAL: ${goalWeightDisplay.toStringAsFixed(1)}", Icons.monitor_weight, VitalPalette.amber, weightSpots),
                              _buildGridCard("WAISTLINE", currentWaist, "TREND: -0.5cm", Icons.straighten, VitalPalette.rose, waistSpots),
                              _buildGridCard("CALORIES", currentCalories, "BUDGET: 2000", Icons.local_fire_department, VitalPalette.flame, calorieSpots),
                              _buildGridCard("PROTEIN", currentProtein, "TARGET: 150g", Icons.fitness_center, VitalPalette.violet, proteinSpots),
                              _buildGridCard("FASTING", currentFasting, "16:8 PROTOCOL", Icons.timer, VitalPalette.teal, fastingSpots),
                              _buildGridCard("STEPS", currentSteps, _stepsSubtitle(latest?.steps), Icons.directions_run, VitalPalette.sky, stepSpots),
                              _buildGridCard("BLOOD PRESSURE", currentBP, "TARGET: <120/80", Icons.favorite_border, VitalPalette.violet, bpSpots),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFF0B15C), VitalPalette.amberDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: VitalPalette.amber.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 1)],
                ),
                child: FloatingActionButton(
                  onPressed: () => _showQuickLogForm(context, todayEntry),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: VitalPalette.onAmber, size: 30),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
