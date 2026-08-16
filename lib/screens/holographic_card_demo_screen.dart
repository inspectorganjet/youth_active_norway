import 'package:flutter/material.dart';
import '../widgets/holographic_card.dart';

/// Demoskjerm for holografisk kort.
class HolographicCardDemoScreen extends StatelessWidget {
  const HolographicCardDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Holographic Card Demo',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
      body: Center(
        child: HolographicCard(
          width:          300,
          height:         420,
          backgroundAsset: 'assets/images/card_bg.png',
          characterAsset:  'assets/images/card_character.png',
          cardTitle:       'ULTRA RARE',
          cardSubtitle:    'Cyber Warrior',
          tiltAngle:       18.0,
          holoOpacity:     0.38,
        ),
      ),
    );
  }
}
