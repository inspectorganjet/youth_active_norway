import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'cyber_boxer_widget.dart';
import 'holographic_card.dart';
import 'neon_human_3d_widget.dart';

/// Universal Avatar Widget that supports custom Flutter interactive widgets
/// (Holographic Card, Cyber Boxer, Neon Human 3D) as well as standard Lottie animations.
class UniversalAvatarWidget extends StatelessWidget {
  final String avatarPath;
  final double size;
  final int level;

  const UniversalAvatarWidget({
    super.key,
    required this.avatarPath,
    this.size = 200,
    this.level = 50,
  });

  bool get isCyberBoxer =>
      avatarPath == 'custom_avatar_digital_boxer' ||
      avatarPath.contains('digital_boxer') ||
      avatarPath.contains('cyber_boxer') ||
      avatarPath.contains('boxing_2');

  bool get isHolographicCard =>
      avatarPath == 'custom_avatar_holographic_card' ||
      avatarPath.contains('holographic_card') ||
      avatarPath.contains('holo_card');

  bool get isNeonHuman3D =>
      avatarPath == 'custom_avatar_neon_human_3d' ||
      avatarPath.contains('neon_human_3d');

  @override
  Widget build(BuildContext context) {
    if (isHolographicCard) {
      // Scale height proportionally for aspect ratio (width: size, height: size * 1.35)
      final cardWidth = size * 0.72;
      final cardHeight = size;
      return FittedBox(
        fit: BoxFit.contain,
        child: HolographicCard(
          width: cardWidth,
          height: cardHeight,
          backgroundAsset: 'assets/images/card_bg.png',
          characterAsset: 'assets/images/card_character.png',
          cardTitle: 'ULTRA RARE',
          cardSubtitle: 'Cyber Warrior',
          tiltAngle: 18.0,
          holoOpacity: 0.38,
        ),
      );
    }

    if (isCyberBoxer) {
      return CyberBoxerWidget(
        level: level,
        size: size,
      );
    }

    if (isNeonHuman3D) {
      return NeonHuman3DWidget(size: size);
    }

    return Lottie.asset(
      avatarPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) => Center(
        child: Text(
          '🎴',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}
