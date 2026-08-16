import 'dart:ui';

/// Tre visuelle evolusjonsnivåer for bokseren
enum AvatarLevel { novice, pro, legend }

/// Konfigurasjon av visuelle parametere for hvert nivå
class LevelConfig {
  final AvatarLevel level;

  /// Hovedfarge for partikler
  final Color primaryColor;

  /// Sekundærfarge (gradient inne i skyen)
  final Color secondaryColor;

  /// Aurafarge (halvgjennomsiktig)
  final Color auraColor;

  /// Antall partikler (800 → 1500 → 2800)
  final int particleCount;

  /// Auraradius rundt kroppen
  final double auraRadius;

  /// Aktiver lysslør ved slag
  final bool trailEnabled;

  /// Aktiver energiringer
  final bool ringEnabled;

  /// Pustehastighet (multiplikator)
  final double breathSpeed;

  /// Glødeintensitet
  final double glowIntensity;

  /// Nivånavn på norsk
  final String levelName;

  const LevelConfig({
    required this.level,
    required this.primaryColor,
    required this.secondaryColor,
    required this.auraColor,
    required this.particleCount,
    required this.auraRadius,
    required this.trailEnabled,
    required this.ringEnabled,
    required this.breathSpeed,
    required this.glowIntensity,
    required this.levelName,
  });

  // ─── Preset configs ───────────────────────────────────────────

  /// Nivå 1 (Nybegynner): Elektrisk blå konturer.
  static const novice = LevelConfig(
    level: AvatarLevel.novice,
    primaryColor: Color(0xFF00E5FF),
    secondaryColor: Color(0xFF0066FF),
    auraColor: Color(0x1A00E5FF),
    particleCount: 1100,
    auraRadius: 0,
    trailEnabled: false,
    ringEnabled: false,
    breathSpeed: 0.75,
    glowIntensity: 1.8,
    levelName: 'Nybegynner (Nivå 1)',
  );

  /// Nivå 50 (Mester): Gyldne oransje konturer med glødende flammeeffekt.
  static const pro = LevelConfig(
    level: AvatarLevel.pro,
    primaryColor: Color(0xFFFF9100),
    secondaryColor: Color(0xFFFF3D00),
    auraColor: Color(0x3DFF9100),
    particleCount: 1800,
    auraRadius: 140,
    trailEnabled: true,
    ringEnabled: true,
    breathSpeed: 1.15,
    glowIntensity: 3.8,
    levelName: 'Mester (Nivå 50)',
  );

  /// Nivå 100 (Legende): Lysende lilla med hvite lyn og partikkelslør.
  static const legend = LevelConfig(
    level: AvatarLevel.legend,
    primaryColor: Color(0xFFD500F9),
    secondaryColor: Color(0xFFFFFFFF),
    auraColor: Color(0x52D500F9),
    particleCount: 2900,
    auraRadius: 200,
    trailEnabled: true,
    ringEnabled: true,
    breathSpeed: 1.5,
    glowIntensity: 5.5,
    levelName: 'Legende (Nivå 100)',
  );

  /// Bestem konfigurasjon ut fra numerisk nivå 1–100
  static LevelConfig fromLevel(int level) {
    if (level >= 100) return legend;
    if (level >= 50) return pro;
    return novice;
  }
}

