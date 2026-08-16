import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyOverlay extends StatelessWidget {
  final VoidCallback onAccept;

  const PrivacyOverlay({Key? key, required this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppTheme.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '100% Kamera Personvern 🚫🎥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'For å gi deg sanntids poeng for armhevinger, knebøy og sit-ups bruker appen Google ML Kit Pose Detection direkte på enheten din.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_rounded, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ingen video- eller bildeopptak lagres eller sendes eksternt. Alt prosesseres 100% lokalt på telefonen din!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Jeg forstår og godtar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
