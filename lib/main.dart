import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
// Dark-glass instrument-panel palette: a warm amber accent (goals, CTAs,
// weight) on an ink-navy base, with one desaturated hue per remaining
// metric so the grid scans like biometric categories rather than a
// single flat color repeated six times.
class VitalPalette {
  VitalPalette._();

  static const ink950 = Color(0xFF0B0D12);
  static const ink900 = Color(0xFF0C0F14);
  static const ink800 = Color(0xFF12151C);
  static const ink700 = Color(0xFF1B1F29);
  static const hairline = Color(0x17FFFFFF);
  static const hairlineStrong = Color(0x24FFFFFF);

  static const amber = Color(0xFFE8A23D);
  static const amberDim = Color(0xFFB97A22);
  static const onAmber = Color(0xFF241505);

  static const textPrimary = Color(0xFFF3F1EA);
  static const textSecondary = Color(0xFF9A9CA8);
  static const textMuted = Color(0xFF72747E);

  static const rose = Color(0xFFD97A93);
  static const flame = Color(0xFFE0663D);
  static const violet = Color(0xFF9C8AD1);
  static const teal = Color(0xFF3FB8AE);
  static const sky = Color(0xFF5B9BD8);
  static const sage = Color(0xFF7FB88D);

  static const numeralFont = 'monospace';
}

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
            colors: [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.015)],
          ),
          borderRadius: radius,
          border: Border.all(color: VitalPalette.hairlineStrong, width: 1),
        ),
        child: child,
      ),
    ),
  );
}

class _GoalRing extends StatelessWidget {
  final double progress;
  final double size;
  const _GoalRing({required this.progress, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RingPainter(progress: progress)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 7) / 2;

    final track = Paint()
      ..color = VitalPalette.hairlineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, track);

    final value = Paint()
      ..color = VitalPalette.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * 3.14159265359 * progress.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159265359 / 2, sweep, false, value);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('vitals_box');
  await Hive.openBox('history_box');
  await Hive.openBox('presets_box');
  runApp(const ProjectVitalApp());
}

class ProjectVitalApp extends StatelessWidget {
  const ProjectVitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vitalsBox = Hive.box('vitals_box');
    final bool isProfileSetUp = vitalsBox.get('profile_setup_complete', defaultValue: false);

    return MaterialApp(
      title: 'Project Vital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: VitalPalette.ink950,
        colorScheme: ColorScheme.fromSeed(
          seedColor: VitalPalette.amber,
          brightness: Brightness.dark,
          surface: VitalPalette.ink900,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: VitalPalette.ink800),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: VitalPalette.ink800),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: VitalPalette.textPrimary,
          ),
        ),
      ),
      home: isProfileSetUp ? const DashboardScreen() : const OnboardingScreen(),
    );
  }
}

