import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  COLOUR PALETTE
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // Metal / chrome
  static const metalLight = Color(0xFFEEF2F8);
  static const metalMid = Color(0xFFCDD6E8);
  static const metalDark = Color(0xFF8A9BB8);
  static const metalShadow = Color(0xFF6A7A9A);
  static const metalHighlight = Color(0xFFFFFFFF);

  // Blue accents (shorts, gloves)
  static const blueLight = Color(0xFF5B9FE8);
  static const blueMid = Color(0xFF2D72D2);
  static const blueDark = Color(0xFF1A4FA0);
  static const blueShadow = Color(0xFF0D2E6A);

  // Glove highlight / shine
  static const gloveHighlight = Color(0xFF7DC0FF);

  // White hair / boots
  static const hairLight = Color(0xFFF5F8FF);
  static const hairMid = Color(0xFFDDE4F0);
  static const hairDark = Color(0xFFB0C0D8);

  // Red goggles
  static const goggleRed = Color(0xFFD03030);
  static const goggleRedGlow = Color(0xFFFF6060);

  // Skin / face
  static const faceLight = Color(0xFFCDD9E8);
  static const faceMid = Color(0xFFAABACE);
  static const faceDark = Color(0xFF8898B0);

  // Belt
  static const beltDark = Color(0xFF1A2A40);
  static const beltGray = Color(0xFF445566);
  static const beltWhite = Color(0xFFEEF2F8);

  // Outline
  static const outline = Color(0xFF2A3A52);

  // Shadow
  static const shadow = Color(0x33000020);
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAINTER
// ─────────────────────────────────────────────────────────────────────────────

/// [punchT]  AnimationController value 0.0 → 1.0 driving the punch cycle
/// [idleT]   AnimationController value 0.0 → 1.0 (looping) for idle breathing
/// [level]   Player level controlling smoke colour
class CyberBoxerPainter extends CustomPainter {
  final double punchT;
  final double idleT;
  final int level;
  final List<SmokeParticle> smokeParticles;

  const CyberBoxerPainter({
    required this.punchT,
    required this.idleT,
    required this.level,
    required this.smokeParticles,
  });

  // ── Kinematic helpers ──────────────────────────────────────────────────────

  /// Smooth punch phases
  double get _anticipation => _smoothStep(0.0, 0.2, punchT); // 0→1 in 0-0.2
  double get _strike => _smoothStep(0.2, 0.6, punchT); // 0→1 in 0.2-0.6
  double get _recovery => _smoothStep(0.6, 1.0, punchT); // 0→1 in 0.6-1.0

