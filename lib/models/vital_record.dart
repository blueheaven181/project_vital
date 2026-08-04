import 'package:isar/isar.dart';

// This specific line tells Isar to write the complex database code for us
part 'vital_record.g.dart';

@collection
class VitalRecord {
  Id id = Isar.autoIncrement; // The unique database ID

  // This ensures we only have one entry per day. If you log twice, it overwrites the first.
  @Index(unique: true, replace: true) 
  late DateTime date;

  // The actual metrics. The "?" means they are optional, so if you 
  // only log weight one day and skip steps, the database won't crash.
  double? weight;
  double? waistline;
  int? calories;
  int? protein;
  double? fastingHours;
  int? steps;
}