// ==========================================
// ONBOARDING & PROFILING SCREEN
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController(text: "41");
  final TextEditingController heightController = TextEditingController(text: "5.45");
  final TextEditingController weightController = TextEditingController(text: "72.5");
  final TextEditingController goalWeightController = TextEditingController(text: "63.0");
  
  bool isHeightInFeet = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(-0.8, -0.9),
                      child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: VitalPalette.amber.withOpacity(0.18))),
                    ),
                    Align(
                      alignment: const Alignment(0.9, 0.8),
                      child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: VitalPalette.violet.withOpacity(0.16))),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: vitalGlassCard(
                  padding: const EdgeInsets.all(32),
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('WELCOME TO PROJECT VITAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: VitalPalette.amber, letterSpacing: 2.0)),
                const SizedBox(height: 12),
                const Text('Lets set up your profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 24),

                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Your Name', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: 'Age', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: heightController,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: isHeightInFeet ? 'Height (e.g. 5.45)' : 'Height (cm)',
                                labelStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.black,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                isHeightInFeet = !isHeightInFeet;
                                heightController.text = isHeightInFeet ? "5.45" : "164";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                              decoration: BoxDecoration(
                                color: VitalPalette.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: VitalPalette.amber.withOpacity(0.3)),
                              ),
                              child: Text(
                                isHeightInFeet ? 'FEET' : 'CM',
                                style: const TextStyle(color: VitalPalette.amber, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: 'Current Weight (kg)', labelStyle: const TextStyle(color: VitalPalette.amber), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: goalWeightController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Goal Weight (kg)',
                                labelStyle: const TextStyle(color: VitalPalette.rose),
                                filled: true,
                                fillColor: Colors.black,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VitalPalette.rose.withOpacity(0.2),
                              foregroundColor: VitalPalette.rose,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              double heightCm = double.tryParse(heightController.text) ?? 165.0;
                              if (isHeightInFeet) heightCm = heightCm * 30.48;
                              final suggestedWeight = 22 * ((heightCm / 100.0) * (heightCm / 100.0));
                              goalWeightController.text = suggestedWeight.toStringAsFixed(1);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Auto-suggested ideal weight set to ${suggestedWeight.toStringAsFixed(1)} kg!')),
                              );
                            },
                            child: const Text('AUTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: VitalPalette.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: () {
                      final box = Hive.box('vitals_box');
                      box.put('user_name', nameController.text.trim());
                      box.put('user_age', int.tryParse(ageController.text) ?? 30);
                      box.put('user_height', heightController.text.trim());

                      final currentW = double.tryParse(weightController.text) ?? 72.0;
                      final goalW = double.tryParse(goalWeightController.text) ?? 63.0;

                      box.put('user_goal_weight', goalW);
                      box.put('profile_setup_complete', true);

                      final historyBox = Hive.box('history_box');
                      final todayKey = DateTime.now().toIso8601String().split('T')[0];
                      if (historyBox.get(todayKey) is! Map) {
                        historyBox.put(todayKey, {'weight': currentW});
                      }

                      final presetsBox = Hive.box('presets_box');
                      if (presetsBox.isEmpty) {
                        presetsBox.put('Morning Oats', {'cals': 420, 'protein': 35});
                        presetsBox.put('Usual Lunch', {'cals': 650, 'protein': 45});
                      }

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      }
                    },
                    child: const Text('INITIALIZE DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// DASHBOARD SCREEN
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box vitalsBox;
  late Box historyBox;
  late Box presetsBox;
  
  String? userName;
  double? savedWeight;
  double? goalWeight;
  double? savedWaistline;
  int? savedCalories;
  int? savedProtein;
  double? savedFasting;
  int? savedSteps;


@override
void initState() {
  super.initState();
  vitalsBox = Hive.box('vitals_box');
  historyBox = Hive.box('history_box');
  presetsBox = Hive.box('presets_box');

  // historyBox.clear(); // <-- Remove or comment out this line!

  if (presetsBox.isEmpty) {
    presetsBox.put('Morning Oats', {'cals': 420, 'protein': 35});
    presetsBox.put('Usual Lunch', {'cals': 650, 'protein': 45});
  }
  _loadData();
}


// 1. Add this Analytics Dialog method inside your State class
  void _showAnalyticsDialog(BuildContext context) {
    // Calculate simple stats from historyBox
    int totalLogs = historyBox.length;
    
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
                      color: VitalPalette.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VitalPalette.amber.withOpacity(0.3)),
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
                  // Summary tile generator
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

// Chronological Date-Sorted Weight Spots Generator
List<FlSpot> getChronologicalWeightSpots() {
  try {
    final keys = historyBox.keys.toList();
    final dateKeys = keys.where((k) => k is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)).toList();

    // Sort strictly oldest to newest using DateTime parsing
    dateKeys.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    List<FlSpot> spots = [];
    for (int i = 0; i < dateKeys.length; i++) {
      final entry = historyBox.get(dateKeys[i]);
      if (entry is Map) {
        final val = double.tryParse(entry['weight']?.toString() ?? '');
        if (val != null) {
          spots.add(FlSpot(i.toDouble(), val));
        }
      }
    }

    if (spots.length == 1) {
      final singleVal = spots[0].y;
      return [FlSpot(0, singleVal), FlSpot(1, singleVal)];
    }

    if (spots.isNotEmpty) return spots;
  } catch (_) {}
  
  double currentW = savedWeight ?? 0.0;
  return [FlSpot(0, currentW), FlSpot(1, currentW)];
}



void _loadData() {
  setState(() {
    userName = vitalsBox.get('user_name', defaultValue: 'Athlete');
    goalWeight = vitalsBox.get('user_goal_weight', defaultValue: 63.0);

    final keys = historyBox.keys.where((k) => k is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)).toList();
    
    if (keys.isNotEmpty) {
      keys.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
      final latestKey = keys.last; 
      final dynamic rawLog = historyBox.get(latestKey);

      if (rawLog != null && rawLog is Map) {
        final wVal = rawLog['weight'] ?? rawLog['w'] ?? rawLog['W'];
        final waistVal = rawLog['waist'] ?? rawLog['waistline'] ?? rawLog['W_cm'];
        final calVal = rawLog['calories'] ?? rawLog['cal'] ?? rawLog['c'] ?? rawLog['C'];
        final proVal = rawLog['protein'] ?? rawLog['pro'] ?? rawLog['p'] ?? rawLog['P'];
        final fastVal = rawLog['fasting'] ?? rawLog['fast'];
        final stepsVal = rawLog['steps'];

        savedWeight = wVal != null ? double.tryParse(wVal.toString()) ?? (wVal is num ? wVal.toDouble() : null) : null;
        savedWaistline = waistVal != null ? double.tryParse(waistVal.toString()) ?? (waistVal is num ? waistVal.toDouble() : null) : null;
        savedCalories = calVal != null ? int.tryParse(calVal.toString()) ?? (calVal is num ? calVal.toInt() : null) : null;
        savedProtein = proVal != null ? int.tryParse(proVal.toString()) ?? (proVal is num ? proVal.toInt() : null) : null;
        savedFasting = fastVal != null ? double.tryParse(fastVal.toString()) ?? (fastVal is num ? fastVal.toDouble() : null) : null;
        savedSteps = stepsVal != null ? int.tryParse(stepsVal.toString()) ?? (stepsVal is num ? stepsVal.toInt() : null) : null;
        return;
      }
    }

    savedWeight = null;
    savedWaistline = null;
    savedCalories = null;
    savedProtein = null;
    savedFasting = null;
    savedSteps = null;
  });
}

