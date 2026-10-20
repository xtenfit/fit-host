import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../core/database/database.dart';
import '../../profile/domain/models/user_profile.dart';

class HealthExportService {
  final AppDatabase db;

  const HealthExportService(this.db);

  /// Generates a structured multi-page PDF Health & Fitness Audit
  Future<File> generatePdfAudit({required UserProfile profile}) async {
    final pdf = pw.Document();

    final workouts = await (db.select(db.workouts)
          ..orderBy([(w) => drift.OrderingTerm.desc(w.startedAt)]))
        .get();

    final stepLogs = await (db.select(db.stepDailyLogs)
          ..orderBy([(s) => drift.OrderingTerm.desc(s.stepDate)]))
        .get();

    final diaryEntries = await (db.select(db.dailyDiaryEntries)
          ..orderBy([(d) => drift.OrderingTerm.desc(d.entryDate)]))
        .get();

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(dateStr),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Audit Title Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OFFICIAL HEALTH & FITNESS AUDIT REPORT',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'User Biometrics & Verified Activity Telemetry',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'App v1.2.2v2',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Biometrics Section
          pw.Text('1. User Biometric Profile', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfTableCell('Metric', isHeader: true),
                  _pdfTableCell('Value', isHeader: true),
                  _pdfTableCell('Standard Target', isHeader: true),
                ],
              ),
              pw.TableRow(children: [
                _pdfTableCell('Height / Stature'),
                _pdfTableCell('${profile.heightCm.toStringAsFixed(1)} cm'),
                _pdfTableCell('N/A'),
              ]),
              pw.TableRow(children: [
                _pdfTableCell('Body Weight'),
                _pdfTableCell('${profile.weightKg.toStringAsFixed(1)} kg'),
                _pdfTableCell(profile.targetWeightKg != null ? '${profile.targetWeightKg!.toStringAsFixed(1)} kg' : 'Maintenance'),
              ]),
              pw.TableRow(children: [
                _pdfTableCell('Dietary Preference'),
                _pdfTableCell(profile.dietType.toUpperCase()),
                _pdfTableCell('Active Protocol'),
              ]),
              pw.TableRow(children: [
                _pdfTableCell('Daily Caloric Target'),
                _pdfTableCell('${profile.dailyCaloriesTarget} kcal'),
                _pdfTableCell('TDEE: ${profile.tdeeCalculated.round()} kcal'),
              ]),
              pw.TableRow(children: [
                _pdfTableCell('Macro Ratio (P / C / F)'),
                _pdfTableCell('${profile.targetProteinGrams}g / ${profile.targetCarbsGrams}g / ${profile.targetFatsGrams}g'),
                _pdfTableCell('${profile.proteinCaloriesPercent}% / ${profile.carbsCaloriesPercent}% / ${profile.fatsCaloriesPercent}%'),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),

          // Workouts Section
          pw.Text('2. Recorded Workout Sessions (${workouts.length} total)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (workouts.isEmpty)
            pw.Text('No workouts logged yet.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTableCell('Title', isHeader: true),
                    _pdfTableCell('Date', isHeader: true),
                    _pdfTableCell('Duration', isHeader: true),
                    _pdfTableCell('Status', isHeader: true),
                  ],
                ),
                ...workouts.take(15).map((w) {
                  final durationMin = (w.durationSeconds / 60).round();
                  final wDate = '${w.startedAt.year}-${w.startedAt.month.toString().padLeft(2, '0')}-${w.startedAt.day.toString().padLeft(2, '0')}';
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(w.title),
                      _pdfTableCell(wDate),
                      _pdfTableCell('$durationMin mins'),
                      _pdfTableCell(w.status.toUpperCase()),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // Pedometer / Steps Section
          pw.Text('3. Daily Pedometer & Activity Logs (${stepLogs.length} entries)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (stepLogs.isEmpty)
            pw.Text('No step logs recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTableCell('Date', isHeader: true),
                    _pdfTableCell('Steps', isHeader: true),
                    _pdfTableCell('Distance', isHeader: true),
                    _pdfTableCell('Active Burn', isHeader: true),
                  ],
                ),
                ...stepLogs.take(10).map((s) {
                  final sDate = '${s.stepDate.year}-${s.stepDate.month.toString().padLeft(2, '0')}-${s.stepDate.day.toString().padLeft(2, '0')}';
                  final distKm = (s.distanceMeters / 1000).toStringAsFixed(2);
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(sDate),
                      _pdfTableCell('${s.steps} steps'),
                      _pdfTableCell('$distKm km'),
                      _pdfTableCell('${s.activeCalories} kcal'),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // Work & Life Diary Section
          pw.Text('4. Daily Work & Life Diary (${diaryEntries.length} entries)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (diaryEntries.isEmpty)
            pw.Text('No diary logs recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.Column(
              children: diaryEntries.take(5).map((d) {
                final dDate = '${d.entryDate.year}-${d.entryDate.month.toString().padLeft(2, '0')}-${d.entryDate.day.toString().padLeft(2, '0')}';
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${d.title} [${d.category.toUpperCase()}]', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text('$dDate • Mood: ${d.mood}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        d.content.length > 200 ? '${d.content.substring(0, 200)}...' : d.content,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Fit_Host_Health_Audit_$dateStr.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generates a multi-sheet Excel Workbook (.xlsx)
  Future<File> generateExcelArchive({required UserProfile profile}) async {
    final excel = Excel.createExcel();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Profile Sheet
    final profileSheet = excel['User Profile'];
    profileSheet.appendRow([
      TextCellValue('Fit Host Health Vault Profile'),
      TextCellValue('Exported Date: $dateStr'),
      TextCellValue('Version: 1.2.2v2'),
    ]);
    profileSheet.appendRow([TextCellValue('')]);
    profileSheet.appendRow([TextCellValue('Biometric Metric'), TextCellValue('Current Value')]);
    profileSheet.appendRow([TextCellValue('User Name / ID'), TextCellValue(profile.name)]);
    profileSheet.appendRow([TextCellValue('Height (cm)'), DoubleCellValue(profile.heightCm)]);
    profileSheet.appendRow([TextCellValue('Weight (kg)'), DoubleCellValue(profile.weightKg)]);
    profileSheet.appendRow([TextCellValue('Target Weight (kg)'), DoubleCellValue(profile.targetWeightKg ?? profile.weightKg)]);
    profileSheet.appendRow([TextCellValue('Diet Preference'), TextCellValue(profile.dietType)]);
    profileSheet.appendRow([TextCellValue('Daily Target Calories'), IntCellValue(profile.dailyCaloriesTarget)]);
    profileSheet.appendRow([TextCellValue('Target Protein (g)'), IntCellValue(profile.targetProteinGrams)]);
    profileSheet.appendRow([TextCellValue('Target Carbs (g)'), IntCellValue(profile.targetCarbsGrams)]);
    profileSheet.appendRow([TextCellValue('Target Fats (g)'), IntCellValue(profile.targetFatsGrams)]);

    // 2. Workouts Sheet
    final workouts = await db.select(db.workouts).get();
    final workoutSheet = excel['Workouts'];
    workoutSheet.appendRow([
      TextCellValue('Workout ID'),
      TextCellValue('Title'),
      TextCellValue('Status'),
      TextCellValue('Started At'),
      TextCellValue('Completed At'),
      TextCellValue('Duration (seconds)'),
      TextCellValue('Duration (minutes)'),
      TextCellValue('Estimated Calories'),
      TextCellValue('Notes'),
    ]);

    for (final w in workouts) {
      workoutSheet.appendRow([
        TextCellValue(w.id),
        TextCellValue(w.title),
        TextCellValue(w.status),
        TextCellValue(w.startedAt.toIso8601String()),
        TextCellValue(w.completedAt?.toIso8601String() ?? ''),
        IntCellValue(w.durationSeconds),
        DoubleCellValue(w.durationSeconds / 60.0),
        IntCellValue(w.caloriesBurned ?? 0),
        TextCellValue(w.note ?? ''),
      ]);
    }

    // 3. Exercise Sets Sheet
    final sets = await db.select(db.workoutSets).get();
    final setsSheet = excel['Exercise Sets'];
    setsSheet.appendRow([
      TextCellValue('Set ID'),
      TextCellValue('Workout Exercise ID'),
      TextCellValue('Set Number'),
      TextCellValue('Reps'),
      TextCellValue('Weight (kg)'),
      TextCellValue('Completed'),
      TextCellValue('Set Type'),
    ]);

    for (final s in sets) {
      setsSheet.appendRow([
        TextCellValue(s.id),
        TextCellValue(s.workoutExerciseId),
        IntCellValue(s.setNumber),
        IntCellValue(s.reps),
        DoubleCellValue(s.weightKg),
        TextCellValue(s.isCompleted ? 'TRUE' : 'FALSE'),
        TextCellValue(s.setType),
      ]);
    }

    // 4. Steps & Activity Sheet
    final steps = await db.select(db.stepDailyLogs).get();
    final stepSheet = excel['Steps & Activity'];
    stepSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Steps Count'),
      TextCellValue('Target Steps'),
      TextCellValue('Distance (meters)'),
      TextCellValue('Distance (km)'),
      TextCellValue('Active Calories (kcal)'),
    ]);

    for (final s in steps) {
      stepSheet.appendRow([
        TextCellValue('${s.stepDate.year}-${s.stepDate.month}-${s.stepDate.day}'),
        IntCellValue(s.steps),
        IntCellValue(s.targetSteps),
        DoubleCellValue(s.distanceMeters),
        DoubleCellValue(s.distanceMeters / 1000.0),
        IntCellValue(s.activeCalories),
      ]);
    }

    // 5. Daily Work & Life Diary Sheet
    final diaries = await db.select(db.dailyDiaryEntries).get();
    final diarySheet = excel['Daily Life Diary'];
    diarySheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Title'),
      TextCellValue('Mood'),
      TextCellValue('Content'),
      TextCellValue('Voice Memo Duration (sec)'),
    ]);

    for (final d in diaries) {
      diarySheet.appendRow([
        TextCellValue('${d.entryDate.year}-${d.entryDate.month}-${d.entryDate.day}'),
        TextCellValue(d.category),
        TextCellValue(d.title),
        TextCellValue(d.mood),
        TextCellValue(d.content),
        IntCellValue(d.voiceMemoDurationSeconds ?? 0),
      ]);
    }

    // Remove default Sheet1 if unused
    if (excel.sheets.containsKey('Sheet1') && excel.sheets.keys.length > 1) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode()!;
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Fit_Host_Fitness_Backup_$dateStr.xlsx');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Exports raw JSON format
  Future<File> generateJsonArchive() async {
    final exercises = await db.select(db.exercises).get();
    final workouts = await db.select(db.workouts).get();
    final workoutSets = await db.select(db.workoutSets).get();
    final stepLogs = await db.select(db.stepDailyLogs).get();
    final diaryEntries = await db.select(db.dailyDiaryEntries).get();
    final reminders = await db.select(db.reminders).get();
    final calendarEvents = await db.select(db.calendarEvents).get();

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final exportPayload = {
      'app': 'Fit Host',
      'version': '1.2.2v2',
      'poweredBy': 'amitrana',
      'managedBy': 'amitrana team',
      'support': 'support@amitrana.tech',
      'copyright': '© 2026 amitrana. All rights reserved.',
      'exportDate': now.toIso8601String(),
      'summary': {
        'exercisesCount': exercises.length,
        'workoutsCount': workouts.length,
        'setsCount': workoutSets.length,
        'stepLogsCount': stepLogs.length,
        'diaryEntriesCount': diaryEntries.length,
        'remindersCount': reminders.length,
        'calendarEventsCount': calendarEvents.length,
      },
      'data': {
        'workouts': workouts.map((w) => {
          'id': w.id,
          'title': w.title,
          'startedAt': w.startedAt.toIso8601String(),
          'completedAt': w.completedAt?.toIso8601String(),
          'status': w.status,
          'durationSeconds': w.durationSeconds,
          'caloriesBurned': w.caloriesBurned,
        }).toList(),
        'steps': stepLogs.map((s) => {
          'date': s.stepDate.toIso8601String(),
          'steps': s.steps,
          'distanceMeters': s.distanceMeters,
          'activeCalories': s.activeCalories,
        }).toList(),
        'diary': diaryEntries.map((d) => {
          'id': d.id,
          'date': d.entryDate.toIso8601String(),
          'title': d.title,
          'category': d.category,
          'mood': d.mood,
          'content': d.content,
        }).toList(),
        'reminders': reminders.map((r) => {
          'id': r.id,
          'title': r.title,
          'category': r.category,
          'timeOfDay': r.timeOfDay,
          'isEnabled': r.isEnabled,
        }).toList(),
      },
    };

    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert(exportPayload);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Fit_Host_Full_Vault_$dateStr.json');
    await file.writeAsString(jsonStr);
    return file;
  }

  /// Triggers standard system share dialog
  static Future<void> shareFile(File file, {required String subject}) async {
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: 'Fit Host Data Vault Backup (v1.2.2v2)',
    );
  }

  // --- PDF Helper Widgets ---
  pw.Widget _buildPdfHeader(String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('FIT HOST — PRODUCTION HEALTH AUDIT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.Text('Report Date: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('© 2026 amitrana. All rights reserved. | Powered by amitrana', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
      ),
    );
  }
}
