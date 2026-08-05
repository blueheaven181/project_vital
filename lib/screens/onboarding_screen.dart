import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/vitals_repository.dart';
import '../theme/vital_palette.dart';
import '../utils/units.dart';
import '../widgets/glass.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController goalWeightController = TextEditingController();

  bool isHeightInFeet = true;
  String gender = 'Male';
  WeightUnit weightUnit = WeightUnit.kg;

  void _convertWeightFields(WeightUnit newUnit) {
    if (newUnit == weightUnit) return;
    final w = double.tryParse(weightController.text);
    final g = double.tryParse(goalWeightController.text);
    if (w != null) weightController.text = kgToDisplay(displayToKg(w, weightUnit), newUnit).toStringAsFixed(1);
    if (g != null) goalWeightController.text = kgToDisplay(displayToKg(g, weightUnit), newUnit).toStringAsFixed(1);
    weightUnit = newUnit;
  }

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
                      child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: VitalPalette.amber.withValues(alpha: 0.18))),
                    ),
                    Align(
                      alignment: const Alignment(0.9, 0.8),
                      child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: VitalPalette.violet.withValues(alpha: 0.16))),
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
                        decoration: InputDecoration(labelText: 'Age', hintText: 'e.g. 30', hintStyle: const TextStyle(color: Colors.white24), labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
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
                                final typed = double.tryParse(heightController.text);
                                isHeightInFeet = !isHeightInFeet;
                                if (typed != null) {
                                  // Convert the value the user already typed instead of
                                  // discarding it for a canned example number.
                                  final converted = isHeightInFeet ? typed / 30.48 : typed * 30.48;
                                  heightController.text = converted.toStringAsFixed(isHeightInFeet ? 2 : 0);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                              decoration: BoxDecoration(
                                color: VitalPalette.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: VitalPalette.amber.withValues(alpha: 0.3)),
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
                      child: InkWell(
                        onTap: () => setState(() => gender = 'Male'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: gender == 'Male' ? VitalPalette.amber.withValues(alpha: 0.15) : Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gender == 'Male' ? VitalPalette.amber : Colors.white24),
                          ),
                          child: Text('MALE', style: TextStyle(color: gender == 'Male' ? VitalPalette.amber : Colors.white54, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => gender = 'Female'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: gender == 'Female' ? VitalPalette.rose.withValues(alpha: 0.15) : Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gender == 'Female' ? VitalPalette.rose : Colors.white24),
                          ),
                          child: Text('FEMALE', style: TextStyle(color: gender == 'Female' ? VitalPalette.rose : Colors.white54, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _convertWeightFields(WeightUnit.kg)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: weightUnit == WeightUnit.kg ? VitalPalette.amber.withValues(alpha: 0.15) : Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: weightUnit == WeightUnit.kg ? VitalPalette.amber : Colors.white24),
                          ),
                          child: Text('KG', style: TextStyle(color: weightUnit == WeightUnit.kg ? VitalPalette.amber : Colors.white54, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _convertWeightFields(WeightUnit.lbs)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: weightUnit == WeightUnit.lbs ? VitalPalette.amber.withValues(alpha: 0.15) : Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: weightUnit == WeightUnit.lbs ? VitalPalette.amber : Colors.white24),
                          ),
                          child: Text('LBS', style: TextStyle(color: weightUnit == WeightUnit.lbs ? VitalPalette.amber : Colors.white54, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: 'Current Weight (${weightUnit.label})', hintText: weightUnit == WeightUnit.kg ? 'e.g. 70' : 'e.g. 154', hintStyle: const TextStyle(color: Colors.white24), labelStyle: const TextStyle(color: VitalPalette.amber), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: goalWeightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Goal Weight (${weightUnit.label})',
                                hintText: weightUnit == WeightUnit.kg ? 'e.g. 63' : 'e.g. 139',
                                hintStyle: const TextStyle(color: Colors.white24),
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
                              backgroundColor: VitalPalette.rose.withValues(alpha: 0.2),
                              foregroundColor: VitalPalette.rose,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              double heightCm = double.tryParse(heightController.text) ?? 165.0;
                              if (isHeightInFeet) heightCm = heightCm * 30.48;
                              final suggestedWeightKg = 22 * ((heightCm / 100.0) * (heightCm / 100.0));
                              final suggestedDisplay = kgToDisplay(suggestedWeightKg, weightUnit);
                              goalWeightController.text = suggestedDisplay.toStringAsFixed(1);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Auto-suggested ideal weight set to ${suggestedDisplay.toStringAsFixed(1)} ${weightUnit.label}!')),
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
                      final repo = VitalsRepository();
                      repo.vitalsBox.put('user_name', nameController.text.trim());
                      repo.vitalsBox.put('user_age', int.tryParse(ageController.text) ?? 30);
                      repo.vitalsBox.put('user_height', heightController.text.trim());
                      repo.vitalsBox.put('user_gender', gender);
                      repo.setWeightUnit(weightUnit);

                      final currentW = displayToKg(double.tryParse(weightController.text) ?? kgToDisplay(72.0, weightUnit), weightUnit);
                      final goalW = displayToKg(double.tryParse(goalWeightController.text) ?? kgToDisplay(63.0, weightUnit), weightUnit);

                      repo.vitalsBox.put('user_goal_weight', goalW);
                      repo.vitalsBox.put('profile_setup_complete', true);

                      final todayKey = DateTime.now().toIso8601String().split('T')[0];
                      if (repo.historyBox.get(todayKey) is! Map) {
                        repo.historyBox.put(todayKey, {'weight': currentW});
                      }

                      repo.seedDefaultPresetsIfEmpty();

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
