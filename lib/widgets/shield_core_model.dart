import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Cyber High-Tech Shield Palette
// ─────────────────────────────────────────────────────────────────────────────

const Color _kNeonCyan = Color(0xFF00F0FF);
const Color _kElectricBlue = Color(0xFF0D6EFD);
const Color _kDeepIndigo = Color(0xFF1E1B4B);
const Color _kCoreWhite = Color(0xFFFFFFFF);
const Color _kGoldPulse = Color(0xFFFFD700);

enum _PartType {
  outerBorder,    // Thick rim of classic shield shape
  innerGridFill,  // Uniform interior particle grid (filled surface)
  energyLines,    // Horizontal / vertical reinforcement ribs
  centerCore,     // Glowing energy core
  ambientEnergy,  // Particles radiating around the shield
}

class _ShieldParticle {
  final double x;
  final double y;
  final double z;
  final double baseSize;
  final double shimmerOffset;
  final double brightness;
  final _PartType type;

  const _ShieldParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.baseSize,
    required this.shimmerOffset,
    required this.brightness,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

class ShieldCoreModel extends StatefulWidget {
  final double size;
  final double phase; // 0.0 (rest/expanded) to 1.0 (compressed/loaded)

  const ShieldCoreModel({
    super.key,
    this.size = 240.0,
    this.phase = 0.0,
  });

  @override
  State<ShieldCoreModel> createState() => _ShieldCoreModelState();
}

class _ShieldCoreModelState extends State<ShieldCoreModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleCtrl;
  late List<_ShieldParticle> _particles;

  static const int _kTotalParticles = 5000;

  @override
  void initState() {
    super.initState();
    _particles = _generateRealShieldMesh(_kTotalParticles);
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    super.dispose();
  }

  /// Exact point-in-shield check for a classic heater shield shape.
  /// Top is flat (-0.75 <= x <= 0.75, y = 0.85).
  /// Sides curve down to a point at (x = 0, y = -0.90).
  static bool _isInsideShield(double x, double y) {
    if (y > 0.85 || y < -0.90) return false;
    
    // Top section (y: 0.20 to 0.85) — slightly tapered sides
    if (y >= 0.20) {
      final maxWidth = 0.75 - (0.85 - y) * 0.10;
      return x.abs() <= maxWidth;
    }
    
    // Lower section (y: -0.90 to 0.20) — parabolic curve down to point
    final progress = (y - 0.20) / (-1.10); // 0.0 at y=0.2, 1.0 at y=-0.9
    final currentWidth = 0.71 * math.pow(1.0 - progress, 0.75);
    return x.abs() <= currentWidth;
  }