// Single source of truth for writing a day's metrics: always a Map, merged
// with whatever is already stored for that date so partial updates (e.g. a
// preset macro stack) don't clobber the other fields.
void _upsertHistoryEntry(String dateKey, Map<String, dynamic> updates) {
  final existing = historyBox.get(dateKey);
  final merged = <String, dynamic>{
    if (existing is Map) ...Map<String, dynamic>.from(existing),
    ...updates,
  };
  historyBox.put(dateKey, merged);
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
    final TextEditingController nameController = TextEditingController(text: userName);
    final TextEditingController goalController = TextEditingController(text: goalWeight?.toString() ?? '63.0');
    final TextEditingController heightController = TextEditingController(text: vitalsBox.get('user_height', defaultValue: '5.45'));

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
                          vitalsBox.put('profile_setup_complete', false);
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
                    vitalsBox.put('user_name', nameController.text.trim());
                    vitalsBox.put('user_height', heightController.text.trim());
                    vitalsBox.put('user_goal_weight', double.tryParse(goalController.text) ?? 63.0);
                    _loadData();
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
    final todayEntry = historyBox.get(todayKey);
    final baseCals = todayEntry is Map ? (int.tryParse(todayEntry['calories']?.toString() ?? '') ?? 0) : 0;
    final baseProt = todayEntry is Map ? (int.tryParse(todayEntry['protein']?.toString() ?? '') ?? 0) : 0;

    _upsertHistoryEntry(todayKey, {
      'calories': baseCals + addCals,
      'protein': baseProt + addProtein,
    });
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $mealName (+${addCals} kcal, +${addProtein}g protein)!')),
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
            final presetKeys = presetsBox.keys.toList();
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
                                final data = Map<String, dynamic>.from(presetsBox.get(name));
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
                            await presetsBox.put(name, {'cals': cals, 'protein': prot});
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
                      final Map<String, dynamic> exportData = {
                        'vitals': vitalsBox.toMap(),
                        'history': historyBox.toMap(),
                        'presets': presetsBox.toMap(),
                        'export_date': DateTime.now().toIso8601String(),
                      };
                      
                      final jsonString = jsonEncode(exportData);
                      Clipboard.setData(ClipboardData(text: jsonString));

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
                final restored = _restoreFromBackupJson(jsonController.text);
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

  bool _restoreFromBackupJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['vitals'] is! Map || decoded['history'] is! Map || decoded['presets'] is! Map) {
        return false;
      }
      _replaceBoxContents(vitalsBox, Map<String, dynamic>.from(decoded['vitals']));
      _replaceBoxContents(historyBox, Map<String, dynamic>.from(decoded['history']));
      _replaceBoxContents(presetsBox, Map<String, dynamic>.from(decoded['presets']));
      _loadData();
      return true;
    } catch (_) {
      return false;
    }
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
                final result = _importCsv(csvController.text);
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

  ({int imported, int skipped}) _importCsv(String raw) {
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    int imported = 0;
    int skipped = 0;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final cols = line.split(',').map((c) => c.trim()).toList();
      final dateKey = cols.isNotEmpty ? cols[0] : '';
      if (!dateRegex.hasMatch(dateKey)) continue; // header row or junk line

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

      if (updates.isEmpty) {
        skipped++;
        continue;
      }

      _upsertHistoryEntry(dateKey, updates);
      imported++;
    }

    if (imported > 0) _loadData();
    return (imported: imported, skipped: skipped);
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final keys = historyBox.keys.toList();
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
                      final val = historyBox.get(key);
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

  double _goalProgressFraction() {
    final spots = getChronologicalWeightSpots();
    final current = savedWeight ?? (spots.isNotEmpty ? spots.last.y : 0.0);
    final goal = goalWeight ?? 63.0;
    final baseline = spots.isNotEmpty ? spots.first.y : current;
    if (baseline == goal) return current <= goal ? 1.0 : 0.0;
    return ((baseline - current) / (baseline - goal)).clamp(0.0, 1.0);
  }

  Widget _backgroundGlow() {
    Widget blob(Color color, double size, Alignment alignment) {
      return Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.18)),
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

  Widget _glassCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(18.0), BorderRadius? borderRadius}) {
    return vitalGlassCard(child: child, padding: padding, borderRadius: borderRadius);
  }

  Widget _buildGridCard(String title, String value, String subtitle, IconData icon, Color accentColor, List<FlSpot> sparklineSpots) {
    return _glassCard(
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
                decoration: BoxDecoration(color: accentColor.withOpacity(0.16), borderRadius: BorderRadius.circular(8)),
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
                    belowBarData: BarAreaData(show: true, color: accentColor.withOpacity(0.15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickLogForm(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final TextEditingController weightController = TextEditingController(text: savedWeight?.toString() ?? '');
    final TextEditingController waistController = TextEditingController(text: savedWaistline?.toString() ?? '');
    final TextEditingController caloriesController = TextEditingController(text: savedCalories?.toString() ?? '');
    final TextEditingController proteinController = TextEditingController(text: savedProtein?.toString() ?? '');
    final TextEditingController fastingController = TextEditingController(text: savedFasting?.toString() ?? '');
    final TextEditingController stepsController = TextEditingController(text: savedSteps?.toString() ?? '');

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
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: VitalPalette.amber.withOpacity(0.4))),
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

                          _upsertHistoryEntry(dateKey, {
                            if (w != null) 'weight': w,
                            if (waist != null) 'waist': waist,
                            if (cals != null) 'calories': cals,
                            if (prot != null) 'protein': prot,
                            if (fast != null) 'fasting': fast,
                            if (stps != null) 'steps': stps,
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadData();
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




  List<FlSpot> _getMetricSpots(String key) {
    try {
      final keys = historyBox.keys.where((k) => k is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)).toList();
      keys.sort((a, b) => a.compareTo(b));
      List<FlSpot> spots = [];
      for (int i = 0; i < keys.length; i++) {
        final entry = historyBox.get(keys[i]);
        if (entry is Map && entry[key] != null) {
        final val = double.tryParse(entry[key].toString());
        if (val != null) spots.add(FlSpot(i.toDouble(), val));
        }
      }
      if (spots.isNotEmpty) return spots;
    } catch (_) {}
    return [const FlSpot(0, 0), const FlSpot(1, 0)];
  }








  @override
  Widget build(BuildContext context) {
    String currentWeight = savedWeight != null ? "$savedWeight kg" : "-- kg";
    String currentWaist = savedWaistline != null ? "$savedWaistline cm" : "-- cm";
    String currentCalories = savedCalories != null ? "$savedCalories" : "--";
    String currentProtein = savedProtein != null ? "$savedProtein g" : "-- g";
    String currentFasting = savedFasting != null ? "${savedFasting}h" : "--";
    String currentSteps = savedSteps != null ? "$savedSteps" : "--";



  
  // Dynamic sparklines from actual history entries
    final weightSpots = getChronologicalWeightSpots();
    final waistSpots = _getMetricSpots('waist');
    final calorieSpots = _getMetricSpots('calories');
    final proteinSpots = _getMetricSpots('protein');
    final fastingSpots = _getMetricSpots('fasting');
    final stepSpots = _getMetricSpots('steps');

    double diff = (savedWeight ?? 72.0) - (goalWeight ?? 63.0);

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
                _glassCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                  borderRadius: BorderRadius.circular(22),
                  child: Row(
                    children: [
                      _GoalRing(progress: _goalProgressFraction(), size: 58),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GOAL · ${goalWeight ?? 63.0} KG', style: const TextStyle(color: VitalPalette.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
          boxShadow: [BoxShadow(color: VitalPalette.amber.withOpacity(0.35), blurRadius: 20, spreadRadius: 1)],
        ),
        child: FloatingActionButton(
          onPressed: () => _showQuickLogForm(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: VitalPalette.onAmber, size: 30),
        ),
      ),
    );
  }
}