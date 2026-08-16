import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/pdf_report_service.dart';
import '../../services/firebase_service.dart';

class PdfExportScreen extends StatelessWidget {
  const PdfExportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;
    final activities = firebaseService.getActivities();
    final tasks = firebaseService.getTasks();
    final moodLogs = firebaseService.getMoodLogs();
    final chatSafetyStats = firebaseService.getChatSafetyStatistics();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PDF Rapport')),
        body: const Center(child: Text('Ingen bruker funnet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAV / Admin PDF Rapport 📄'),
      ),
      body: PdfPreview(
        build: (format) => PdfReportService.generateYouthReportPdf(
          user: user,
          activities: activities,
          tasks: tasks,
          moodLogs: moodLogs,
          chatSafetyStats: chatSafetyStats,
        ),
        pdfFileName: 'ungdoms_aktivitet_rapport_${user.nickname}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
