import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/mood_log.dart';

class MoodPopupDialog extends StatefulWidget {
  final String timeOfDay;
  final VoidCallback onSaved;

  const MoodPopupDialog({
    Key? key,
    required this.timeOfDay,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<MoodPopupDialog> createState() => _MoodPopupDialogState();
}

class _MoodPopupDialogState extends State<MoodPopupDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedEmoji = '😊';
  final TextEditingController _noteController = TextEditingController();

  final List<String> _emojis = ['😊', '😍', '😴', '😔', '😡'];

  void _saveMood() async {
    final log = MoodLog(
      id: 'mood_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      timeOfDay: widget.timeOfDay,
      moodEmoji: _selectedEmoji,
      userNote: _noteController.text.trim(),
    );

    await _firebaseService.addMoodLog(log);
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppTheme.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.purpleXP.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('🎭', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hvordan har du det? 🇳🇴',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.timeOfDay} sjekk-inn for din dagsform',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Emoji selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _emojis.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.purpleXP.withOpacity(0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppTheme.purpleXP, width: 2) : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Skriv et par ord (valgfritt)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0446BC),
                  textStyle: const TextStyle(fontWeight: FontWeight.w500),
                ),
                child: const Text('Lagre Stemning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
