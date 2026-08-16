import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Black Hole & Nova — Palette
// ─────────────────────────────────────────────────────────────────────────────

const Color _kCoolBlue = Color(0xFF4FC3F7);
const Color _kDeepPurple = Color(0xFF7C4DFF);
const Color _kHotOrange = Color(0xFFFF6D00);
const Color _kNovaWhite = Color(0xFFFFFFFF);
const Color _kAccretionGold = Color(0xFFFFD740);
const Color _kVoidBlack = Color(0xFF0A0A1A);

// ─────────────────────────────────────────────────────────────────────────────
//  Particle types
// ─────────────────────────────────────────────────────────────────────────────

enum _NovaPartType {
  /// Core orbital particles (the main glowing sphere at rest)
  orbitalSphere,

  /// Accretion disk (flat equatorial ring around the core)
  accretionDisk,

  /// Outer debris cloud (loose particles orbiting at range)
  outerCloud,

  /// Supernova blast shards (only visible during nova explosion)
  novaBlast,
}

class _NovaParticle {
  // Orbital parameters (spherical coords at rest radius)
  final double theta; // azimuth 0..2π
  final double phi;   // polar 0..π
  final double restRadius; // normalised 0..1
  final double orbitSpeed; // multiplier on spin rate
  final double baseSize;
  final double shimmerOffset;
  final double brightness;
  final _NovaPartType type;

