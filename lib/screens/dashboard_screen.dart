import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/vitals_entry.dart';
import '../services/vitals_repository.dart';
import '../theme/vital_palette.dart';
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

  void _showAnalyticsDialog(BuildContext context) {
    int totalLogs = repo.historyBox.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VitalPalette.ink800,
          title: const Text('PROGRESS & AUTOMATED ANALYSIS', style: TextStyle(color: VitalPalette.amber, fontSize: 14, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('WEEKLY & MONTHLY TREND ANALYSIS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VitalPalette.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VitalPalette.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.insights, color: VitalPalette.amber, size: 18),
                            SizedBox(width: 8),
                            Text('AI Vitals Assessment', style: TextStyle(color: VitalPalette.amber, fontWeight: FontWeight.w900, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          totalLogs > 0
                            ? 'You have logged $totalLogs entries total. Your chronological timeline is active, ensuring backdated records map seamlessly across your monthly progress graphs.'
                            : 'No logs recorded yet. Start tracking your daily weight, waistline, and macros to activate automated trend analysis!',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('METRIC BREAKDOWN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.monitor_weight, color: VitalPalette.amber),
                    title: const Text('Weight Timeline', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sorted chronologically by log date', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    trailing: const Text('Active', style: TextStyle(color: VitalPalette.amber, fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _showMoreMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              menuTile(Icons.history, VitalPalette.flame, 'Timeline History', 'Every logged day, chronologically', () => _showHistoryDialog(context)),
              menuTile(Icons.insights, VitalPalette.amber, 'Progress Analysis', 'Weekly / monthly trend summary', () => _showAnalyticsDialog(context)),
              menuTile(Icons.breakfast_dining, VitalPalette.violet, 'Meal Macro Presets', 'Stack saved meals into today', () => _showPresetLibraryDialog(context)),
              menuTile(Icons.cloud_upload_outlined, VitalPalette.sky, 'Backup & Restore', 'Export or restore a full JSON backup', () => _showBackupCloudDialog(context)),
              menuTile(Icons.file_upload_outlined, VitalPalette.sage, 'Import CSV', 'Bulk-import multiple days at once', () => _showImportCsvDialog(context)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showProfileSettingsDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: repo.vitalsBox.get('user_name', defaultValue: 'Athlete'));
    final TextEditingController goalController = TextEditingController(text: repo.vitalsBox.get('user_goal_weight', defaultValue: 63.0).toString());
    final TextEditingController heightController = TextEditingController(text: repo.vitalsBox.get('user_height', defaultValue: '5.45'));

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
                      decoration: InputDecoration(labelText: 'Target Goal Weight (kg)', labelStyle: const TextStyle(color: VitalPalette.rose), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
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
                    repo.vitalsBox.put('user_goal_weight', double.tryParse(goalController.text) ?? 63.0);
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
                    label: const Text('DOWNLOAD BACKUP FILE (.JSON)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: repo.exportBackupJson()));

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup JSON copied to clipboard & ready to save to Cloud/Drive!')),
                      );
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
                const Text('One row per day. Columns: date,weight,waist,calories,protein,fasting,steps', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                const Text('e.g. 2026-08-01,76.4,88,1840,128,14.5,8200', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
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

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
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
              Text(title, style: const TextStyle(fontSize: 9, color: VitalPalette.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: VitalPalette.numeralFont,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: VitalPalette.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 9.5, color: VitalPalette.textMuted, fontWeight: FontWeight.w500)),
            ],
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

  void _showQuickLogForm(BuildContext context, VitalsEntry? latest) {
    DateTime selectedDate = DateTime.now();
    final TextEditingController weightController = TextEditingController(text: latest?.weight?.toString() ?? '');
    final TextEditingController waistController = TextEditingController(text: latest?.waist?.toString() ?? '');
    final TextEditingController caloriesController = TextEditingController(text: latest?.calories?.toString() ?? '');
    final TextEditingController proteinController = TextEditingController(text: latest?.protein?.toString() ?? '');
    final TextEditingController fastingController = TextEditingController(text: latest?.fasting?.toString() ?? '');
    final TextEditingController stepsController = TextEditingController(text: latest?.steps?.toString() ?? '');

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
                          setModalState(() { selectedDate = picked; });
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
                    TextField(controller: weightController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Weight (kg)', labelStyle: const TextStyle(color: VitalPalette.amber), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
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
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        onPressed: () async {
                          final dateKey = selectedDate.toIso8601String().split('T')[0];
                          final w = double.tryParse(weightController.text);
                          final waist = double.tryParse(waistController.text);
                          final cals = int.tryParse(caloriesController.text);
                          final prot = int.tryParse(proteinController.text);
                          final fast = double.tryParse(fastingController.text);
                          final stps = int.tryParse(stepsController.text);

                          repo.upsertHistoryEntry(dateKey, {
                            if (w != null) 'weight': w,
                            if (waist != null) 'waist': waist,
                            if (cals != null) 'calories': cals,
                            if (prot != null) 'protein': prot,
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
            final goalWeight = (vitalsBox.get('user_goal_weight', defaultValue: 63.0) as num).toDouble();
            final latest = repo.latestEntry;

            String currentWeight = latest?.weight != null ? "${latest?.weight} kg" : "-- kg";
            String currentWaist = latest?.waist != null ? "${latest?.waist} cm" : "-- cm";
            String currentCalories = latest?.calories != null ? "${latest?.calories}" : "--";
            String currentProtein = latest?.protein != null ? "${latest?.protein} g" : "-- g";
            String currentFasting = latest?.fasting != null ? "${latest?.fasting}h" : "--";
            String currentSteps = latest?.steps != null ? "${latest?.steps}" : "--";

            final weightSpots = repo.chronologicalWeightSpots(fallback: latest?.weight ?? 0.0);
            final waistSpots = repo.metricSpots('waist');
            final calorieSpots = repo.metricSpots('calories');
            final proteinSpots = repo.metricSpots('protein');
            final fastingSpots = repo.metricSpots('fasting');
            final stepSpots = repo.metricSpots('steps');

            double diff = (latest?.weight ?? 72.0) - goalWeight;

            return Scaffold(
              appBar: AppBar(
                toolbarHeight: 78,
                title: Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('VITALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VitalPalette.amber, letterSpacing: 3.0)),
                      const SizedBox(height: 3),
                      Text(userName ?? 'Athlete', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: VitalPalette.textPrimary, letterSpacing: -0.2)),
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                          borderRadius: BorderRadius.circular(22),
                          child: Row(
                            children: [
                              GoalRing(progress: _goalProgressFraction(latest, goalWeight), size: 58),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GOAL · $goalWeight KG', style: const TextStyle(color: VitalPalette.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                    const SizedBox(height: 5),
                                    Text(
                                      diff > 0 ? '${diff.toStringAsFixed(1)} kg remaining' : 'Target reached!',
                                      style: const TextStyle(fontFamily: VitalPalette.numeralFont, color: VitalPalette.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
                                    ),
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
                              _buildGridCard("WEIGHT", currentWeight, "GOAL: $goalWeight", Icons.monitor_weight, VitalPalette.amber, weightSpots),
                              _buildGridCard("WAISTLINE", currentWaist, "TREND: -0.5cm", Icons.straighten, VitalPalette.rose, waistSpots),
                              _buildGridCard("CALORIES", currentCalories, "BUDGET: 2000", Icons.local_fire_department, VitalPalette.flame, calorieSpots),
                              _buildGridCard("PROTEIN", currentProtein, "TARGET: 150g", Icons.fitness_center, VitalPalette.violet, proteinSpots),
                              _buildGridCard("FASTING", currentFasting, "16:8 PROTOCOL", Icons.timer, VitalPalette.teal, fastingSpots),
                              _buildGridCard("STEPS", currentSteps, "GOAL: 20k", Icons.directions_run, VitalPalette.sky, stepSpots),
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
                  onPressed: () => _showQuickLogForm(context, latest),
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
