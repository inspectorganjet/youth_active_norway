import 'package:flutter/material.dart';

class AvatarItem {
  final String id;
  final String name;
  final String lottiePath;
  final String rarity; // "alminnelig" (common), "sjelden" (rare), "legendarisk" (legendary)
  final int priceCoins;
  final bool isOwned;

  AvatarItem({
    required this.id,
    required this.name,
    required this.lottiePath,
    required this.rarity,
    required this.priceCoins,
    this.isOwned = false,
  });

  factory AvatarItem.fromMap(Map<String, dynamic> map, String id, {bool isOwned = false}) {
    return AvatarItem(
      id: id,
      name: map['name'] ?? 'Avatar',
      lottiePath: map['lottiePath'] ?? 'assets/lottie/avatar_runner.json',
      rarity: map['rarity'] ?? 'alminnelig',
      priceCoins: (map['priceCoins'] ?? 0) as int,
      isOwned: isOwned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lottiePath': lottiePath,
      'rarity': rarity,
      'priceCoins': priceCoins,
    };
  }

  Color get rarityColor {
    switch (rarity.toLowerCase()) {
      case 'legendarisk':
      case 'legendary':
        return const Color(0xFFF59E0B); // Amber / Gold
      case 'sjelden':
      case 'rare':
        return const Color(0xFF8B5CF6); // Purple
      case 'alminnelig':
      case 'common':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String get avatarEmoji {
    if (id.contains('dragon') || name.contains('Dragen')) return '🐲';
    if (id.contains('hero') || name.contains('Silje')) return '⚡';
    if (id.contains('ninja') || name.contains('Ninja')) return '🥷';
    if (id.contains('runner') || name.contains('Lars')) return '🏃';
    if (id.contains('digital_boxer') || name.contains('boksere')) return '🥊';
    return '👤';
  }

  String get rarityNorwegian {
    switch (rarity.toLowerCase()) {
      case 'legendarisk':
      case 'legendary':
        return 'Legendarisk ✨';
      case 'sjelden':
      case 'rare':
        return 'Sjelden 💜';
      case 'alminnelig':
      case 'common':
      default:
        return 'Alminnelig 💙';
    }
  }
}
