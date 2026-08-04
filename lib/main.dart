import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

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
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('WELCOME TO PROJECT VITAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.tealAccent, letterSpacing: 2.0)),
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
                                color: Colors.tealAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                              ),
                              child: Text(
                                isHeightInFeet ? 'FEET' : 'CM',
                                style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w900, fontSize: 12),
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
                        decoration: InputDecoration(labelText: 'Current Weight (kg)', labelStyle: const TextStyle(color: Colors.tealAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
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
                                labelStyle: const TextStyle(color: Colors.pinkAccent),
                                filled: true,
                                fillColor: Colors.black,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                              foregroundColor: Colors.pinkAccent,
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: () async {
                      final box = Hive.box('vitals_box');
                      await box.put('user_name', nameController.text.trim());
                      await box.put('user_age', int.tryParse(ageController.text) ?? 30);
                      await box.put('user_height', heightController.text.trim());
                      
                      final currentW = double.tryParse(weightController.text) ?? 72.0;
                      final goalW = double.tryParse(goalWeightController.text) ?? 63.0;

                      await box.put('latest_weight', currentW);
                      await box.put('user_goal_weight', goalW);
                      await box.put('profile_setup_complete', true);

                      final presetsBox = Hive.box('presets_box');
                      if (presetsBox.isEmpty) {
                        await presetsBox.put('Morning Oats', {'cals': 420, 'protein': 35});
                        await presetsBox.put('Usual Lunch', {'cals': 650, 'protein': 45});
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

  String currentWeight = 'No log today';
  String currentWaist = 'No log today';
  String currentCalories = '0';
  String currentProtein = '0g';
  String currentFasting = '0h';
  String currentSteps = '0';




  @override
  void initState() {
    super.initState();
    vitalsBox = Hive.box('vitals_box');
    historyBox = Hive.box('history_box');
    presetsBox = Hive.box('presets_box');
    
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
          backgroundColor: const Color(0xFF111111),
          title: const Text('PROGRESS & AUTOMATED ANALYSIS', style: TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.w900)),
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
                      color: Colors.tealAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.insights, color: Colors.tealAccent, size: 18),
                            SizedBox(width: 8),
                            Text('AI Vitals Assessment', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w900, fontSize: 12)),
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
                    leading: const Icon(Icons.monitor_weight, color: Colors.tealAccent),
                    title: const Text('Weight Timeline', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sorted chronologically by log date', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    trailing: const Text('Active', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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
    
    // Filter keys that match the YYYY-MM-DD date format
    final dateKeys = keys.where((k) {
      if (k is! String) return false;
      return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k);
    }).toList();

    // Sort dates strictly chronological (Oldest to Newest)
    dateKeys.sort((a, b) => a.compareTo(b));

    List<FlSpot> spots = [];
    for (int i = 0; i < dateKeys.length; i++) {
      final entry = historyBox.get(dateKeys[i]);
      if (entry != null && entry is Map) {
        // Extract weight dynamically from the map
        final dynamic rawWeight = entry['weight'] ?? entry['Weight'];
        final double? weightVal = double.tryParse(rawWeight?.toString() ?? '');
        
        if (weightVal != null && weightVal > 0) {
          spots.add(FlSpot(i.toDouble(), weightVal));
        }
      }
    }

    if (spots.isNotEmpty) {
      return spots;
    }
  } catch (_) {}

  // Fallback default spots if empty
  return [const FlSpot(0, 72.0), const FlSpot(1, 72.5)];
}



void _loadData() {
  final todayKey = DateTime.now().toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
  final todayLog = historyBox.get(todayKey);

  setState(() {
    userName = vitalsBox.get('user_name', defaultValue: 'Athlete');
    goalWeight = vitalsBox.get('user_goal_weight', defaultValue: 63.0);
    
    // Load latest values from vitalsBox into your state variables
    savedWeight = vitalsBox.get('latest_weight');
    savedWaistline = vitalsBox.get('latest_waistline');
    savedCalories = vitalsBox.get('latest_calories');
    savedProtein = vitalsBox.get('latest_protein');
    savedFasting = vitalsBox.get('latest_fasting');
    savedSteps = vitalsBox.get('latest_steps');

    if (todayLog != null && todayLog is Map) {
      if (todayLog['weight'] != null) savedWeight = double.tryParse(todayLog['weight'].toString());
      if (todayLog['waist'] != null) savedWaistline = double.tryParse(todayLog['waist'].toString());
      if (todayLog['calories'] != null) savedCalories = int.tryParse(todayLog['calories'].toString());
      if (todayLog['protein'] != null) savedProtein = int.tryParse(todayLog['protein'].toString());
      if (todayLog['fasting'] != null) savedFasting = double.tryParse(todayLog['fasting'].toString());
      if (todayLog['steps'] != null) savedSteps = int.tryParse(todayLog['steps'].toString());
    }
  });
}


