import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A 3D flexed arm model (large bicep, tricep, forearm & shoulder) composed
/// of 2300 bright glowing particles.
///
/// Reacts to phone tilt (accelerometer/gyroscope) and mouse hover by bending /
/// tilting smoothly in 3D space.
class BicepParticleArm extends StatefulWidget {
  /// Bounding size of the square canvas (e.g. 140 or 180).
  final double size;

  /// Optional flex progress (0.0 = relaxed, 1.0 = peak flex).
  final double flexProgress;

  const BicepParticleArm({
    super.key,
    this.size = 140,
    this.flexProgress = 1.0,
  });

  @override
  State<BicepParticleArm> createState() => _BicepParticleArmState();
}

class _BicepParticleArmState extends State<BicepParticleArm>
    with SingleTickerProviderStateMixin {
  // ─── Sensor subscriptions ────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;
  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;

  // Ticker for idle shimmer / subtle flex movement
  late AnimationController _idleController;

  // 2300 bright particles forming the 3D flexed arm model
  late List<_ArmParticle> _particles;
  static const int _kParticleCount = 2300;

  @override
  void initState() {
    super.initState();
    _particles = _generate3DArmMesh(_kParticleCount);

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initSensors();
  }

  void _initSensors() {
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (AccelerometerEvent e) {
          if (!mounted) return;
          final double pitch = (e.y * 5.0).clamp(-45.0, 45.0);
          final double roll = (-e.x * 5.0).clamp(-45.0, 45.0);
          _targetTiltX = pitch;
          _targetTiltY = roll;
        },
        onError: (_) {},
      );
    } catch (_) {}

    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (GyroscopeEvent e) {
          if (!mounted) return;
          _targetTiltX = (_targetTiltX + e.x * 2.5).clamp(-55.0, 55.0);
          _targetTiltY = (_targetTiltY + e.y * 2.5).clamp(-55.0, 55.0);
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _idleController.dispose();
    super.dispose();
  }

  /// Parametric 3D Volumetric Flexed Arm Mesh Generator (2300 particles)
  /// Represents:
  ///   1. Shoulder / Deltoid (rounded sphere cap at origin)
  ///   2. Upper Arm shaft (cylinder between shoulder & elbow)
  ///   3. Large Bicep Peak (prominent ellipsoid bulge on front of upper arm)
  ///   4. Tricep Muscle (elongated muscle bulge on back of upper arm)
  ///   5. Elbow Joint (hinge sphere)
  ///   6. Forearm (tapered cylinder extending up at ~60° flex angle)
  ///   7. Fist / Wrist (dense compact cluster at top end)
  static List<_ArmParticle> _generate3DArmMesh(int count) {
    final rng = math.Random(2026);
    final List<_ArmParticle> list = [];

    // Distribution weights across muscle groups
    final int shoulderCount = (count * 0.14).round();
    final int upperArmShaftCount = (count * 0.16).round();
    final int bicepPeakCount = (count * 0.28).round(); // Big bicep focus!
    final int tricepCount = (count * 0.16).round(); // Tricep
    final int elbowCount = (count * 0.06).round();
    final int forearmCount = (count * 0.16).round();
    final int fistCount = count - (shoulderCount + upperArmShaftCount + bicepPeakCount + tricepCount + elbowCount + forearmCount);

    // ── 1. Shoulder / Deltoid (Sphere at origin [0, -0.6, 0]) ────────────────
    for (int i = 0; i < shoulderCount; i++) {
      final double u = rng.nextDouble();
      final double v = rng.nextDouble();
      final double theta = u * 2.0 * math.pi;
      final double phi = math.acos(2.0 * v - 1.0);

      final double r = 0.28 * (0.8 + 0.2 * rng.nextDouble());
      final double x = r * math.sin(phi) * math.cos(theta) - 0.4;
      final double y = r * math.sin(phi) * math.sin(theta) + 0.45;
      final double z = r * math.cos(phi);

      list.add(_createParticle(x, y, z, rng, brightnessBoost: 0.15));
    }

    // ── 2. Upper Arm Shaft (from Shoulder [-0.4, 0.45] to Elbow [0.0, 0.4]) ──
    for (int i = 0; i < upperArmShaftCount; i++) {
      final double t = rng.nextDouble(); // 0 -> 1 along upper arm axis
      final double angle = rng.nextDouble() * 2.0 * math.pi;

      final double startX = -0.35, startY = 0.4;
      final double endX = 0.0, endY = 0.35;

      final double cx = startX + (endX - startX) * t;
      final double cy = startY + (endY - startY) * t;
      final double radius = 0.20 + 0.04 * math.sin(t * math.pi);

      final double x = cx + radius * math.cos(angle) * (0.8 + 0.2 * rng.nextDouble());
      final double y = cy;
      final double z = radius * math.sin(angle) * (0.8 + 0.2 * rng.nextDouble());

      list.add(_createParticle(x, y, z, rng));
    }

    // ── 3. LARGE BICEP PEAK (Ellipsoid on top of upper arm) ──────────────────
    for (int i = 0; i < bicepPeakCount; i++) {
      // Bicep center around [-0.18, 0.22, 0.05]
      final double u = rng.nextDouble();
      final double v = rng.nextDouble();
      final double theta = u * 2.0 * math.pi;
      final double phi = math.acos(2.0 * v - 1.0);

      // Pronounced egg/bulge dimensions
      final double rx = 0.30 * (0.75 + 0.25 * rng.nextDouble()); // Length along arm
      final double ry = 0.26 * (0.75 + 0.25 * rng.nextDouble()); // Height (BIG PEAK!)
      final double rz = 0.24 * (0.75 + 0.25 * rng.nextDouble()); // Thickness

      final double x = -0.18 + rx * math.sin(phi) * math.cos(theta);
      final double y = 0.22 + ry * math.cos(phi); // Bulges upward
      final double z = 0.05 + rz * math.sin(phi) * math.sin(theta);

      list.add(_createParticle(x, y, z, rng, brightnessBoost: 0.25, isHighlight: rng.nextDouble() > 0.65));
    }

    // ── 4. TRICEP MUSCLE (Ellipsoid underneath upper arm) ────────────────────
    for (int i = 0; i < tricepCount; i++) {
      final double u = rng.nextDouble();
      final double v = rng.nextDouble();
      final double theta = u * 2.0 * math.pi;
      final double phi = math.acos(2.0 * v - 1.0);

      final double rx = 0.28 * (0.7 + 0.3 * rng.nextDouble());
      final double ry = 0.20 * (0.7 + 0.3 * rng.nextDouble());
      final double rz = 0.22 * (0.7 + 0.3 * rng.nextDouble());

      final double x = -0.18 + rx * math.sin(phi) * math.cos(theta);
      final double y = 0.52 + ry * math.cos(phi); // Bulges downward/back
      final double z = -0.05 + rz * math.sin(phi) * math.sin(theta);

      list.add(_createParticle(x, y, z, rng));
    }

    // ── 5. Elbow Joint (Sphere at [0.0, 0.38, 0]) ───────────────────────────
    for (int i = 0; i < elbowCount; i++) {
      final double u = rng.nextDouble();
      final double v = rng.nextDouble();
      final double theta = u * 2.0 * math.pi;
      final double phi = math.acos(2.0 * v - 1.0);
      final double r = 0.16 * (0.8 + 0.2 * rng.nextDouble());

      final double x = r * math.sin(phi) * math.cos(theta);
      final double y = 0.38 + r * math.cos(phi);
      final double z = r * math.sin(phi) * math.sin(theta);

      list.add(_createParticle(x, y, z, rng));
    }

    // ── 6. Forearm (Extending from Elbow [0, 0.38] UP towards Wrist [0.38, -0.22]) ──
    for (int i = 0; i < forearmCount; i++) {
      final double t = rng.nextDouble(); // 0 -> 1 along forearm
      final double angle = rng.nextDouble() * 2.0 * math.pi;

      final double startX = 0.0, startY = 0.38;
      final double endX = 0.36, endY = -0.22;

      final double cx = startX + (endX - startX) * t;
      final double cy = startY + (endY - startY) * t;

      // Forearm taper (thicker near elbow, slightly narrower near wrist)
      final double radius = (0.19 - 0.06 * t) * (0.8 + 0.2 * rng.nextDouble());

      // Perpendicular vector for tube
      final double x = cx + radius * math.cos(angle);
      final double y = cy + radius * math.sin(angle) * 0.5;
      final double z = radius * math.sin(angle);

      list.add(_createParticle(x, y, z, rng, brightnessBoost: 0.1));
    }

    // ── 7. Clenched Fist (Cluster at top end [0.38, -0.25, 0.0]) ─────────────
    for (int i = 0; i < fistCount; i++) {
      final double u = rng.nextDouble();
      final double v = rng.nextDouble();
      final double theta = u * 2.0 * math.pi;
      final double phi = math.acos(2.0 * v - 1.0);
      final double r = 0.17 * (0.75 + 0.25 * rng.nextDouble());

      final double x = 0.38 + r * math.sin(phi) * math.cos(theta);
      final double y = -0.25 + r * math.cos(phi);
      final double z = r * math.sin(phi) * math.sin(theta);

      list.add(_createParticle(x, y, z, rng, brightnessBoost: 0.3, isHighlight: true));
    }

    return list;
  }

  static _ArmParticle _createParticle(
    double x,
    double y,
    double z,
    math.Random rng, {
    double brightnessBoost = 0.0,
    bool isHighlight = false,
  }) {
    final double size = isHighlight ? (2.2 + rng.nextDouble() * 1.8) : (0.8 + rng.nextDouble() * 2.0);
    final double phase = rng.nextDouble() * math.pi * 2;
    final double brightness = (0.55 + rng.nextDouble() * 0.45 + brightnessBoost).clamp(0.0, 1.0);

    return _ArmParticle(
      x: x,
      y: y,
      z: z,
      baseSize: size,
      shimmerPhase: phase,
      brightness: brightness,
      isHighlight: isHighlight,
    );
  }

  void _onPointerMove(PointerEvent event) {
    final double dx = (event.localPosition.dx - widget.size / 2) / (widget.size / 2);
    final double dy = (event.localPosition.dy - widget.size / 2) / (widget.size / 2);

    setState(() {
      _targetTiltY = dx * 35.0;
      _targetTiltX = -dy * 35.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onPointerMove,
      child: Listener(
        onPointerMove: _onPointerMove,
        child: AnimatedBuilder(
          animation: _idleController,
          builder: (context, child) {
            _currentTiltX += (_targetTiltX - _currentTiltX) * 0.12;
            _currentTiltY += (_targetTiltY - _currentTiltY) * 0.12;

            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ArmPainter(
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

class _ArmParticle {
  final double x, y, z;
  final double baseSize;
  final double shimmerPhase;
  final double brightness;
  final bool isHighlight;

  const _ArmParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.baseSize,
    required this.shimmerPhase,
    required this.brightness,
    required this.isHighlight,
  });
}

class _ArmPainter extends CustomPainter {
  final List<_ArmParticle> particles;
  final double tiltX; // degrees
  final double tiltY; // degrees
  final double idleT;

  late final double _cosX, _sinX, _cosY, _sinY;

  _ArmPainter({
    required this.particles,
    required this.tiltX,
    required this.tiltY,
    required this.idleT,
  }) {
    // Combine phone tilt + subtle idle breathing angle
    final double rx = (tiltX * math.pi / 180) + math.sin(idleT * math.pi * 2) * 0.06;
    final double ry = (tiltY * math.pi / 180) + math.cos(idleT * math.pi * 2) * 0.08;

    _cosX = math.cos(rx);
    _sinX = math.sin(rx);
    _cosY = math.cos(ry);
    _sinY = math.sin(ry);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double scaleFactor = size.width * 0.72;

    // Ambient background halo glow behind arm
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.22),
          const Color(0xFF1D4ED8).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.6));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.6, glowPaint);

    // Project and render 2300 particles
    final List<_ProjectedArmParticle> projected = [];

    for (final p in particles) {
      // 3D Rotation (Rx then Ry)
      double y1 = p.y * _cosX - p.z * _sinX;
      double z1 = p.y * _sinX + p.z * _cosX;

      double x2 = p.x * _cosY + z1 * _sinY;
      double z2 = -p.x * _sinY + z1 * _cosY;

      final double wx = x2;
      final double wy = y1;
      final double wz = z2;

      // Perspective projection
      final double fov = 3.0;
      final double scale = fov / (fov + wz);
      final double sx = cx + wx * scaleFactor * scale;
      final double sy = cy + wy * scaleFactor * scale;

      final double depthFactor = (wz + 1.0) * 0.5; // 0 (back) ... 1 (front)
      final double shimmer = 0.7 + 0.3 * math.sin(p.shimmerPhase + idleT * math.pi * 4 + depthFactor * math.pi);
      final double alpha = (p.brightness * (0.3 + 0.7 * depthFactor) * shimmer).clamp(0.0, 1.0);
      final double pSize = p.baseSize * scale * (0.5 + depthFactor * 0.5);

      projected.add(_ProjectedArmParticle(
        sx: sx,
        sy: sy,
        wz: wz,
        alpha: alpha,
        size: pSize,
        depthFactor: depthFactor,
        isHighlight: p.isHighlight,
      ));
    }

    // Depth sorting (back-to-front)
    projected.sort((a, b) => a.wz.compareTo(b.wz));

    final paintObj = Paint();

    for (final pp in projected) {
      if (pp.alpha < 0.03) continue;

      // Color scheme: Bright Ice Blue & Platinum White (lyse partikler)
      Color particleColor;
      if (pp.isHighlight) {
        particleColor = Color.lerp(
          const Color(0xFFBAE6FD), // Light Cyan
          Colors.white, // Ultra Bright White
          pp.depthFactor,
        )!;
      } else {
        particleColor = Color.lerp(
          const Color(0xFF38BDF8), // Electric Cyan
          const Color(0xFFF8FAFC), // Bright Platinum
          pp.depthFactor,
        )!;
      }

      final Offset pt = Offset(pp.sx, pp.sy);

      // Particle aura glow
      if (pp.size > 1.3 && pp.depthFactor > 0.3) {
        paintObj
          ..color = particleColor.withValues(alpha: pp.alpha * 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pp.size * 1.5);
        canvas.drawCircle(pt, pp.size * 2.0, paintObj);
        paintObj.maskFilter = null;
      }

      // Core particle dot
      paintObj.color = particleColor.withValues(alpha: pp.alpha);
      canvas.drawCircle(pt, pp.size, paintObj);
    }
  }

  @override
  bool shouldRepaint(_ArmPainter old) =>
      old.tiltX != tiltX || old.tiltY != tiltY || old.idleT != idleT;
}

class _ProjectedArmParticle {
  final double sx, sy, wz, alpha, size, depthFactor;
  final bool isHighlight;
  const _ProjectedArmParticle({
    required this.sx,
    required this.sy,
    required this.wz,
    required this.alpha,
    required this.size,
    required this.depthFactor,
    required this.isHighlight,
  });
}
