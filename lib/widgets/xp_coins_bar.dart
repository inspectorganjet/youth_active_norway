import 'package:flutter/material.dart';
import '../models/user_model.dart';

class XpCoinsBar extends StatelessWidget {
  final UserModel user;

  const XpCoinsBar({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int maxXpForLevel = user.currentLevel * 250;
    final int currentXp = user.levelXp;
    final double progress = (currentXp / maxXpForLevel).clamp(0.0, 1.0);

    return Column(
      children: [
        // Level title on left, XP & Gold balance on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: Text(
                    'Rang ${user.currentLevel}',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$currentXp / $maxXpForLevel XP',
                  style: const TextStyle(
                    color: Color(0xFF6B21A8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Text('💰 ', style: TextStyle(fontSize: 12)),
                      Text(
                        '${user.coins} Mynter',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Wider Purple Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 18,
                width: double.infinity,
                color: const Color(0xFFF3E8FF),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF8B5CF6),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