  const _NovaParticle({
    required this.theta,
    required this.phi,
    required this.restRadius,
    required this.orbitSpeed,
    required this.baseSize,
    required this.shimmerOffset,
    required this.brightness,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

/// 3D "Black Hole & Nova" particle system for the Abs / Core workout mode.
///
/// **[crunchPhase]** 0.0 = resting sphere/ring, 1.0 = maximum collapse
/// (particles spiralling into dense black hole core, colour shifts hot).
///
/// **[novaBurst]** 0.0 = no explosion, > 0.0 = supernova shockwave propagating
/// outward (typically triggered at each 5-rep milestone).
class BlackHoleNovaModel extends StatefulWidget {
  final double size;

  /// 0.0 (open / expended) → 1.0 (compressed / black hole peak)
  final double crunchPhase;

  /// 0.0 → 1.0: supernova explosion progress (one-shot wave)
  final double novaBurst;

  const BlackHoleNovaModel({
    super.key,
    this.size = 240.0,
    this.crunchPhase = 0.0,
    this.novaBurst = 0.0,
  });

  @override
  State<BlackHoleNovaModel> createState() => _BlackHoleNovaModelState();
}

class _BlackHoleNovaModelState extends State<BlackHoleNovaModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late List<_NovaParticle> _particles;

  static const int _kCount = 5000;

  @override
  void initState() {
    super.initState();
    _particles = _buildNovaMesh(_kCount);
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Mesh Builder — distributes particles across layers
  // ─────────────────────────────────────────────────────────────────────────

  static List<_NovaParticle> _buildNovaMesh(int total) {
    final rng = math.Random(31415);
    final list = <_NovaParticle>[];

    // 1. ORBITAL SPHERE SURFACE (2,400 particles) — main glowing shell
    const int sphereCount = 2400;
    for (int i = 0; i < sphereCount; i++) {
      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);
      final r = 0.72 + rng.nextDouble() * 0.14; // thin surface shell

      list.add(_NovaParticle(
        theta: theta,
        phi: phi,
        restRadius: r,
        orbitSpeed: 0.8 + rng.nextDouble() * 0.5,
        baseSize: 1.0 + rng.nextDouble() * 0.8,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 0.70 + rng.nextDouble() * 0.30,
        type: _NovaPartType.orbitalSphere,
      ));
    }

    // 2. ACCRETION DISK — flat equatorial ring (1,200 particles)
    const int diskCount = 1200;
    for (int i = 0; i < diskCount; i++) {
      final angle = (i / diskCount) * 2 * math.pi + rng.nextDouble() * 0.08;
      final radiusNoise = 0.55 + rng.nextDouble() * 0.42;
      final heightNoise = (rng.nextDouble() - 0.5) * 0.18; // thin flat disk

      list.add(_NovaParticle(
        theta: angle,
        phi: math.pi / 2 + heightNoise, // equatorial plane ± noise
        restRadius: radiusNoise,
        orbitSpeed: 1.2 + rng.nextDouble() * 1.0, // disk spins faster
        baseSize: 1.2 + rng.nextDouble() * 0.7,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 0.80 + rng.nextDouble() * 0.20,
        type: _NovaPartType.accretionDisk,
      ));
    }

    // 3. OUTER DEBRIS CLOUD (1,000 particles) — loose far-out orbiters
    const int cloudCount = 1000;
    for (int i = 0; i < cloudCount; i++) {
      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);
      final r = 0.88 + rng.nextDouble() * 0.30;

      list.add(_NovaParticle(
        theta: theta,
        phi: phi,
        restRadius: r,
        orbitSpeed: 0.4 + rng.nextDouble() * 0.4,
        baseSize: 0.7 + rng.nextDouble() * 0.6,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 0.45 + rng.nextDouble() * 0.35,
        type: _NovaPartType.outerCloud,
      ));
    }

    // 4. NOVA BLAST SHARDS (400 particles) — stored at r=1, radius expanded by novaBurst
    const int blastCount = 400;
    for (int i = 0; i < blastCount; i++) {
      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);

      list.add(_NovaParticle(
        theta: theta,
        phi: phi,
        restRadius: 1.0,
        orbitSpeed: 1.0,
        baseSize: 1.8 + rng.nextDouble() * 1.2,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 1.0,
        type: _NovaPartType.novaBlast,
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spinCtrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NovaPainter(
            particles: _particles,
            spinTime: _spinCtrl.value,
            crunchPhase: widget.crunchPhase,
            novaBurst: widget.novaBurst,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────────────────────

class _NovaPainter extends CustomPainter {
  final List<_NovaParticle> particles;
  final double spinTime;
  final double crunchPhase;
  final double novaBurst;

  _NovaPainter({
    required this.particles,
    required this.spinTime,
    required this.crunchPhase,
    required this.novaBurst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final baseR = size.width * 0.44;

    // ── Crunch: collapses sphere inward at phase 1.0 ──────────────────────────
    // rest → collapsed: 1.0 → ~0.15 (tiny black hole point)
    final double collapseR = baseR * (1.0 - crunchPhase * 0.85);

    // ── Spin accelerates on crunch ────────────────────────────────────────────
    final double spinRate = 1.0 + crunchPhase * 3.5; // spins 4.5× faster at peak
    final double globalSpin = spinTime * math.pi * 2 * spinRate;

    // ── Tilt: gentle idle Y/X oscillation ────────────────────────────────────
    final double yaw = math.sin(spinTime * math.pi * 2) * 0.22;
    final double pitch = math.cos(spinTime * math.pi * 2 * 0.7) * 0.12;
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);

    // ── Ambient void glow (darkens to black on crunch) ────────────────────────
    final Color glowColor = Color.lerp(_kCoolBlue, _kHotOrange, crunchPhase)!;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.22 + crunchPhase * 0.25),
          _kDeepPurple.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.55),
      );
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55, glowPaint);

    // ── Event horizon: opaque black core at max crunch ────────────────────────
    if (crunchPhase > 0.3) {
      final double holeR = collapseR * 0.20 * crunchPhase;
      final Paint holePaint = Paint()
        ..shader = RadialGradient(
          colors: [_kVoidBlack, _kVoidBlack.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: holeR * 1.5),
        );
      canvas.drawCircle(Offset(cx, cy), holeR * 1.5, holePaint);
    }

    // ── Project & render particles ─────────────────────────────────────────────
    final renderList = <({double sx, double sy, double z, double ps, Color color, double alpha})>[];

    for (final p in particles) {
      // Nova blast: skip unless novaBurst is active
      if (p.type == _NovaPartType.novaBlast) {
        if (novaBurst < 0.02) continue;
        final blastR = baseR * (1.0 + novaBurst * 1.8);
        final alpha = (1.0 - novaBurst).clamp(0.0, 1.0) * p.brightness;

        final sp = math.sin(p.phi), cp = math.cos(p.phi);
        final st = math.sin(p.theta), ct = math.cos(p.theta);
        final bx = blastR * sp * ct;
        final by = blastR * cp;
        final bz = blastR * sp * st;

        final x1 = bx * cosY + bz * sinY;
        final z1 = -bx * sinY + bz * cosY;
        final y2 = by * cosX - z1 * sinX;
        final z2 = by * sinX + z1 * cosX;

        const fov = 3.5;
        final persp = fov / (fov + z2 * 0.5);
        final col = Color.lerp(_kNovaWhite, _kHotOrange, novaBurst)!;

        renderList.add((
          sx: cx + x1 * persp,
          sy: cy - y2 * persp,
          z: z2,
          ps: p.baseSize * persp * 1.4,
          color: col,
          alpha: alpha,
        ));
        continue;
      }

      // Regular particles: apply crunch collapse + spin
      // Radius shrinks toward 0 as crunchPhase → 1.0
      double effRadius;
      if (p.type == _NovaPartType.accretionDisk) {
        // Accretion disk collapses harder (it feeds the black hole)
        effRadius = p.restRadius * collapseR * (0.40 + (1.0 - crunchPhase) * 0.60);
      } else if (p.type == _NovaPartType.outerCloud) {
        // Outer cloud: pulled inward but more slowly
        effRadius = p.restRadius * (collapseR + baseR * 0.15) * (0.6 + (1.0 - crunchPhase) * 0.4);
      } else {
        effRadius = p.restRadius * collapseR;
      }

      // Orbital spin baked into theta
      final dynTheta = p.theta + globalSpin * p.orbitSpeed;
      final sp = math.sin(p.phi), cp = math.cos(p.phi);
      final st = math.sin(dynTheta), ct = math.cos(dynTheta);

      double x = effRadius * sp * ct;
      double y = effRadius * cp;
      double z = effRadius * sp * st;

      // Rotate
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;
      final y2 = y * cosX - z1 * sinX;
      final z2 = y * sinX + z1 * cosX;

      const fov = 3.5;
      final persp = fov / (fov + z2 * 0.4);
      final sx = cx + x1 * persp;
      final sy = cy - y2 * persp;

      // Shimmer
      final shimmer = 0.70 + 0.30 * math.sin(p.shimmerOffset + spinTime * math.pi * 7 * spinRate);
      final depthNorm = ((z2 / (baseR * 0.8) + 1.0) * 0.5).clamp(0.1, 1.0);
      double alpha = (p.brightness * shimmer * (0.35 + 0.65 * depthNorm)).clamp(0.0, 1.0);

      // Colour: cool blue at rest → hot orange/gold at peak crunch
      Color col;
      switch (p.type) {
        case _NovaPartType.accretionDisk:
          col = Color.lerp(_kAccretionGold, _kHotOrange, crunchPhase)!;
          alpha = (alpha + crunchPhase * 0.3).clamp(0.0, 1.0);
          break;
        case _NovaPartType.orbitalSphere:
          col = Color.lerp(_kCoolBlue, _kDeepPurple, crunchPhase * 0.7)!;
          break;
        case _NovaPartType.outerCloud:
          col = Color.lerp(_kDeepPurple, _kCoolBlue, depthNorm)!;
          break;
        default:
          col = _kCoolBlue;
      }

      final pSize = p.baseSize * persp * (0.55 + depthNorm * 0.55);

      renderList.add((
        sx: sx,
        sy: sy,
        z: z2,
        ps: pSize,
        color: col,
        alpha: alpha,
      ));
    }

    // Depth sort
    renderList.sort((a, b) => a.z.compareTo(b.z));

    final paintObj = Paint();
    for (final r in renderList) {
      if (r.alpha < 0.02) continue;
      final offset = Offset(r.sx, r.sy);

      if (r.ps > 1.1 || r.color == _kNovaWhite) {
        paintObj
          ..color = r.color.withValues(alpha: r.alpha * 0.40)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.ps * 2.2);
        canvas.drawCircle(offset, r.ps * 2.0, paintObj);
        paintObj.maskFilter = null;
      }

      paintObj.color = r.color.withValues(alpha: r.alpha);
      canvas.drawCircle(offset, r.ps, paintObj);
    }
  }

  @override
  bool shouldRepaint(_NovaPainter old) =>
      old.spinTime != spinTime ||
      old.crunchPhase != crunchPhase ||
      old.novaBurst != novaBurst;
}
