import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin, support, coach }

extension UserRoleExtension on UserRole {
  String toShortString() => toString().split('.').last;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'support':
        return UserRole.support;
      case 'coach':
        return UserRole.coach;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String toNorwegianName() {
    switch (this) {
      case UserRole.admin:
        return 'Hovedadministrator';
      case UserRole.support:
        return 'Foresatt / NAV Støtte';
      case UserRole.coach:
        return 'Trener';
      case UserRole.user:
        return 'Ungdom';
    }
  }
}

class UserModel {
  final String uid;
  final String nickname;
  final UserRole role;
  final String clubId;
  final int levelXp;
  final int coins;
  final String activeAvatarLottie;
  final double avatarRotationY;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.clubId,
    required this.levelXp,
    required this.coins,
    required this.activeAvatarLottie,
    this.avatarRotationY = 0.0,
    required this.createdAt,
  });

  int get level => (levelXp ~/ 100) + 1;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nickname: map['nickname'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'user'),
      clubId: map['clubId'] ?? '',
      levelXp: (map['levelXp'] ?? 0) as int,
      coins: (map['coins'] ?? 0) as int,
      activeAvatarLottie: map['activeAvatarLottie'] ?? 'assets/lottie/avatar_runner.json',
      avatarRotationY: (map['avatarRotationY'] ?? 0.0) as double,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'role': role.toShortString(),
      'clubId': clubId,
      'levelXp': levelXp,
      'coins': coins,
      'activeAvatarLottie': activeAvatarLottie,
      'avatarRotationY': avatarRotationY,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get currentLevel => (levelXp / 100).floor() + 1;
  int get xpInCurrentLevel => levelXp % 100;

  UserModel copyWith({
    String? nickname,
    UserRole? role,
    String? clubId,
    int? levelXp,
    int? coins,
    String? activeAvatarLottie,
    double? avatarRotationY,
  }) {
    return UserModel(
      uid: uid,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      clubId: clubId ?? this.clubId,
      levelXp: levelXp ?? this.levelXp,
      coins: coins ?? this.coins,
      activeAvatarLottie: activeAvatarLottie ?? this.activeAvatarLottie,
      avatarRotationY: avatarRotationY ?? this.avatarRotationY,
      createdAt: createdAt,
    );
  }
}
