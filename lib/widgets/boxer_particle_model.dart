import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

enum _MuscleGroup {
  neutral, // Neon cyan/blue body
  boxingGlove, // Glowing fiery red/gold boxing gloves
  shoulders, // Neon magenta/purple shoulders & arms
  core, // Core & hips
}

class _BoxerParticle {
  final double x, y, z;
  final double baseSize;
  final double shimmerPhase;
  final double brightness;
  final _MuscleGroup muscle;
  final bool isHighlight;

  const _BoxerParticle({
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

class BoxerParticleModel extends StatefulWidget {
  final double size;
  final bool isPunching;

  const BoxerParticleModel({
    super.key,
    this.size = 220.0,
    this.isPunching = true,
  });

  @override
  State<BoxerParticleModel> createState() => _BoxerParticleManagerState();
}

class _BoxerParticleManagerState extends State<BoxerParticleModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  final List<_BoxerParticle> _particles = [];

  // Smooth tilt values for gyro and gesture interaction
  double _smoothTiltX = 0.0;
  double _smoothTiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _buildParticles();
  }

  void _buildParticles() {
    final rng = math.Random(101);
    final list = <_BoxerParticle>[];

    void addP(double x, double y, double z, _MuscleGroup m,
        {bool isHighlight = false, double szMult = 1.0}) {
      list.add(_BoxerParticle(
        x: x,
        y: y,
        z: z,
        baseSize: (rng.nextDouble() * 1.5 + 1.2) * szMult,
        shimmerPhase: rng.nextDouble() * math.pi * 2,
        brightness: 0.6 + rng.nextDouble() * 0.4,
        muscle: m,
        isHighlight: isHighlight,
      ));
    }

    // 1. Head & Guard Helmet (Spherical cloud around head)
    for (int i = 0; i < 220; i++) {
      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);
      final r = 0.22 * math.pow(rng.nextDouble(), 0.3);
      addP(
        r * math.sin(phi) * math.cos(theta),
        -0.85 + r * math.cos(phi),
        r * math.sin(phi) * math.sin(theta),
        _MuscleGroup.neutral,
      );
    }

    // 2. Torso / Chest / Core
    for (int i = 0; i < 600; i++) {
      final y = -0.65 + rng.nextDouble() * 0.7;
      final widthFactor = (1.0 - (y + 0.65) * 0.3) * 0.45;
      final r = rng.nextDouble() * widthFactor;
      final angle = rng.nextDouble() * math.pi * 2;
      addP(
        r * math.cos(angle),
        y,
        r * math.sin(angle),
        _MuscleGroup.core,
      );
    }

    // 3. Shoulders & Arms
    for (int i = 0; i < 400; i++) {
      final side = rng.nextBool() ? 1.0 : -1.0;
      final armProgress = rng.nextDouble();
      final armX = side * (0.2 + armProgress * 0.3);
      final armY = -0.5 + armProgress * 0.4;
      final armZ = 0.1 + armProgress * 0.3;

      final noiseX = (rng.nextDouble() - 0.5) * 0.15;
      final noiseY = (rng.nextDouble() - 0.5) * 0.15;
      final noiseZ = (rng.nextDouble() - 0.5) * 0.15;

      addP(
        armX + noiseX,
        armY + noiseY,
        armZ + noiseZ,
        _MuscleGroup.shoulders,
      );
    }

    // 4. Boxing Gloves (Dense glowing spheres in front)
    for (int i = 0; i < 300; i++) {
      final isRight = i % 2 == 0;
      final side = isRight ? 1.0 : -1.0;

      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);
      final r = 0.16 * rng.nextDouble();

      final gx = side * 0.28 + r * math.sin(phi) * math.cos(theta);
      final gy = -0.22 + r * math.cos(phi);
      final gz = 0.5 + r * math.sin(phi) * math.sin(theta);

      addP(
        gx,
        gy,
        gz,
        _MuscleGroup.boxingGlove,
        isHighlight: rng.nextDouble() > 0.65,
        szMult: 1.3,
      );
    }

