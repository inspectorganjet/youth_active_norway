import 'package:cloud_firestore/cloud_firestore.dart';

class CoachComment {
  final String coachUid;
  final String coachName;
  final String commentText;
  final DateTime timestamp;
  final String? userReactionEmoji;

  CoachComment({
    required this.coachUid,
    required this.coachName,
    required this.commentText,
    required this.timestamp,
    this.userReactionEmoji,
  });

  factory CoachComment.fromMap(Map<String, dynamic> map) {
    return CoachComment(
      coachUid: map['coachUid'] ?? '',
      coachName: map['coachName'] ?? '',
      commentText: map['commentText'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userReactionEmoji: map['userReactionEmoji'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coachUid': coachUid,
      'coachName': coachName,
      'commentText': commentText,
      'timestamp': Timestamp.fromDate(timestamp),
      'userReactionEmoji': userReactionEmoji,
    };
  }
}

class ActivityModel {
  final String id;
  final DateTime timestamp;
  final String type; // "pushups", "squats", "situps", "reading", "food", "cardio_running", "cardio_cycling"
  final int reps;
  final double distanceKm;
  final int durationSeconds;
  final int coinsEarned;
  final int xpEarned; // 100 Gold = 10 XP
  final String moodEmoji;
  final String userComment;
  final String aiReport;
  final List<CoachComment> coachComments;
  final Map<String, dynamic>? detailedInfo; // Anti-Cheat audit breakdown, reps, technique score

  ActivityModel({
    required this.id,
    required this.timestamp,
    required this.type,
    this.reps = 0,
    this.distanceKm = 0.0,
    required this.durationSeconds,
    required this.coinsEarned,
    int? xpEarned,
    required this.moodEmoji,
    required this.userComment,
    required this.aiReport,
    required this.coachComments,
    this.detailedInfo,
  }) : xpEarned = xpEarned ?? (coinsEarned * 0.1).round();

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    var rawComments = map['coachComments'] as List<dynamic>? ?? [];
    List<CoachComment> comments = rawComments
        .map((c) => CoachComment.fromMap(c as Map<String, dynamic>))
        .toList();

    int coins = (map['coinsEarned'] ?? 0) as int;
    int xp = (map['xpEarned'] ?? (coins * 0.1).round()) as int;

    return ActivityModel(
      id: id,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'custom',
      reps: (map['reps'] ?? 0) as int,
      distanceKm: (map['distanceKm'] ?? 0.0) as double,
      durationSeconds: (map['durationSeconds'] ?? 0) as int,
      coinsEarned: coins,
      xpEarned: xp,
      moodEmoji: map['moodEmoji'] ?? '😊',
      userComment: map['userComment'] ?? '',
      aiReport: map['aiReport'] ?? '',
      coachComments: comments,
      detailedInfo: map['detailedInfo'] != null ? Map<String, dynamic>.from(map['detailedInfo']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'reps': reps,
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'coinsEarned': coinsEarned,
      'xpEarned': xpEarned,
      'moodEmoji': moodEmoji,
      'userComment': userComment,
      'aiReport': aiReport,
      'coachComments': coachComments.map((c) => c.toMap()).toList(),
      'detailedInfo': detailedInfo,
    };
  }

  String get NorwegianTypeTitle {
    switch (type) {
      case 'pushups':
        return 'Armhevinger';
      case 'squats':
        return 'Knebøy';
      case 'situps':
        return 'Mageøvelser';
      case 'reading':
        return 'Digital Lesing';
      case 'food':
        return 'Ernæringsanalyse (Food AI)';
      case 'cardio_running':
        return 'Løping';
      case 'cardio_cycling':
        return 'Sykling';
      case 'cardio':
        return 'Kardiotrening';
      case 'shadow_boxing':
        return 'Skyggekamp 🥊';
      case 'meditation':
      case 'wim_hof_breathing':
        return 'Wim Hof Meditasjon';
      default:
        return 'Aktivitet';
    }
  }

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
