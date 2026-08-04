// A single day's logged metrics, parsed from the raw Map stored in
// history_box. Accepts a handful of legacy/short key aliases so old
// imported or hand-edited data keeps working.
class VitalsEntry {
  final double? weight;
  final double? waist;
  final int? calories;
  final int? protein;
  final double? fasting;
  final int? steps;
  final int? systolic;
  final int? diastolic;

  const VitalsEntry({this.weight, this.waist, this.calories, this.protein, this.fasting, this.steps, this.systolic, this.diastolic});

  factory VitalsEntry.fromMap(Map raw) {
    double? asDouble(dynamic v) => v == null ? null : (double.tryParse(v.toString()) ?? (v is num ? v.toDouble() : null));
    int? asInt(dynamic v) => v == null ? null : (int.tryParse(v.toString()) ?? (v is num ? v.toInt() : null));

    return VitalsEntry(
      weight: asDouble(raw['weight'] ?? raw['w'] ?? raw['W']),
      waist: asDouble(raw['waist'] ?? raw['waistline'] ?? raw['W_cm']),
      calories: asInt(raw['calories'] ?? raw['cal'] ?? raw['c'] ?? raw['C']),
      protein: asInt(raw['protein'] ?? raw['pro'] ?? raw['p'] ?? raw['P']),
      fasting: asDouble(raw['fasting'] ?? raw['fast']),
      steps: asInt(raw['steps']),
      systolic: asInt(raw['systolic'] ?? raw['sys']),
      diastolic: asInt(raw['diastolic'] ?? raw['dia']),
    );
  }
}
