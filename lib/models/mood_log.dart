import 'package:cloud_firestore/cloud_firestore.dart';

class MoodLog {
  final String id;
  final DateTime timestamp;
  final String timeOfDay; // "Morgen", "Ettermiddag", "Kveld"
  final String moodEmoji;
  final String userNote;

  MoodLog({
    required this.id,
    required this.timestamp,
    required this.timeOfDay,
    required this.moodEmoji,
    required this.userNote,
  });

  factory MoodLog.fromMap(Map<String, dynamic> map, String id) {
    return MoodLog(
      id: id,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeOfDay: map['timeOfDay'] ?? 'Morgen',
      moodEmoji: map['moodEmoji'] ?? '😊',
      userNote: map['userNote'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'timeOfDay': timeOfDay,
      'moodEmoji': moodEmoji,
      'userNote': userNote,
    };
  }
}
