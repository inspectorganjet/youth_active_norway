
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Muscle group enum — determines particle colour.
enum _MuscleGroup {
  /// Skeleton / connective tissue / neutral body — neon blue
  neutral,

  /// Chest (pectoralis major/minor) — engaged during pushups → violet/pink
  chest,

  /// Triceps brachii — engaged during pushups → violet/pink
  triceps,

  /// Anterior deltoid / shoulder — engaged during pushups → violet/pink
  shoulder,

  /// Serratus anterior / core stabiliser — violet/pink (secondary)
  serratus,
}

class _HumanParticle {
  final double x, y, z;
  final double baseSize;
  final double shimmerPhase;
  final double brightness;
  final _MuscleGroup muscle;
  final bool isHighlight;

  const _HumanParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.baseSize,
    required this.shimmerPhase,
    required this.brightness,
    required this.muscle,
    required this.isHighlight,
  });
}

class _ProjectedParticle {
  final double sx, sy, wz, alpha, size, depthFactor;
  final _MuscleGroup muscle;
  final bool isHighlight;

  const _ProjectedParticle({
    required this.sx,
    required this.sy,
    required this.wz,
    required this.alpha,
    required this.size,
    required this.depthFactor,
    required this.muscle,
    required this.isHighlight,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Colour palette
// ─────────────────────────────────────────────────────────────────────────────

/// Neon electric blue for the neutral body structure.
const Color _kBlueDeep = Color(0xFF0D47FF);
const Color _kBlueMid = Color(0xFF2979FF);
const Color _kBlueBright = Color(0xFF82B1FF);
const Color _kBlueGlow = Color(0xFF448AFF);

/// Violet-pink palette for the engaged muscles.
const Color _kVioletDeep = Color(0xFF9C27B0);
const Color _kVioletMid = Color(0xFFCE93D8);
const Color _kPinkBright = Color(0xFFFF4FC3);
const Color _kPinkGlow = Color(0xFFFF80AB);

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

/// A full-body 3-D anatomical human figure composed of ~5 000 glowing particles.
///
/// • **Neutral body** (skeleton, limbs, head, core) → neon blue.
/// • **Pushup-engaged muscles** (pectorals, triceps, shoulders, serratus)
///   → violet / pink glow.
///
/// The model responds to mouse-hover / pointer-drag for 3-D rotation.
class PushupHumanModel extends StatefulWidget {
  final double size;

  const PushupHumanModel({super.key, this.size = 260});

  @override
  State<PushupHumanModel> createState() => _PushupHumanModelState();
}

class _PushupHumanModelState extends State<PushupHumanModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late List<_HumanParticle> _particles;

  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;
  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;

  static const int _kCount = 5000;

  @override
  void initState() {
    super.initState();
    _particles = _buildHumanMesh(_kCount);
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent e) {
    final double dx =
        (e.localPosition.dx - widget.size / 2) / (widget.size / 2);
    final double dy =
        (e.localPosition.dy - widget.size / 2) / (widget.size / 2);
    setState(() {
      _targetTiltY = dx * 40.0;
      _targetTiltX = -dy * 25.0;
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Particle mesh generator — full anatomical human
  // ───────────────────────────────────────────────────────────────────────────

  /// Helper: add a filled ellipsoid of particles.
  static void _addEllipsoid(
    List<_HumanParticle> out,
    math.Random rng, {
    required double cx,
    required double cy,
    required double cz,
    required double rx,
    required double ry,
    required double rz,
    required int count,
    required _MuscleGroup muscle,
    double brightnessBoost = 0.0,
    bool highlightFraction = false,
  }) {
    for (int i = 0; i < count; i++) {
      final double u = rng.nextDouble();
      final double v = rng.nextDouble();
      final double theta = u * 2.0 * math.pi;
      final double phi = math.acos(2.0 * v - 1.0);
      // Use cube-root for filled volume
      final double r = math.pow(rng.nextDouble(), 1 / 3).toDouble();

      final double x = cx + rx * r * math.sin(phi) * math.cos(theta);
      final double y = cy + ry * r * math.cos(phi);
      final double z = cz + rz * r * math.sin(phi) * math.sin(theta);

      final bool hi = highlightFraction && rng.nextDouble() > 0.6;
      final double sz = hi ? (2.0 + rng.nextDouble() * 1.5) : (0.8 + rng.nextDouble() * 1.8);
      final double brightness = (0.55 + rng.nextDouble() * 0.45 + brightnessBoost).clamp(0.0, 1.0);

      out.add(_HumanParticle(
        x: x, y: y, z: z,
        baseSize: sz,
        shimmerPhase: rng.nextDouble() * math.pi * 2,
        brightness: brightness,
        muscle: muscle,
        isHighlight: hi,
      ));
    }
  }

  /// Helper: add a tapered cylinder (tube) of particles.
  static void _addCylinder(
    List<_HumanParticle> out,
    math.Random rng, {
    required double x0, required double y0, required double z0,
    required double x1, required double y1, required double z1,
    required double r0,
    required double r1,
    required int count,
    required _MuscleGroup muscle,
    double brightnessBoost = 0.0,
  }) {
    // Build a local coordinate frame for the cylinder
    final double dx = x1 - x0, dy = y1 - y0, dz = z1 - z0;
    final double len = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (len < 1e-6) return;
    final double ux = dx / len, uy = dy / len, uz = dz / len;

    // Arbitrary perpendicular vector
    double px, py, pz;
    if (ux.abs() < 0.9) {
      px = 0; py = uz; pz = -uy;
    } else {
      px = -uz; py = 0; pz = ux;
    }
    final double plen = math.sqrt(px*px + py*py + pz*pz);
    px /= plen; py /= plen; pz /= plen;
    // q = u × p
    final double qx = uy*pz - uz*py;
    final double qy = uz*px - ux*pz;
    final double qz = ux*py - uy*px;

    for (int i = 0; i < count; i++) {
      final double t = rng.nextDouble();
      final double angle = rng.nextDouble() * 2.0 * math.pi;
      final double radiusNoise = 0.8 + 0.2 * rng.nextDouble();
      final double radius = (r0 + (r1 - r0) * t) * radiusNoise;

      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final double x = x0 + ux*t*len + radius*(px*cosA + qx*sinA);
      final double y = y0 + uy*t*len + radius*(py*cosA + qy*sinA);
      final double z = z0 + uz*t*len + radius*(pz*cosA + qz*sinA);

      final double sz = 0.9 + rng.nextDouble() * 1.6;
      final double brightness = (0.5 + rng.nextDouble() * 0.5 + brightnessBoost).clamp(0.0, 1.0);

      out.add(_HumanParticle(
        x: x, y: y, z: z,
        baseSize: sz,
        shimmerPhase: rng.nextDouble() * math.pi * 2,
        brightness: brightness,
        muscle: muscle,
        isHighlight: false,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  //  Full anatomical mesh
  //  Coordinate system (normalised units, ≈ -1.0 … +1.0):
  //   +Y = up,  +X = right,  +Z = toward viewer
  // ---------------------------------------------------------------------------
  static List<_HumanParticle> _buildHumanMesh(int total) {
    final rng = math.Random(2027);
    final List<_HumanParticle> out = [];

    // ── HEAD (sphere) ─────────────────────────────────────────────────────────
    _addEllipsoid(out, rng,
        cx: 0, cy: 0.85, cz: 0,
        rx: 0.13, ry: 0.15, rz: 0.13,
        count: (total * 0.055).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.1,
        highlightFraction: true);

    // ── NECK ──────────────────────────────────────────────────────────────────
    _addCylinder(out, rng,
        x0: 0, y0: 0.70, z0: 0,
        x1: 0, y1: 0.74, z1: 0,
        r0: 0.055, r1: 0.065,
        count: (total * 0.014).round(),
        muscle: _MuscleGroup.neutral);

    // ── TORSO ─────────────────────────────────────────────────────────────────

    // Spine (core cylinder — neutral)
    _addCylinder(out, rng,
        x0: 0, y0: -0.28, z0: 0,
        x1: 0, y1: 0.70, z1: 0,
        r0: 0.01, r1: 0.01,
        count: (total * 0.008).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.2);

    // Chest / Pectorals — LEFT (big violet/pink slab)
    _addEllipsoid(out, rng,
        cx: -0.14, cy: 0.42, cz: 0.08,
        rx: 0.17, ry: 0.13, rz: 0.09,
        count: (total * 0.065).round(),
        muscle: _MuscleGroup.chest,
        brightnessBoost: 0.25,
        highlightFraction: true);

    // Chest / Pectorals — RIGHT
    _addEllipsoid(out, rng,
        cx: 0.14, cy: 0.42, cz: 0.08,
        rx: 0.17, ry: 0.13, rz: 0.09,
        count: (total * 0.065).round(),
        muscle: _MuscleGroup.chest,
        brightnessBoost: 0.25,
        highlightFraction: true);

    // Upper torso / ribcage body (neutral blue box fill)
    _addEllipsoid(out, rng,
        cx: 0, cy: 0.38, cz: 0,
        rx: 0.24, ry: 0.30, rz: 0.12,
        count: (total * 0.045).round(),
        muscle: _MuscleGroup.neutral);

    // Serratus anterior (side ribs, left)
    _addEllipsoid(out, rng,
        cx: -0.22, cy: 0.25, cz: 0.04,
        rx: 0.07, ry: 0.18, rz: 0.06,
        count: (total * 0.022).round(),
        muscle: _MuscleGroup.serratus,
        brightnessBoost: 0.15);

    // Serratus anterior (side ribs, right)
    _addEllipsoid(out, rng,
        cx: 0.22, cy: 0.25, cz: 0.04,
        rx: 0.07, ry: 0.18, rz: 0.06,
        count: (total * 0.022).round(),
        muscle: _MuscleGroup.serratus,
        brightnessBoost: 0.15);

    // Abdominals (6 individual muscle bellies)
    for (int row = 0; row < 3; row++) {
      final double abY = 0.12 - row * 0.13;
      for (final double side in [-0.065, 0.065]) {
        _addEllipsoid(out, rng,
            cx: side, cy: abY, cz: 0.10,
            rx: 0.055, ry: 0.055, rz: 0.04,
            count: (total * 0.010).round(),
            muscle: _MuscleGroup.neutral,
            brightnessBoost: 0.05);
      }
    }

    // Lower torso / waist
    _addEllipsoid(out, rng,
        cx: 0, cy: -0.18, cz: 0,
        rx: 0.18, ry: 0.09, rz: 0.10,
        count: (total * 0.025).round(),
        muscle: _MuscleGroup.neutral);

    // Hips / Gluteus
    _addEllipsoid(out, rng,
        cx: 0, cy: -0.32, cz: -0.02,
        rx: 0.21, ry: 0.09, rz: 0.12,
        count: (total * 0.025).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.05);

    // ── LEFT ARM ──────────────────────────────────────────────────────────────

    // Left anterior deltoid (front shoulder — engaged in pushups)
    _addEllipsoid(out, rng,
        cx: -0.33, cy: 0.60, cz: 0.04,
        rx: 0.09, ry: 0.09, rz: 0.09,
        count: (total * 0.030).round(),
        muscle: _MuscleGroup.shoulder,
        brightnessBoost: 0.3,
        highlightFraction: true);

    // Left lateral / posterior deltoid (neutral)
    _addEllipsoid(out, rng,
        cx: -0.33, cy: 0.58, cz: -0.04,
        rx: 0.085, ry: 0.085, rz: 0.085,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.1);

    // Left upper arm shaft (bicep side — neutral hue)
    _addCylinder(out, rng,
        x0: -0.33, y0: 0.51, z0: 0,
        x1: -0.33, y1: 0.18, z1: 0,
        r0: 0.075, r1: 0.060,
        count: (total * 0.022).round(),
        muscle: _MuscleGroup.neutral);

    // Left bicep peak
    _addEllipsoid(out, rng,
        cx: -0.33, cy: 0.36, cz: 0.07,
        rx: 0.07, ry: 0.10, rz: 0.055,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.15,
        highlightFraction: true);

    // Left tricep — ENGAGED (posterior upper arm)
    _addEllipsoid(out, rng,
        cx: -0.33, cy: 0.34, cz: -0.08,
        rx: 0.08, ry: 0.13, rz: 0.06,
        count: (total * 0.030).round(),
        muscle: _MuscleGroup.triceps,
        brightnessBoost: 0.25,
        highlightFraction: true);

    // Left elbow
    _addEllipsoid(out, rng,
        cx: -0.33, cy: 0.17, cz: 0,
        rx: 0.055, ry: 0.055, rz: 0.055,
        count: (total * 0.010).round(),
        muscle: _MuscleGroup.neutral);

    // Left forearm
    _addCylinder(out, rng,
        x0: -0.33, y0: 0.17, z0: 0,
        x1: -0.33, y1: -0.15, z1: 0.02,
        r0: 0.055, r1: 0.038,
        count: (total * 0.020).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.05);

    // Left wrist/hand
    _addEllipsoid(out, rng,
        cx: -0.33, cy: -0.17, cz: 0,
        rx: 0.045, ry: 0.05, rz: 0.04,
        count: (total * 0.010).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.2,
        highlightFraction: true);

    // ── RIGHT ARM ─────────────────────────────────────────────────────────────

    // Right anterior deltoid (ENGAGED)
    _addEllipsoid(out, rng,
        cx: 0.33, cy: 0.60, cz: 0.04,
        rx: 0.09, ry: 0.09, rz: 0.09,
        count: (total * 0.030).round(),
        muscle: _MuscleGroup.shoulder,
        brightnessBoost: 0.3,
        highlightFraction: true);

    // Right lateral / posterior deltoid (neutral)
    _addEllipsoid(out, rng,
        cx: 0.33, cy: 0.58, cz: -0.04,
        rx: 0.085, ry: 0.085, rz: 0.085,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.1);

    // Right upper arm shaft
    _addCylinder(out, rng,
        x0: 0.33, y0: 0.51, z0: 0,
        x1: 0.33, y1: 0.18, z1: 0,
        r0: 0.075, r1: 0.060,
        count: (total * 0.022).round(),
        muscle: _MuscleGroup.neutral);

    // Right bicep peak
    _addEllipsoid(out, rng,
        cx: 0.33, cy: 0.36, cz: 0.07,
        rx: 0.07, ry: 0.10, rz: 0.055,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.15,
        highlightFraction: true);

    // Right tricep — ENGAGED
    _addEllipsoid(out, rng,
        cx: 0.33, cy: 0.34, cz: -0.08,
        rx: 0.08, ry: 0.13, rz: 0.06,
        count: (total * 0.030).round(),
        muscle: _MuscleGroup.triceps,
        brightnessBoost: 0.25,
        highlightFraction: true);

    // Right elbow
    _addEllipsoid(out, rng,
        cx: 0.33, cy: 0.17, cz: 0,
        rx: 0.055, ry: 0.055, rz: 0.055,
        count: (total * 0.010).round(),
        muscle: _MuscleGroup.neutral);

    // Right forearm
    _addCylinder(out, rng,
        x0: 0.33, y0: 0.17, z0: 0,
        x1: 0.33, y1: -0.15, z1: 0.02,
        r0: 0.055, r1: 0.038,
        count: (total * 0.020).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.05);

    // Right wrist/hand
    _addEllipsoid(out, rng,
        cx: 0.33, cy: -0.17, cz: 0,
        rx: 0.045, ry: 0.05, rz: 0.04,
        count: (total * 0.010).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.2,
        highlightFraction: true);

    // ── LEFT LEG ──────────────────────────────────────────────────────────────

    // Left hip / gluteus (left side)
    _addEllipsoid(out, rng,
        cx: -0.11, cy: -0.34, cz: 0,
        rx: 0.10, ry: 0.09, rz: 0.09,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral);

    // Left quad / upper thigh (front)
    _addEllipsoid(out, rng,
        cx: -0.11, cy: -0.54, cz: 0.05,
        rx: 0.09, ry: 0.16, rz: 0.07,
        count: (total * 0.025).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.08);

    // Left hamstring (rear)
    _addEllipsoid(out, rng,
        cx: -0.11, cy: -0.53, cz: -0.06,
        rx: 0.08, ry: 0.14, rz: 0.06,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral);

    // Left knee
    _addEllipsoid(out, rng,
        cx: -0.11, cy: -0.70, cz: 0,
        rx: 0.065, ry: 0.065, rz: 0.065,
        count: (total * 0.010).round(),
        muscle: _MuscleGroup.neutral);

    // Left calf / shin
    _addCylinder(out, rng,
        x0: -0.11, y0: -0.70, z0: 0,
        x1: -0.11, y1: -0.96, z1: 0,
        r0: 0.055, r1: 0.035,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral);

    // Left foot
    _addEllipsoid(out, rng,
        cx: -0.11, cy: -0.99, cz: 0.05,
        rx: 0.04, ry: 0.03, rz: 0.09,
        count: (total * 0.008).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.1);

    // ── RIGHT LEG ─────────────────────────────────────────────────────────────

    _addEllipsoid(out, rng,
        cx: 0.11, cy: -0.34, cz: 0,
        rx: 0.10, ry: 0.09, rz: 0.09,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral);

    _addEllipsoid(out, rng,
        cx: 0.11, cy: -0.54, cz: 0.05,
        rx: 0.09, ry: 0.16, rz: 0.07,
        count: (total * 0.025).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.08);

    _addEllipsoid(out, rng,
        cx: 0.11, cy: -0.53, cz: -0.06,
        rx: 0.08, ry: 0.14, rz: 0.06,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral);

    _addEllipsoid(out, rng,
        cx: 0.11, cy: -0.70, cz: 0,
        rx: 0.065, ry: 0.065, rz: 0.065,
        count: (total * 0.010).round(),
        muscle: _MuscleGroup.neutral);

    _addCylinder(out, rng,
        x0: 0.11, y0: -0.70, z0: 0,
        x1: 0.11, y1: -0.96, z1: 0,
        r0: 0.055, r1: 0.035,
        count: (total * 0.018).round(),
        muscle: _MuscleGroup.neutral);

    _addEllipsoid(out, rng,
        cx: 0.11, cy: -0.99, cz: 0.05,
        rx: 0.04, ry: 0.03, rz: 0.09,
        count: (total * 0.008).round(),
        muscle: _MuscleGroup.neutral,
        brightnessBoost: 0.1);

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onPointerMove,
      child: Listener(
        onPointerMove: _onPointerMove,
        child: AnimatedBuilder(
          animation: _idleController,
          builder: (context, _) {
            _currentTiltX += (_targetTiltX - _currentTiltX) * 0.10;
            _currentTiltY += (_targetTiltY - _currentTiltY) * 0.10;
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _HumanPainter(
                particles: _particles,
                tiltX: _currentTiltX,
                tiltY: _currentTiltY,
                idleT: _idleController.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────────────────────

class _HumanPainter extends CustomPainter {
  final List<_HumanParticle> particles;
  final double tiltX, tiltY, idleT;

  late final double _cosX, _sinX, _cosY, _sinY;

  _HumanPainter({
    required this.particles,
    required this.tiltX,
    required this.tiltY,
    required this.idleT,
  }) {
    final double rx =
        (tiltX * math.pi / 180) + math.sin(idleT * math.pi * 2) * 0.04;
    final double ry =
        (tiltY * math.pi / 180) + math.cos(idleT * math.pi * 2) * 0.06;
    _cosX = math.cos(rx);
    _sinX = math.sin(rx);
    _cosY = math.cos(ry);
    _sinY = math.sin(ry);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    // Scale so the full body (≈ 2 units tall) fills ~90% of the canvas height
    final double scaleFactor = size.height * 0.44;

    // Ambient background halo
    final glowPaint = Paint()
      ..shader = RadialGradient(colors: [
        _kBlueGlow.withValues(alpha: 0.18),
        _kVioletDeep.withValues(alpha: 0.08),
        Colors.transparent,
      ]).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.55));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55, glowPaint);

    // Project all particles
    final List<_ProjectedParticle> projected = [];

    for (final p in particles) {
      // Rotate around X then Y
      final double y1 = p.y * _cosX - p.z * _sinX;
      final double z1 = p.y * _sinX + p.z * _cosX;

      final double x2 = p.x * _cosY + z1 * _sinY;
      final double z2 = -p.x * _sinY + z1 * _cosY;

      // Perspective projection
      const double fov = 3.5;
      final double persp = fov / (fov + z2);
      final double sx = cx + x2 * scaleFactor * persp;
      // +Y = up in model → -Y on screen
      final double sy = cy - y1 * scaleFactor * persp;

      final double depthFactor = (z2 + 1.0) * 0.5;
      final double shimmer = 0.65 + 0.35 * math.sin(
          p.shimmerPhase + idleT * math.pi * 5 + depthFactor * math.pi);
      final double alpha =
          (p.brightness * (0.25 + 0.75 * depthFactor) * shimmer)
              .clamp(0.0, 1.0);
      final double pSize =
          p.baseSize * persp * (0.45 + depthFactor * 0.55);

      projected.add(_ProjectedParticle(
        sx: sx,
        sy: sy,
        wz: z2,
        alpha: alpha,
        size: pSize,
        depthFactor: depthFactor,
        muscle: p.muscle,
        isHighlight: p.isHighlight,
      ));
    }

    // Depth sort — back to front (painter's algorithm)
    projected.sort((a, b) => a.wz.compareTo(b.wz));

    final paintObj = Paint();

    for (final pp in projected) {
      if (pp.alpha < 0.025) continue;

      final bool engaged = pp.muscle != _MuscleGroup.neutral;

      Color col;
      if (engaged) {
        // Violet → pink gradient by depth
        if (pp.isHighlight) {
          col = Color.lerp(_kVioletDeep, _kPinkGlow, pp.depthFactor)!;
        } else {
          col = Color.lerp(_kVioletMid, _kPinkBright, pp.depthFactor)!;
        }
      } else {
        if (pp.isHighlight) {
          col = Color.lerp(_kBlueMid, Colors.white, pp.depthFactor)!;
        } else {
          col = Color.lerp(_kBlueDeep, _kBlueBright, pp.depthFactor)!;
        }
      }

      final Offset pt = Offset(pp.sx, pp.sy);

      // Glow aura for larger / front particles
      if (pp.size > 1.2 && pp.depthFactor > 0.25) {
        paintObj
          ..color = col.withValues(alpha: pp.alpha * 0.40)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pp.size * 1.8);
        canvas.drawCircle(pt, pp.size * 2.2, paintObj);
        paintObj.maskFilter = null;
      }

      // Core dot
      paintObj.color = col.withValues(alpha: pp.alpha);
      canvas.drawCircle(pt, pp.size, paintObj);
    }
  }

  @override
  bool shouldRepaint(_HumanPainter old) =>
      old.tiltX != tiltX || old.tiltY != tiltY || old.idleT != idleT;
}