    _particles.addAll(list);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tilt(
      tiltConfig: const TiltConfig(
        angle: 22.0,
        enableRevert: true,
        enableSensorRevert: true,
        leaveDuration: Duration(milliseconds: 900),
        leaveCurve: Curves.easeOutCubic,
      ),
      shadowConfig: const ShadowConfig(disable: true),
      lightConfig: const LightConfig(disable: true),
      onGestureMove: (model, gestureType) {
        if (mounted) {
          setState(() {
            _smoothTiltX = _smoothTiltX + (model.areaProgress.dx - _smoothTiltX) * 0.25;
            _smoothTiltY = _smoothTiltY + (model.areaProgress.dy - _smoothTiltY) * 0.25;
          });
        }
      },
      onGestureLeave: (_, gestureType) {
        if (mounted) {
          setState(() {
            _smoothTiltX = 0.0;
            _smoothTiltY = 0.0;
          });
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BoxerPainter(
              particles: _particles,
              time: _anim.value,
              isPunching: widget.isPunching,
              tiltX: _smoothTiltX,
              tiltY: _smoothTiltY,
            ),
          );
        },
      ),
    );
  }
}

class _BoxerPainter extends CustomPainter {
  final List<_BoxerParticle> particles;
  final double time;
  final bool isPunching;
  final double tiltX;
  final double tiltY;

  _BoxerPainter({
    required this.particles,
    required this.time,
    required this.isPunching,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final scale = size.width * 0.42;

    // Combined smooth rotation from animation + gyroscope / gesture tilt
    final rotY = math.sin(time * math.pi * 2) * 0.15 + (tiltX * 0.55);
    final rotX = (tiltY * 0.40);
    final punchOffset = isPunching ? math.sin(time * math.pi * 8).abs() * 0.25 : 0.0;

    final cosY = math.cos(rotY), sinY = math.sin(rotY);
    final cosX = math.cos(rotX), sinX = math.sin(rotX);

    final renderList = <({double sx, double sy, double z, double ps, Color color, double alpha, bool isHighlight})>[];

    for (final p in particles) {
      double px = p.x;
      double py = p.y;
      double pz = p.z;

      // Extend glove on punch
      if (p.muscle == _MuscleGroup.boxingGlove) {
        pz += punchOffset;
      }

      // Rotate around Y (Yaw) and X (Pitch)
      final x1 = px * cosY + pz * sinY;
      final z1 = -px * sinY + pz * cosY;
      final y2 = py * cosX - z1 * sinX;
      final z2 = py * sinX + z1 * cosX;

      // Perspective projection
      final perspective = 1.0 / (1.0 - z2 * 0.4);
      final sx = cx + x1 * scale * perspective;
      final sy = cy + y2 * scale * perspective;

      // Colors
      Color c;
      if (p.muscle == _MuscleGroup.boxingGlove) {
        c = const Color(0xFFEF4444); // Glowing Boxing Glove Red
      } else if (p.muscle == _MuscleGroup.shoulders) {
        c = const Color(0xFFEC4899); // Pink/Purple shoulder
      } else if (p.muscle == _MuscleGroup.core) {
        c = const Color(0xFF3B82F6); // Electric Blue
      } else {
        c = const Color(0xFF06B6D4); // Neon Cyan
      }

      final shimmer = math.sin(time * math.pi * 4 + p.shimmerPhase) * 0.2 + 0.8;
      final alpha = (p.brightness * shimmer * perspective).clamp(0.1, 1.0);
      final pSize = p.baseSize * perspective * (p.isHighlight ? 1.4 : 1.0);

      renderList.add((
        sx: sx,
        sy: sy,
        z: z2,
        ps: pSize,
        color: c,
        alpha: alpha,
        isHighlight: p.isHighlight,
      ));
    }

    // Sort particles by depth for correct 3D overlap
    renderList.sort((a, b) => a.z.compareTo(b.z));

    for (final r in renderList) {
      final paint = Paint()
        ..color = r.color.withValues(alpha: r.alpha)
        ..style = PaintingStyle.fill;

      final offset = Offset(r.sx, r.sy);
      canvas.drawCircle(offset, r.ps, paint);

      // Glow effect for gloves
      if (r.isHighlight) {
        final glowPaint = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35 * r.alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(offset, r.ps * 2.2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoxerPainter oldDelegate) => true;
}
