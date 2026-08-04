import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'vitals_repository.dart';
import '../utils/units.dart';

// Builds a clinical-style PDF: patient info header plus a 30-day
// weight/blood-pressure table, for sharing with a doctor or keeping as a
// paper record. Weight is shown in the user's current display unit.
Future<Uint8List> buildClinicalReportPdf(VitalsRepository repo) async {
  final unit = repo.weightUnit;
  final name = repo.vitalsBox.get('user_name', defaultValue: 'Athlete') as String;
  final age = repo.vitalsBox.get('user_age', defaultValue: 0);
  final gender = repo.vitalsBox.get('user_gender', defaultValue: 'Male') as String;
  final heightCm = parseHeightCm(repo.vitalsBox.get('user_height', defaultValue: '5.45') as String);
  final goalKg = (repo.vitalsBox.get('user_goal_weight', defaultValue: 63.0) as num).toDouble();

  final dateKeys = repo.sortedDateKeys;
  final last30 = dateKeys.length > 30 ? dateKeys.sublist(dateKeys.length - 30) : dateKeys;

  final tableRows = last30.reversed.map((dateKey) {
    final entry = repo.entryForDate(dateKey);
    final weightStr = entry?.weight != null ? kgToDisplay(entry!.weight!, unit).toStringAsFixed(1) : '-';
    final waistStr = entry?.waist != null ? entry!.waist!.toStringAsFixed(1) : '-';
    final bpStr = (entry?.systolic != null && entry?.diastolic != null) ? '${entry?.systolic}/${entry?.diastolic}' : '-';
    final classificationStr = entry?.weight != null ? classifyBmi(entry!.weight!, heightCm).label : '-';
    return [dateKey, weightStr, waistStr, bpStr, classificationStr];
  }).toList();

  final latestKg = last30.isNotEmpty ? repo.entryForDate(last30.last)?.weight : null;
  final bmiInfo = latestKg != null ? classifyBmi(latestKg, heightCm) : null;

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PROJECT VITAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
          pw.Text('Weight Tracker Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${DateTime.now().toIso8601String().split('T')[0]}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Divider(),
        ],
      ),
      build: (context) => [
        pw.SizedBox(height: 8),
        pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(1)},
          children: [
            _infoRow('Name', name),
            _infoRow('Age', '$age'),
            _infoRow('Gender', gender),
            _infoRow('Height', '${heightCm.toStringAsFixed(1)} cm'),
            _infoRow('Goal Weight', '${kgToDisplay(goalKg, unit).toStringAsFixed(1)} ${unit.label}'),
            if (bmiInfo != null) _infoRow('Current BMI', '${bmiInfo.bmi.toStringAsFixed(1)} (${bmiInfo.label})'),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text('WEIGHT, WAISTLINE & BLOOD PRESSURE — LAST ${last30.length} DAY(S)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (tableRows.isEmpty)
          pw.Text('No logged data yet.', style: const pw.TextStyle(color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Weight (${unit.label})', 'Waist (cm)', 'Blood Pressure (mmHg)', 'Classification'],
            data: tableRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.Text(
          'Disclaimer: Project Vital is a personal tracking tool, not created by medical professionals. This report is not medical advice or a diagnosis. Consult a qualified healthcare provider about your health.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.TableRow _infoRow(String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ),
    ],
  );
}
