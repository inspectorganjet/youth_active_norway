import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final String taskType; // "pushups", "squats", "situps", "reading", "custom"
  final int targetGoal;
  final bool completed;
  final String createdByRole; // "admin", "support", "coach"
  final String? completionMoodEmoji;
  final String? completionComment;

  final int goldReward;
  final DateTime? createdAt;
  final String? workoutMode; // e.g. "Pose AI", "GPS Tracking", "Manual"

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.taskType,
    required this.targetGoal,
    required this.completed,
    required this.createdByRole,
    this.goldReward = 200,
    this.createdAt,
    this.workoutMode,
    this.completionMoodEmoji,
    this.completionComment,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taskType: map['taskType'] ?? 'custom',
      targetGoal: (map['targetGoal'] ?? 0) as int,
      completed: map['completed'] ?? false,
      createdByRole: map['createdByRole'] ?? 'coach',
      goldReward: map['goldReward'] ?? 200,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      workoutMode: map['workoutMode'],
      completionMoodEmoji: map['completionMoodEmoji'],
      completionComment: map['completionComment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'taskType': taskType,
      'targetGoal': targetGoal,
      'completed': completed,
      'createdByRole': createdByRole,
      'goldReward': goldReward,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'workoutMode': workoutMode,
      'completionMoodEmoji': completionMoodEmoji,
      'completionComment': completionComment,
    };
  }
}
