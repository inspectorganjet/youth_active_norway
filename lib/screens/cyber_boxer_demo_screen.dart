import 'package:flutter/material.dart';
import '../widgets/cyber_boxer_widget.dart';

/// Standalone demo screen for the cyber boxer.
/// Can be pushed from any route:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const CyberBoxerDemoScreen()));
class CyberBoxerDemoScreen extends StatefulWidget {
  const CyberBoxerDemoScreen({super.key});

  @override
  State<CyberBoxerDemoScreen> createState() => _CyberBoxerDemoScreenState();
}

class _CyberBoxerDemoScreenState extends State<CyberBoxerDemoScreen> {
  int _level = 0;

  // Level presets for quick testing
  static const _levelPresets = [
    (label: 'No smoke', value: 0),
    (label: 'Blue (lvl 10)', value: 10),
    (label: 'Yellow (lvl 50)', value: 50),
    (label: 'Purple (lvl 100)', value: 100),
    (label: 'Max (lvl 500)', value: 500),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CYBER BOXER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Column(
        children: [
          // ── Bokeh background + boxer ────────────────────────────────────
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radial glow behind the fighter
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _glowColor().withAlpha(60),
                        Colors.transparent,
                      ],
                      radius: 0.5,
                    ),
                  ),
                ),
                // The boxer (tap to punch)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    CyberBoxerWidget(
                      level: _level,
                      size: 300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TAP TO PUNCH',
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        letterSpacing: 3,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Level badge
                Positioned(
                  top: 16,
                  right: 24,
                  child: _LevelBadge(level: _level),
                ),
              ],
            ),
          ),

          // ── Controls ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF162035),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SMOKE LEVEL',
                  style: TextStyle(
                    color: Color(0xFF8899BB),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Preset buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _levelPresets.map((preset) {
                    final selected = _level == preset.value;
                    return GestureDetector(
                      onTap: () => setState(() => _level = preset.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _glowColorForLevel(preset.value)
                              : const Color(0xFF1F3050),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? _glowColorForLevel(preset.value)
                                : const Color(0xFF2A4070),
                            width: 1.5,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: _glowColorForLevel(preset.value)
                                        .withAlpha(80),
                                    blurRadius: 12,
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          preset.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white.withAlpha(180),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _glowColor(),
                    inactiveTrackColor: const Color(0xFF2A4070),
                    thumbColor: _glowColor(),
                    overlayColor: _glowColor().withAlpha(40),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _level.toDouble(),
                    min: 0,
                    max: 500,
                    divisions: 100,
                    onChanged: (v) => setState(() => _level = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Level $_level',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(_smokeLevelLabel(),
                        style: TextStyle(
                            color: _glowColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _glowColor() => _glowColorForLevel(_level);

  Color _glowColorForLevel(int lvl) {
    if (lvl >= 100) return const Color(0xFF9B30FF);
    if (lvl >= 50) return const Color(0xFFFFCC00);
    if (lvl >= 10) return const Color(0xFF4488FF);
    return const Color(0xFF445566);
  }

  String _smokeLevelLabel() {
    if (_level >= 100) return 'PURPLE SMOKE';
    if (_level >= 50) return 'YELLOW SMOKE';
    if (_level >= 10) return 'BLUE SMOKE';
    return 'NO SMOKE';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LEVEL BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2A4070).withAlpha(180), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('LVL',
              style: TextStyle(
                  color: Color(0xFF8899BB),
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          Text(
            '$level',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.0),
          ),
        ],
      ),
    );
  }
}
