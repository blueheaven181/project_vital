// Weight is always stored internally in kg (history_box, goal weight, BMI
// math). This file is the single place that converts to/from a display unit.
enum WeightUnit { kg, lbs }

extension WeightUnitLabel on WeightUnit {
  String get label => this == WeightUnit.kg ? 'kg' : 'lbs';
}

WeightUnit weightUnitFromStored(String? raw) => raw == 'lbs' ? WeightUnit.lbs : WeightUnit.kg;

double kgToLbs(double kg) => kg * 2.20462;
double lbsToKg(double lbs) => lbs / 2.20462;

double kgToDisplay(double kg, WeightUnit unit) => unit == WeightUnit.kg ? kg : kgToLbs(kg);
double displayToKg(double value, WeightUnit unit) => unit == WeightUnit.kg ? value : lbsToKg(value);

// user_height is stored as a raw string that's either decimal feet (e.g.
// "5.45") or centimeters (e.g. "164"), with no persisted flag for which —
// the two ranges don't overlap for realistic adult heights, so a threshold
// is enough to tell them apart. Mirrors the feet->cm formula the onboarding
// screen already uses for its ideal-weight suggestion.
double parseHeightCm(String raw) {
  final val = double.tryParse(raw.trim());
  if (val == null) return 165.0;
  return val < 12 ? val * 30.48 : val;
}

class BmiResult {
  final double bmi;
  final String label;
  const BmiResult(this.bmi, this.label);
}

BmiResult classifyBmi(double weightKg, double heightCm) {
  final heightM = heightCm / 100.0;
  final bmi = weightKg / (heightM * heightM);
  String label;
  if (bmi < 18.5) {
    label = 'Underweight';
  } else if (bmi < 25) {
    label = 'Normal';
  } else if (bmi < 30) {
    label = 'Overweight';
  } else {
    label = 'Obese';
  }
  return BmiResult(bmi, label);
}