  static double _smoothStep(double edge0, double edge1, double t) {
    final x = ((t - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// Torso offset X: anticipation pulls back, strike pushes forward
  double get _torsoOffsetX =>
      -8 * _anticipation + 28 * _strike - 28 * _recovery;

  /// Torso rotation: slight lean forward on strike
  double get _torsoRotation =>
      -0.04 * _anticipation + 0.12 * _strike - 0.12 * _recovery;

  /// Idle breathing offset (small vertical bob)
  double get _breathY => math.sin(idleT * 2 * math.pi) * 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // ── Scale to fit ──────────────────────────────────────────────────────
    final scale = size.shortestSide / 340.0;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    // ── Ground shadow ─────────────────────────────────────────────────────
    _drawGroundShadow(canvas);

    // ── Smoke (behind character) ──────────────────────────────────────────
    _drawSmoke(canvas);

    // ── Root / Torso transform ────────────────────────────────────────────
    canvas.save();
    canvas.translate(_torsoOffsetX, _breathY);
    canvas.rotate(_torsoRotation);

    // Draw order: back arm → legs → torso → front arm → head
    _drawBackArm(canvas);
    _drawLegs(canvas);
    _drawTorso(canvas);
    _drawFrontArm(canvas);
    _drawHead(canvas);

    canvas.restore(); // torso transform

    canvas.restore(); // root
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GROUND SHADOW
  // ─────────────────────────────────────────────────────────────────────────
  void _drawGroundShadow(Canvas canvas) {
    final paint = Paint()
      ..color = _C.shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(5, 148), width: 140, height: 22),
      paint,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SMOKE / STEAM
  // ─────────────────────────────────────────────────────────────────────────
  Color get _smokeColor {
    if (level >= 100) return const Color(0xFF9B30FF);
    if (level >= 50) return const Color(0xFFFFCC00);
    if (level >= 10) return const Color(0xFF4488FF);
    return Colors.transparent;
  }

  void _drawSmoke(Canvas canvas) {
    if (level < 10) return;
    final color = _smokeColor;
    for (final SmokeParticle p in smokeParticles) {
      final alpha = (p.life * 180).round().clamp(0, 255);
      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + p.size * 2);
      canvas.drawCircle(Offset(p.x - 50, p.y), p.size, paint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HEAD
  // ─────────────────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas) {
    // Neck
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(2, -68), width: 18, height: 20),
      4,
      _C.metalMid,
      _C.outline,
    );
    // Neck bolts
    _drawBolt(canvas, const Offset(-5, -65));
    _drawBolt(canvas, const Offset(9, -65));

    // Head base (face plate)
    final headRect =
        Rect.fromCenter(center: const Offset(2, -92), width: 48, height: 46);
    _fillRoundedRect(canvas, headRect, 12,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.faceLight, _C.faceMid, _C.faceDark],
        ).createShader(headRect));
    _strokeRoundedRect(canvas, headRect, 12, _C.outline, 1.5);

    // ─ Hair (bowl cut / helmet style) ─
    _drawHair(canvas);

    // ─ Face details ─
    // Jaw / chin segmentation line
    _drawLine(canvas, const Offset(-14, -76), const Offset(18, -76),
        _C.metalShadow, 1.0);
    // Ear panel L
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(-28, -90), width: 10, height: 18),
      4,
      _C.metalMid,
      _C.outline,
    );
    // Ear panel R
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(32, -90), width: 10, height: 18),
      4,
      _C.metalMid,
      _C.outline,
    );

    // ─ Goggles ─
    _drawGoggles(canvas);

    // Mouth grille lines
    for (int i = 0; i < 4; i++) {
      final y = -78.0 + i * 4;
      _drawLine(canvas, Offset(-8, y), Offset(12, y), _C.metalShadow, 0.8);
    }
  }

  void _drawHair(Canvas canvas) {
    final path = Path()
      ..moveTo(-26, -102)
      ..cubicTo(-30, -130, -10, -142, 2, -142)
      ..cubicTo(14, -142, 32, -130, 28, -102)
      ..close();
    final hairRect = const Rect.fromLTWH(-30, -145, 60, 45);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_C.metalHighlight, _C.hairLight, _C.hairMid],
      ).createShader(hairRect);
    canvas.drawPath(path, paint);
    final stroke = Paint()
      ..color = _C.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, stroke);

    // Hair strand lines
    final strandPaint = Paint()
      ..color = _C.hairDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = -2; i <= 2; i++) {
      final x = i * 6.0 + 2;
      final top = -140.0;
      final bot = -105.0;
      canvas.drawLine(Offset(x, top), Offset(x + i * 2, bot), strandPaint);
    }
  }

  void _drawGoggles(Canvas canvas) {
    // Goggle frame bar
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(2, -96), width: 50, height: 13),
      6,
      _C.metalDark,
      _C.outline,
    );

    // Left lens
    _drawGoggleLens(canvas, const Offset(-12, -96));
    // Right lens
    _drawGoggleLens(canvas, const Offset(16, -96));
  }

  void _drawGoggleLens(Canvas canvas, Offset center) {
    final rect = Rect.fromCenter(center: center, width: 14, height: 11);
    // Glow
    final glowPaint = Paint()
      ..color = _C.goggleRedGlow.withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(rect.inflate(3), glowPaint);

    // Lens fill
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [_C.goggleRedGlow, _C.goggleRed, const Color(0xFF800000)],
      ).createShader(rect);
    canvas.drawOval(rect, fillPaint);

    // Lens rim
    final rimPaint = Paint()
      ..color = _C.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(rect, rimPaint);

    // Highlight
    final hlPaint = Paint()
      ..color = Colors.white.withAlpha(140)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(center: center.translate(-2, -2), width: 5, height: 3),
        hlPaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TORSO
  // ─────────────────────────────────────────────────────────────────────────
  void _drawTorso(Canvas canvas) {
    // Upper torso (chest plate)
    final chestRect =
        Rect.fromCenter(center: const Offset(0, -28), width: 70, height: 60);
    _fillRoundedRect(canvas, chestRect, 10,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.metalLight, _C.metalMid, _C.metalDark],
        ).createShader(chestRect));
    _strokeRoundedRect(canvas, chestRect, 10, _C.outline, 1.5);

    // Chest panel lines (segmentation)
    _drawLine(canvas, const Offset(-20, -28), const Offset(20, -28),
        _C.metalShadow, 1.2);
    _drawLine(canvas, const Offset(0, -55), const Offset(0, -2),
        _C.metalShadow, 1.2);

    // Chest bolts
    _drawBolt(canvas, const Offset(-18, -44));
    _drawBolt(canvas, const Offset(18, -44));
    _drawBolt(canvas, const Offset(-18, -12));
    _drawBolt(canvas, const Offset(18, -12));

    // Blue display rect on chest
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(0, -28), width: 22, height: 14),
      3,
      _C.blueMid,
      _C.outline,
    );
    // Small white square on display
    _fillRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(0, -28), width: 10, height: 8),
      2,
      gradient: LinearGradient(
        colors: [Colors.white.withAlpha(220), _C.metalLight],
      ).createShader(const Rect.fromLTWH(-5, -32, 10, 8)),
    );

    // Belt
    _drawBelt(canvas);

    // Waist connector
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(0, 2), width: 54, height: 10),
      4,
      _C.metalMid,
      _C.outline,
    );
  }

  void _drawBelt(Canvas canvas) {
    // Belt strap
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(0, 10), width: 72, height: 16),
      4,
      _C.beltDark,
      _C.outline,
    );
    // Belt buckle
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(0, 10), width: 22, height: 12),
      3,
      _C.beltGray,
      _C.outline,
    );
    // Buckle white center
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(center: const Offset(0, 10), width: 14, height: 7),
      2,
      _C.beltWhite,
      _C.metalShadow,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LEGS
  // ─────────────────────────────────────────────────────────────────────────
  void _drawLegs(Canvas canvas) {
    // Shorts
    _drawShorts(canvas);

    // Back leg (right in stance, further from viewer)
    _drawLeg(canvas, isBack: true);
    // Front leg (left, closer)
    _drawLeg(canvas, isBack: false);
  }

  void _drawShorts(Canvas canvas) {
    final path = Path()
      ..moveTo(-38, 18)
      ..lineTo(38, 18)
      ..lineTo(30, 75)
      ..lineTo(10, 75)
      ..lineTo(2, 50)
      ..lineTo(-8, 75)
      ..lineTo(-28, 75)
      ..close();
    final shortsRect = const Rect.fromLTWH(-38, 18, 76, 57);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_C.blueLight, _C.blueMid, _C.blueDark],
      ).createShader(shortsRect);
    canvas.drawPath(path, paint);
    final stroke = Paint()
      ..color = _C.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, stroke);

    // Adidas-style stripes on shorts
    for (int i = 0; i < 3; i++) {
      final x = -28.0 + i * 5;
      _drawLine(
          canvas, Offset(x, 25), Offset(x - 3, 70), Colors.white38, 1.5);
    }
  }

  void _drawLeg(Canvas canvas, {required bool isBack}) {
    final xBase = isBack ? 22.0 : -20.0;
    final yBase = 75.0;
    final xFoot = isBack ? 38.0 : -42.0;
    final scale = isBack ? 0.88 : 1.0;

    canvas.save();
    if (isBack) {
      canvas.translate(xBase, yBase);
      canvas.scale(scale);
      canvas.translate(-xBase, -yBase);
    }

    // Upper leg (metal cylinder)
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(
          center: Offset(xBase, yBase + 18), width: 22, height: 36),
      8,
      _C.metalMid,
      _C.outline,
    );
    _drawLine(
        canvas,
        Offset(xBase - 8, yBase + 2),
        Offset(xBase + 8, yBase + 2),
        _C.metalShadow,
        0.8);

    // Knee joint
    final kc = Offset(xBase + (isBack ? 8 : -8), yBase + 36);
    _drawCircleGrad(canvas, kc, 11, _C.metalMid, _C.metalDark);
    _drawBolt(canvas, kc);

    // Lower leg
    _drawRoundedRect(
      canvas,
      Rect.fromCenter(
          center: Offset(kc.dx + (isBack ? 6 : -4), kc.dy + 22),
          width: 16,
          height: 34),
      6,
      _C.metalMid,
      _C.outline,
    );

    // Ankle
    final ac = Offset(kc.dx + (isBack ? 10 : -6), kc.dy + 42);
    _drawCircleGrad(canvas, ac, 8, _C.metalMid, _C.metalDark);

    // Boot
    _drawBoot(canvas, ac, isBack ? xFoot : xFoot, isBack);

    canvas.restore();
  }

  void _drawBoot(Canvas canvas, Offset ankle, double footX, bool isBack) {
    final dir = isBack ? 1.0 : -1.0;
    final bootBase = ankle.translate(dir * 8, 12);

    // Boot upper
    final upperRect = Rect.fromCenter(
        center: bootBase.translate(0, -4), width: 24, height: 22);
    _fillRoundedRect(canvas, upperRect, 6,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.hairLight, _C.hairMid],
        ).createShader(upperRect));
    _strokeRoundedRect(canvas, upperRect, 6, _C.outline, 1.2);

    // Sole
    final soleRect = Rect.fromCenter(
        center: bootBase.translate(dir * 4, 7), width: 36, height: 10);
    _fillRoundedRect(canvas, soleRect, 5,
        gradient: LinearGradient(
          colors: [_C.metalLight, _C.metalMid],
        ).createShader(soleRect));
    _strokeRoundedRect(canvas, soleRect, 5, _C.outline, 1.2);

    // Lace lines
    for (int i = 0; i < 4; i++) {
      final y = bootBase.dy - 10 + i * 4.0;
      _drawLine(canvas, Offset(bootBase.dx - 8, y), Offset(bootBase.dx + 8, y),
          _C.metalDark, 0.7);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ARMS
  // ─────────────────────────────────────────────────────────────────────────

  // Back arm = right arm (jab hand, further from viewer)
  void _drawBackArm(Canvas canvas) {
    // Static guard position (slightly raised, angled forward)
    final shoulderPos = const Offset(30, -38);

    // Upper arm
    final elbowPos = shoulderPos.translate(28, 18);
    _drawArmSegment(canvas, shoulderPos, elbowPos, 12, _C.metalMid);

    // Elbow joint
    _drawCircleGrad(canvas, elbowPos, 9, _C.metalMid, _C.metalDark);
    _drawBolt(canvas, elbowPos);

    // Forearm
    final wristPos = elbowPos.translate(14, -4);
    _drawArmSegment(canvas, elbowPos, wristPos, 9, _C.metalMid);

    // Glove (back, guard position)
    _drawGlove(canvas, wristPos, false, isPunching: false);
  }

  // Front arm = left arm (power hand, punching)
  void _drawFrontArm(Canvas canvas) {
    final shoulderPos = const Offset(-32, -42);

    // Punch kinematic:
    // - anticipation: arm pulls back (elbow goes back)
    // - strike: arm fully extends forward-left
    // - recovery: returns
    final strikeFactor = _strike - _recovery;

    final elbowOffset = Offset(
      -20 + strikeFactor * (-28),
      12 - strikeFactor * 8,
    );
    final elbowPos = shoulderPos + elbowOffset;

    final wristOffset = Offset(
      -18 + strikeFactor * (-34),
      -2 + strikeFactor * (-4),
    );
    final wristPos = shoulderPos + wristOffset;

    // Shoulder joint
    _drawCircleGrad(canvas, shoulderPos, 13, _C.metalMid, _C.metalDark);
    _drawBolt(canvas, shoulderPos);

    // Upper arm
    _drawArmSegment(canvas, shoulderPos, elbowPos, 13, _C.metalMid);

    // Elbow joint
    _drawCircleGrad(canvas, elbowPos, 10, _C.metalMid, _C.metalDark);
    _drawBolt(canvas, elbowPos);

    // Forearm cylinder
    _drawArmSegment(canvas, elbowPos, wristPos, 10, _C.metalMid);

    // ─ Light trail during strike ─
    if (_strike > 0.1 && _recovery < 0.3) {
      _drawPunchTrail(canvas, wristPos, strikeFactor);
    }

    // Glove
    _drawGlove(canvas, wristPos, true, isPunching: strikeFactor > 0.1);
  }

  void _drawPunchTrail(Canvas canvas, Offset tip, double factor) {
    final trailPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final t = i / 5.0;
      final alpha = (factor * (1.0 - t) * 150).round().clamp(0, 200);
      trailPaint.color = _C.gloveHighlight.withAlpha(alpha);
      final r = 18.0 - t * 10;
      canvas.drawCircle(tip.translate(t * 30, t * 6), r, trailPaint);
    }
  }

  void _drawArmSegment(
      Canvas canvas, Offset a, Offset b, double thickness, Color color) {
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    final length = (b - a).distance;

    canvas.save();
    canvas.translate(a.dx, a.dy);
    canvas.rotate(angle);

    final rect = Rect.fromLTWH(0, -thickness / 2, length, thickness);
    _fillRoundedRect(canvas, rect, thickness / 2,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_C.metalLight, color, _C.metalDark],
        ).createShader(rect));
    _strokeRoundedRect(canvas, rect, thickness / 2, _C.outline, 1.2);

    // Segment bolt
    _drawBolt(canvas, Offset(length / 2, 0));

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GLOVE
  // ─────────────────────────────────────────────────────────────────────────
  void _drawGlove(Canvas canvas, Offset wrist, bool isFront,
      {required bool isPunching}) {
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);

    // Rotate glove slightly on punch
    if (isFront && isPunching) canvas.rotate(-0.15);

    // Wrist cuff
    final cuffRect =
        Rect.fromCenter(center: const Offset(-10, 0), width: 20, height: 16);
    _fillRoundedRect(canvas, cuffRect, 6,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_C.blueLight, _C.blueMid],
        ).createShader(cuffRect));
    _strokeRoundedRect(canvas, cuffRect, 6, _C.outline, 1.2);

    // Main glove body
    final gloveRect = Rect.fromCenter(
      center: const Offset(-26, 0),
      width: 36,
      height: 30,
    );
    _fillRoundedRect(canvas, gloveRect, 12,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.gloveHighlight, _C.blueLight, _C.blueMid, _C.blueDark],
        ).createShader(gloveRect));
    _strokeRoundedRect(canvas, gloveRect, 12, _C.outline, 1.5);

    // Thumb bump
    final thumbRect = Rect.fromCenter(
      center: const Offset(-16, -12),
      width: 14,
      height: 10,
    );
    _fillRoundedRect(canvas, thumbRect, 5,
        gradient: const LinearGradient(
          colors: [_C.blueLight, _C.blueMid],
        ).createShader(thumbRect));
    _strokeRoundedRect(canvas, thumbRect, 5, _C.outline, 1.0);

    // Lace lines across glove
    for (int i = 0; i < 3; i++) {
      final x = -38.0 + i * 9;
      _drawLine(
          canvas, Offset(x, -10), Offset(x + 2, 10), _C.blueShadow, 0.8);
    }

    // Glove highlight
    final hlPaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-28, -6), width: 18, height: 8),
      hlPaint,
    );

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  REUSABLE DRAWING HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _drawBolt(Canvas canvas, Offset center) {
    final bg = Paint()..color = _C.metalDark;
    final hl = Paint()..color = _C.metalLight;
    canvas.drawCircle(center, 3.2, bg);
    canvas.drawCircle(center.translate(-0.8, -0.8), 1.2, hl);
    final rim = Paint()
      ..color = _C.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawCircle(center, 3.2, rim);
  }

  void _drawCircleGrad(
      Canvas canvas, Offset center, double radius, Color c1, Color c2) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [c1, c2],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
    final stroke = Paint()
      ..color = _C.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, stroke);
  }

  void _drawLine(
      Canvas canvas, Offset a, Offset b, Color color, double width) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawRoundedRect(
      Canvas canvas, Rect rect, double radius, Color fill, Color stroke) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rr, Paint()..color = fill);
    canvas.drawRRect(
        rr,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  void _fillRoundedRect(Canvas canvas, Rect rect, double radius,
      {required Shader gradient}) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rr, Paint()..shader = gradient);
  }

  void _strokeRoundedRect(
      Canvas canvas, Rect rect, double radius, Color color, double width) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
        rr,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width);
  }

  @override
  bool shouldRepaint(CyberBoxerPainter old) =>
      old.punchT != punchT ||
      old.idleT != idleT ||
      old.level != level ||
      old.smokeParticles != smokeParticles;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMOKE PARTICLE
// ─────────────────────────────────────────────────────────────────────────────
class SmokeParticle {
  double x;
  double y;
  double size;
  double life; // 0.0 → 1.0 (1 = fresh, 0 = dead)
  double vx;
  double vy;

  SmokeParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.life,
    required this.vx,
    required this.vy,
  });
}
