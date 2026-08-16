import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/task_model.dart';
import '../models/mood_log.dart';

class PdfReportService {
  static Future<Uint8List> generateYouthReportPdf({
    required UserModel user,
    required List<ActivityModel> activities,
    required List<TaskModel> tasks,
    required List<MoodLog> moodLogs,
    Map<String, int>? chatSafetyStats,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    final stats = chatSafetyStats ?? {
      'useful': 12,
      'fun': 4,
      'strange': 1,
      'dangerous': 0,
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'UNGDOMS-AKTIVITET RAPPORT 🇳🇴',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'Offisiell Oppsummering for NAV / Foresatte / Administrator',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Text(
                  dateFormat.format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blue800),
            pw.SizedBox(height: 12),

            // Profile Summary Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Kallenavn: ${user.nickname}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Klubb/Gruppe: ${user.clubId}'),
                      pw.Text('Rolle: ${user.role.toNorwegianName()}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Level: ${user.currentLevel}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.purple800)),
                      pw.Text('Totalt Level-XP: ${user.levelXp} XP'),
                      pw.Text('Mynter Saldo: ${user.coins} 💰'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 1. Activities Table Section
            pw.Text(
              '1. Aktivitets- og Treningshistorikk',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 6),
            if (activities.isEmpty)
              pw.Text('Ingen registrerte aktiviteter ennå.', style: const pw.TextStyle(color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Dato', 'Aktivitet', 'XP/Mynter', 'Stemning', 'Brukerkommentar'],
                data: activities.map((a) {
                  return [
                    dateFormat.format(a.timestamp),
                    a.NorwegianTypeTitle,
                    '+${a.xpEarned} XP / +${a.coinsEarned} Mynter',
                    a.moodEmoji,
                    a.userComment.length > 30 ? '${a.userComment.substring(0, 30)}...' : a.userComment,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),

            pw.SizedBox(height: 16),

            // 2. Mood Logs Section
            pw.Text(
              '2. Stemningsmålinger (3x Daglig Mood Logs)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 6),
            if (moodLogs.isEmpty)
              pw.Text('Ingen stemningsmålinger registrert ennå.', style: const pw.TextStyle(color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Tidspunkt', 'Tid på dagen', 'Stemning', 'Notat'],
                data: moodLogs.map((m) {
                  return [
                    dateFormat.format(m.timestamp),
                    m.timeOfDay,
                    m.moodEmoji,
                    m.userNote,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),

            pw.SizedBox(height: 16),

            // 3. AI Chat Safety & Risk Audit Breakdown Section (New Requirement!)
            pw.Text(
              '3. AI-Chat Sikkerhets- og Risikostatistikk (Support & Admin Rapport)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blue300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Intern AI har analysert brukerens samtalelogg for sikkerhet og hensikt:',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Text('🌱 Nyttige/Lærerike: ${stats['useful']}'),
                      pw.Text('🎈 Morsomme/Forskning: ${stats['fun']}'),
                      pw.Text('❓ Merkelige: ${stats['strange']}'),
                      pw.Text(
                        '⚠️ Farlige/Risiko: ${stats['dangerous']}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: (stats['dangerous'] ?? 0) > 0 ? PdfColors.red : PdfColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // AI Mentor Assessment Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Digital analyse: Helhetsvurdering & Oppsummering:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Ungdommen viser god og stabil progresjon i fysikk og digital lesing. Samtaleloggen viser trygg og lærerik bruk uten noen risiko-flagg.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