void _showLogDialog(BuildContext context) {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController fastingController = TextEditingController();
  final TextEditingController stepsController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Log Daily Metrics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)')),
              TextField(controller: waistController, decoration: const InputDecoration(labelText: 'Waistline (cm)')),
              TextField(controller: caloriesController, decoration: const InputDecoration(labelText: 'Calories')),
              TextField(controller: proteinController, decoration: const InputDecoration(labelText: 'Protein (g)')),
              TextField(controller: fastingController, decoration: const InputDecoration(labelText: 'Fasting (hours)')),
              TextField(controller: stepsController, decoration: const InputDecoration(labelText: 'Steps')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final double w = double.tryParse(weightController.text) ?? 0.0;
              final double waist = double.tryParse(waistController.text) ?? 0.0;
              final int cal = int.tryParse(caloriesController.text) ?? 0;
              final int pro = int.tryParse(proteinController.text) ?? 0;
              final double fast = double.tryParse(fastingController.text) ?? 0.0;
              final int steps = int.tryParse(stepsController.text) ?? 0;

              _saveDailyMetrics(w, waist, cal, pro, fast, steps);
              Navigator.of(context).pop();
            },
            child: const Text('Save Metrics'),
          ),
        ],
      );
    },
  );
}



void _saveDailyMetrics(double weight, double waist, int calories, int protein, double fasting, int steps) {
  final todayKey = DateTime.now().toIso8601String().split('T')[0]; // Format: 2026-08-04

  // 1. Save strictly under today's date key in historyBox
  historyBox.put(todayKey, {
    'weight': weight,
    'waist': waist,
    'calories': calories,
    'protein': protein,
    'fasting': fasting,
    'steps': steps,
  });

  // 2. Also update latest values in vitalsBox so fallback views populate instantly
  vitalsBox.put('latest_weight', weight);
  vitalsBox.put('latest_waistline', waist);
  vitalsBox.put('latest_calories', calories);
  vitalsBox.put('latest_protein', protein);
  vitalsBox.put('latest_fasting', fasting);
  vitalsBox.put('latest_steps', steps);

  // 3. Reload dashboard state so UI updates immediately
  _loadData();
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
              backgroundColor: const Color(0xFF111111),
              title: const Text('PROFILE & GOAL SETTINGS', style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.w900)),
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
                      decoration: InputDecoration(labelText: 'Height (e.g. 5.45 or cm)', labelStyle: const TextStyle(color: Colors.tealAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: goalController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Target Goal Weight (kg)', labelStyle: const TextStyle(color: Colors.pinkAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orangeAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.orangeAccent, size: 18),
                        label: const Text('RE-RUN FULL ONBOARDING', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                        onPressed: () async {
                          await vitalsBox.put('profile_setup_complete', false);
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                  onPressed: () async {
                    await vitalsBox.put('user_name', nameController.text.trim());
                    await vitalsBox.put('user_height', heightController.text.trim());
                    await vitalsBox.put('user_goal_weight', double.tryParse(goalController.text) ?? 63.0);
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
    int currentCals = savedCalories ?? 0;
    int currentProt = savedProtein ?? 0;

    int newCals = currentCals + addCals;
    int newProt = currentProt + addProtein;

    await vitalsBox.put('latest_calories', newCals);
    await vitalsBox.put('latest_protein', newProt);
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
              backgroundColor: const Color(0xFF111111),
              title: const Text('CUSTOM MEAL MACRO STACKER', style: TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.w900)),
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
                                  subtitle: Text('${data['cals']} kcal | ${data['protein']}g Protein', style: const TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16)),
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
                    const Text('Add New Custom Meal Preset:', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.tealAccent)),
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
                        child: const Text('SAVE NEW PRESET', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w900)),
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
          backgroundColor: const Color(0xFF111111),
          title: const Text('DATA BACKUP & CLOUD SYNC', style: TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.w900)),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
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
                      side: const BorderSide(color: Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.upload_file, color: Colors.orangeAccent, size: 18),
                    label: const Text('RESTORE FROM BACKUP', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paste your backup JSON data to restore your timeline.')),
                      );
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

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final keys = historyBox.keys.toList();
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text('HISTORICAL TIMELINE', style: TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.w900)),
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
                        subtitle: Text('Data: $val', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
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

  Widget _buildGridCard(String title, String value, String subtitle, IconData icon, Color accentColor, List<FlSpot> sparklineSpots) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Text(title, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(
            height: 35,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sparklineSpots,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
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
      backgroundColor: const Color(0xFF111111),
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
                    const Text('RECORD DAILY VITALS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.tealAccent, letterSpacing: 2.0)),
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
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.tealAccent.withOpacity(0.4))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.tealAccent, size: 18),
                                const SizedBox(width: 12),
                                Text('Date: ${selectedDate.toIso8601String().split('T')[0]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const Text('CHANGE', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: weightController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Weight (kg)', labelStyle: const TextStyle(color: Colors.tealAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: waistController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Waistline (cm)', labelStyle: const TextStyle(color: Colors.pinkAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: caloriesController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Calories (kcal)', labelStyle: const TextStyle(color: Colors.deepOrangeAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: proteinController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Protein (g)', labelStyle: const TextStyle(color: Colors.purpleAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: fastingController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Fasting Hours (e.g. 16)', labelStyle: const TextStyle(color: Colors.orangeAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: stepsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'Steps', labelStyle: const TextStyle(color: Colors.blueAccent), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
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

                          if (w != null) await vitalsBox.put('latest_weight', w);
                          if (waist != null) await vitalsBox.put('latest_waistline', waist);
                          if (cals != null) await vitalsBox.put('latest_calories', cals);
                          if (prot != null) await vitalsBox.put('latest_protein', prot);
                          if (fast != null) await vitalsBox.put('latest_fasting', fast);
                          if (stps != null) await vitalsBox.put('latest_steps', stps);

                          await historyBox.put(dateKey, 'W:${w ?? "--"}kg | C:${cals ?? "--"} | P:${prot ?? "--"}g');

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

  @override
  Widget build(BuildContext context) {
    String currentWeight = savedWeight != null ? "$savedWeight kg" : "-- kg";
    String currentWaist = savedWaistline != null ? "$savedWaistline cm" : "-- cm";
    String currentCalories = savedCalories != null ? "$savedCalories" : "--";
    String currentProtein = savedProtein != null ? "$savedProtein g" : "-- g";
    String currentFasting = savedFasting != null ? "${savedFasting}h" : "--";
    String currentSteps = savedSteps != null ? "$savedSteps" : "--";

    final weightSpots = [const FlSpot(0, 74), const FlSpot(1, 73.5), const FlSpot(2, 72.9), FlSpot(3, savedWeight ?? 72.5)];
    final waistSpots = [const FlSpot(0, 90), const FlSpot(1, 89), const FlSpot(2, 88.5)];
    final calorieSpots = [const FlSpot(0, 1950), const FlSpot(1, 1800), const FlSpot(2, 1900)];
    final proteinSpots = [const FlSpot(0, 120), const FlSpot(1, 130), const FlSpot(2, 140)];
    final fastingSpots = [const FlSpot(0, 16), const FlSpot(1, 16), const FlSpot(2, 16)];
    final stepSpots = [const FlSpot(0, 18000), const FlSpot(1, 19500), const FlSpot(2, 21000)];

    double diff = (savedWeight ?? 72.0) - (goalWeight ?? 63.0);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 16.0),
          child: Text('V I T A L S - $userName'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.tealAccent, size: 28), onPressed: () => _showProfileSettingsDialog(context), tooltip: 'Profile Settings'),
          IconButton(icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent, size: 28), onPressed: () => _showBackupCloudDialog(context), tooltip: 'Cloud Backup'),
          IconButton(icon: const Icon(Icons.history, color: Colors.orangeAccent, size: 28), onPressed: () => _showHistoryDialog(context), tooltip: 'Timeline History'),


          IconButton(
            icon: const Icon(Icons.insights, color: Colors.tealAccent, size: 20),
            onPressed: () => _showAnalyticsDialog(context),
            tooltip: 'Weekly / Monthly Progress',
          ),


          IconButton(icon: const Icon(Icons.breakfast_dining, color: Colors.purpleAccent, size: 28), onPressed: () => _showPresetLibraryDialog(context), tooltip: 'Custom Meal Macro Stacker'),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.tealAccent, size: 28),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GOAL TRAJECTORY (TARGET: ${goalWeight ?? 63.0} KG)', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          Text(diff > 0 ? '${diff.toStringAsFixed(1)} kg remaining to target' : 'Target reached!', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Text('7-DAY AVG ACTIVE', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildGridCard("WEIGHT", currentWeight, "GOAL: $goalWeight", Icons.monitor_weight, Colors.tealAccent, getChronologicalWeightSpots()),
                  _buildGridCard("WAISTLINE", currentWaist, "TREND: -0.5cm", Icons.straighten, Colors.pinkAccent, waistSpots),
                  _buildGridCard("CALORIES", currentCalories, "BUDGET: 2000", Icons.local_fire_department, Colors.deepOrangeAccent, calorieSpots),
                  _buildGridCard("PROTEIN", currentProtein, "TARGET: 150g", Icons.fitness_center, Colors.purpleAccent, proteinSpots),
                  _buildGridCard("FASTING", currentFasting, "16:8 PROTOCOL", Icons.timer, Colors.orangeAccent, fastingSpots),
                  _buildGridCard("STEPS", currentSteps, "GOAL: 20k", Icons.directions_run, Colors.blueAccent, stepSpots),
    
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickLogForm(context),
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }
}