  /// Calculates boundary X for a given Y
  static double _getShieldBoundaryX(double y) {
    if (y > 0.85) return 0.0;
    if (y >= 0.20) {
      return 0.75 - (0.85 - y) * 0.10;
    }
    final progress = (y - 0.20) / (-1.10);
    return (0.71 * math.pow(1.0 - progress, 0.75)).toDouble();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Generates an Anatomically Correct 3D Heater Shield Mesh
  // ─────────────────────────────────────────────────────────────────────────

  static List<_ShieldParticle> _generateRealShieldMesh(int total) {
    final rng = math.Random(101);
    final list = <_ShieldParticle>[];

    // 1. OUTLINE / BORDER (1,800 particles) — Crisp thick perimeter frame
    const int borderCount = 1800;
    for (int i = 0; i < borderCount; i++) {
      final t = i / borderCount; // 0..1 around perimeter
      double x, y;

      if (t < 0.25) {
        // Top edge (-0.75 to +0.75)
        x = -0.75 + (t / 0.25) * 1.50;
        y = 0.85;
      } else if (t < 0.625) {
        // Right parabolic curve down to tip (0.75, 0.85) -> (0, -0.90)
        final u = (t - 0.25) / 0.375; // 0..1
        y = 0.85 - u * 1.75;
        x = _getShieldBoundaryX(y);
      } else {
        // Left parabolic curve up from tip (0, -0.90) -> (-0.75, 0.85)
        final u = (t - 0.625) / 0.375; // 0..1
        y = -0.90 + u * 1.75;
        x = -_getShieldBoundaryX(y);
      }

      // Add 3-layer thickness to border
      final offsetDist = (rng.nextDouble() - 0.5) * 0.05;
      final px = x + offsetDist;
      final py = y + offsetDist;

      // 3D Convex Curve (+Z out toward viewer in middle)
      final z = math.sqrt(math.max(0.0, 0.64 - (px * px + py * py) * 0.4)) * 0.45;

      list.add(_ShieldParticle(
        x: px,
        y: py,
        z: z,
        baseSize: 1.4 + rng.nextDouble() * 0.8,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 0.90 + rng.nextDouble() * 0.10,
        type: _PartType.outerBorder,
      ));
    }

    // 2. UNIFORM FILLED INTERIOR SURFACE (2,000 particles) — Fully solid particle shield body
    int filledCount = 0;
    while (filledCount < 2000) {
      final rx = (rng.nextDouble() - 0.5) * 1.55;
      final ry = (rng.nextDouble() - 0.5) * 1.80;

      if (_isInsideShield(rx, ry)) {
        // Convex 3D curve (bulges outward toward viewer)
        final r2 = (rx * rx + ry * ry);
        final z = (0.45 - r2 * 0.25).clamp(0.05, 0.45);

        list.add(_ShieldParticle(
          x: rx,
          y: ry,
          z: z,
          baseSize: 0.9 + rng.nextDouble() * 0.7,
          shimmerOffset: rng.nextDouble() * math.pi * 2,
          brightness: 0.65 + rng.nextDouble() * 0.30,
          type: _PartType.innerGridFill,
        ));
        filledCount++;
      }
    }

    // 3. CROSS REINFORCEMENT RIBS (600 particles) — Central Vertical Spine & Horizontal Bar
    const int ribCount = 600;
    for (int i = 0; i < ribCount; i++) {
      double x, y;
      if (i < 300) {
        // Vertical spine (x = 0, y = -0.85 to +0.80)
        x = (rng.nextDouble() - 0.5) * 0.04;
        y = -0.85 + (i / 300.0) * 1.65;
      } else {
        // Horizontal crossbar (y = 0.35, x = -0.65 to +0.65)
        x = -0.65 + ((i - 300) / 300.0) * 1.30;
        y = 0.35 + (rng.nextDouble() - 0.5) * 0.04;
      }

      if (_isInsideShield(x, y)) {
        final z = (0.50 - (x * x + y * y) * 0.20).clamp(0.1, 0.50);
        list.add(_ShieldParticle(
          x: x,
          y: y,
          z: z,
          baseSize: 1.3 + rng.nextDouble() * 0.7,
          shimmerOffset: rng.nextDouble() * math.pi * 2,
          brightness: 0.85 + rng.nextDouble() * 0.15,
          type: _PartType.energyLines,
        ));
      }
    }

    // 4. CENTER GLOW CORE (400 particles)
    const int coreCount = 400;
    for (int i = 0; i < coreCount; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = math.pow(rng.nextDouble(), 0.6) * 0.22;
      final x = dist * math.cos(angle);
      final y = 0.35 + dist * math.sin(angle); // centered on crossbar intersection
      final z = 0.48 + (rng.nextDouble() - 0.5) * 0.10;

      list.add(_ShieldParticle(
        x: x,
        y: y,
        z: z,
        baseSize: 1.6 + rng.nextDouble() * 1.2,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 0.95 + rng.nextDouble() * 0.05,
        type: _PartType.centerCore,
      ));
    }

    // 5. AMBIENT SPARKS (200 particles)
    const int sparkCount = 200;
    for (int i = 0; i < sparkCount; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 0.3 + rng.nextDouble() * 0.75;
      final x = dist * math.cos(angle);
      final y = (rng.nextDouble() - 0.5) * 1.6;
      final z = (rng.nextDouble() - 0.5) * 0.4;

      list.add(_ShieldParticle(
        x: x,
        y: y,
        z: z,
        baseSize: 0.7 + rng.nextDouble() * 0.7,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
        brightness: 0.5 + rng.nextDouble() * 0.5,
        type: _PartType.ambientEnergy,
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ShieldPainter3D(
            particles: _particles,
            idleTime: _idleCtrl.value,
            compressionPhase: widget.phase,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  3D Renderer with Perspective Projection & Smooth Rotation Dynamics
// ─────────────────────────────────────────────────────────────────────────────

class _ShieldPainter3D extends CustomPainter {
  final List<_ShieldParticle> particles;
  final double idleTime;
  final double compressionPhase;

  _ShieldPainter3D({
    required this.particles,
    required this.idleTime,
    required this.compressionPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0 + 10.0; // slightly down centered
    final baseScale = size.width * 0.44;

    // Deep, rhythmic, stately breathing wave (sine curve over 10 seconds)
    // Smoothly expands and contracts the shield up to ±22% for a deep breathing effect
    final double deepBreathing = math.sin(idleTime * math.pi * 2) * 0.22;
    final double totalPhase = (compressionPhase + deepBreathing).clamp(-0.25, 1.0);

    // Deep scale factor: deep inhale contracts, deep exhale expands shield dramatically
    final double compressFactor = 1.0 - totalPhase * 0.35;
    final double currentScale = baseScale * compressFactor;

    // Ultra-smooth 3D tilt & rotation (yaw: -18°..+18°, pitch: -8°..+8°)
    final double yaw = math.sin(idleTime * math.pi * 2) * 0.20;
    final double pitch = math.cos(idleTime * math.pi * 2 * 0.5) * 0.08 - 0.03;

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);

    // Ambient Outer Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(_kNeonCyan, _kGoldPulse, compressionPhase)!
              .withValues(alpha: 0.28 + compressionPhase * 0.30),
          _kElectricBlue.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.55),
      );
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55, glowPaint);

    final projected = <({
      double sx,
      double sy,
      double depthZ,
      double size,
      Color color,
      double alpha,
      _PartType type,
    })>[];

    for (final p in particles) {
      double px = p.x;
      double py = p.y;
      double pz = p.z;

      if (p.type == _PartType.centerCore) {
        pz += compressionPhase * 0.18;
      } else {
        px *= compressFactor;
        py *= compressFactor;
      }

      // 3D Rotation
      final x1 = px * cosY + pz * sinY;
      final z1 = -px * sinY + pz * cosY;

      final y2 = py * cosX - z1 * sinX;
      final z2 = py * sinX + z1 * cosX;

      // Perspective
      const double fov = 3.8;
      final double persp = fov / (fov + z2);

      final double sx = cx + x1 * currentScale * persp;
      final double sy = cy - y2 * currentScale * persp; // -y for screen coordinates

      final double shimmer = 0.75 + 0.25 * math.sin(p.shimmerOffset + idleTime * math.pi * 6);
      final double depthNorm = ((z2 + 1.0) / 2.0).clamp(0.1, 1.0);
      double alpha = (p.brightness * shimmer * (0.40 + 0.60 * depthNorm)).clamp(0.0, 1.0);

      Color col;
      switch (p.type) {
        case _PartType.outerBorder:
          col = Color.lerp(_kNeonCyan, _kGoldPulse, compressionPhase * 0.85)!;
          break;
        case _PartType.energyLines:
        case _PartType.centerCore:
          col = Color.lerp(_kCoreWhite, _kGoldPulse, compressionPhase)!;
          alpha = (alpha + compressionPhase * 0.3).clamp(0.0, 1.0);
          break;
        case _PartType.innerGridFill:
          col = Color.lerp(_kElectricBlue, _kNeonCyan, depthNorm)!;
          break;
        case _PartType.ambientEnergy:
          col = _kNeonCyan;
          break;
      }

      final pSize = p.baseSize * persp * (0.6 + depthNorm * 0.5);

      projected.add((
        sx: sx,
        sy: sy,
        depthZ: z2,
        size: pSize,
        color: col,
        alpha: alpha,
        type: p.type,
      ));
    }

    // Depth Sorting
    projected.sort((a, b) => a.depthZ.compareTo(b.depthZ));

    final paintObj = Paint();

    for (final pt in projected) {
      if (pt.alpha < 0.02) continue;

      final offset = Offset(pt.sx, pt.sy);

      // Glow blur for border outline & center core
      if (pt.type == _PartType.outerBorder ||
          pt.type == _PartType.centerCore ||
          pt.size > 1.4) {
        paintObj
          ..color = pt.color.withValues(alpha: pt.alpha * 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pt.size * 2.0);
        canvas.drawCircle(offset, pt.size * 2.0, paintObj);
        paintObj.maskFilter = null;
      }

      paintObj.color = pt.color.withValues(alpha: pt.alpha);
      canvas.drawCircle(offset, pt.size, paintObj);
    }
  }

  @override
  bool shouldRepaint(_ShieldPainter3D old) =>
      old.idleTime != idleTime || old.compressionPhase != compressionPhase;
}
