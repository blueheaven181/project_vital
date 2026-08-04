import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/vital_palette.dart';

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
