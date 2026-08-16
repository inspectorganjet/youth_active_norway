import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color Palette
// ─────────────────────────────────────────────────────────────────────────────
const Color _kRobotBlue = Color(0xFF0446BC);
const Color _kRobotCyan = Color(0xFF38BDF8);
const Color _kRobotWhite = Color(0xFFFFFFFF);
const Color _kRobotGlow = Color(0xFF60A5FA);

// ─────────────────────────────────────────────────────────────────────────────
// Struct for Robot particles
// ─────────────────────────────────────────────────────────────────────────────
class _RobotParticle {
  final double x;
  final double y;
  final double z;
  final double size;
  final Color color;
  final double alpha;
  final bool isEye;
  final bool isMouth;
  final bool isAntenna;

  const _RobotParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.color,
    required this.alpha,
    this.isEye = false,
    this.isMouth = false,
    this.isAntenna = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// 3D Particle Robot Model matching the user's flat robot icon geometry.
class ParticleRobotModel extends StatefulWidget {
  final double size;
  final bool enableTilt;

  const ParticleRobotModel({
    super.key,
    this.size = 140.0,
    this.enableTilt = true,
  });

  @override
  State<ParticleRobotModel> createState() => _ParticleRobotModelState();
}

class _ParticleRobotModelState extends State<ParticleRobotModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late List<_RobotParticle> _particles;

  double _smoothTiltX = 0.0;
  double _smoothTiltY = 0.0;

  static const int _kParticleCount = 1800;

  @override
  void initState() {
    super.initState();
    _particles = _buildRobotMesh(_kParticleCount);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // 3D Particle Mesh Generator for Robot head from image reference
  static List<_RobotParticle> _buildRobotMesh(int total) {
    final rng = math.Random(777);
    final list = <_RobotParticle>[];

    void addP(double x, double y, double z, Color col,
        {double sizeMult = 1.0, double alpha = 0.85, bool eye = false, bool mouth = false, bool ant = false}) {
      list.add(_RobotParticle(
        x: x,
        y: y,
        z: z,
        size: (1.2 + rng.nextDouble() * 1.0) * sizeMult,
        color: col,
        alpha: alpha,
        isEye: eye,
        isMouth: mouth,
        isAntenna: ant,
      ));
    }

    // 1. Antenna Knob at Top Center (Semi-sphere)
    for (int i = 0; i < 90; i++) {
      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);
      final r = 0.16 * math.pow(rng.nextDouble(), 0.5);
      addP(
        r * math.sin(phi) * math.cos(theta),
        -0.82 + r * math.cos(phi),
        r * math.sin(phi) * math.sin(theta),
        _kRobotBlue,
        ant: true,
        sizeMult: 1.2,
      );
    }

    // 2. Ear Knobs (Left & Right protruding ears)
    for (int i = 0; i < 220; i++) {
      final isRight = i % 2 == 0;
      final side = isRight ? 1.0 : -1.0;

      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final phi = math.acos(2.0 * v - 1.0);
      final r = 0.16 * math.pow(rng.nextDouble(), 0.5);

      final ex = side * 0.70 + r * math.sin(phi) * math.cos(theta);
      final ey = -0.20 + r * math.cos(phi);
      final ez = r * math.sin(phi) * math.sin(theta);

      addP(ex, ey, ez, _kRobotBlue, sizeMult: 1.1);
    }

    // 3. Main Rounded Square Head Block
    for (int i = 0; i < 1150; i++) {
      final u = (rng.nextDouble() - 0.5) * 1.20; // width -0.6 to 0.6
      final v = (rng.nextDouble() - 0.5) * 0.95; // height -0.47 to 0.47
      final w = (rng.nextDouble() - 0.5) * 0.60; // depth -0.3 to 0.3

      // Rounded corners filter
      final cornerDistX = math.max(0.0, u.abs() - 0.42);
      final cornerDistY = math.max(0.0, v.abs() - 0.30);
      if (cornerDistX * cornerDistX + cornerDistY * cornerDistY > 0.04) continue;

      final isEdge = u.abs() > 0.50 || v.abs() > 0.40 || w.abs() > 0.22;
      final col = isEdge
          ? Color.lerp(_kRobotBlue, _kRobotCyan, rng.nextDouble())!
          : _kRobotBlue;

      addP(u, v - 0.18, w, col);
    }

    // 4. Two Glowing White Eyes (Flat circular particle disks)
    for (int i = 0; i < 180; i++) {
      final isRight = i % 2 == 0;
      final side = isRight ? 1.0 : -1.0;

      final u = rng.nextDouble();
      final v = rng.nextDouble();
      final theta = u * 2.0 * math.pi;
      final r = 0.12 * math.sqrt(v);

      final eyeX = side * 0.26 + r * math.cos(theta);
      final eyeY = -0.24 + r * math.sin(theta);
      final eyeZ = 0.32; // In front of head surface

      addP(eyeX, eyeY, eyeZ, _kRobotWhite, eye: true, sizeMult: 1.4, alpha: 1.0);
    }

    // 5. White Slot Mouth (Horizontal capsule)
    for (int i = 0; i < 160; i++) {
      final mx = (rng.nextDouble() - 0.5) * 0.36;
      final my = -0.01 + (rng.nextDouble() - 0.5) * 0.08;
      final mz = 0.32;

      addP(mx, my, mz, _kRobotWhite, mouth: true, sizeMult: 1.3, alpha: 1.0);
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final painterWidget = AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RobotPainter(
            particles: _particles,
            progress: _anim.value,
            tiltX: _smoothTiltX,
            tiltY: _smoothTiltY,
          ),
        );
      },
    );

    if (!widget.enableTilt) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: painterWidget,
      );
    }

    return Tilt(
      tiltConfig: const TiltConfig(
        angle: 20.0,
        enableRevert: true,
        enableSensorRevert: true,
        leaveDuration: Duration(milliseconds: 800),
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
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: painterWidget,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _RobotPainter extends CustomPainter {
  final List<_RobotParticle> particles;
  final double progress;
  final double tiltX;
  final double tiltY;

  _RobotPainter({
    required this.particles,
    required this.progress,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final scale = size.width * 0.44;

    // Smooth head breathing rotation + tilt
    final double yaw = math.sin(progress * math.pi * 2) * 0.12 + (tiltX * 0.50);
    final double pitch = math.sin(progress * math.pi * 2 * 0.5) * 0.04 + (tiltY * 0.35);

    final cosY = math.cos(yaw), sinY = math.sin(yaw);
    final cosX = math.cos(pitch), sinX = math.sin(pitch);

    // Soft Ambient Blue Aura behind Robot
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kRobotBlue.withValues(alpha: 0.28),
          _kRobotCyan.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.52));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.52, auraPaint);

    // Project and Depth Sort Robot Particles
    final renderList = <({double sx, double sy, double z, double ps, Color color, double alpha, bool isEye})>[];

    for (final p in particles) {
      final floatY = p.y + math.sin(progress * math.pi * 2 + p.x * 2.0) * 0.015;

      final x1 = p.x * cosY + p.z * sinY;
      final z1 = -p.x * sinY + p.z * cosY;
      final y2 = floatY * cosX - z1 * sinX;
      final z2 = floatY * sinX + z1 * cosX;

      const fov = 3.2;
      final persp = fov / (fov + z2 * 0.45);
      final sx = cx + x1 * scale * persp;
      final sy = cy + y2 * scale * persp;

      renderList.add((
        sx: sx,
        sy: sy,
        z: z2,
        ps: p.size * persp,
        color: p.color,
        alpha: p.alpha,
        isEye: p.isEye,
      ));
    }

    renderList.sort((a, b) => a.z.compareTo(b.z));

    final paintObj = Paint();
    for (final r in renderList) {
      if (r.alpha < 0.02) continue;
      final offset = Offset(r.sx, r.sy);

      // Glow behind glowing white eyes
      if (r.isEye) {
        paintObj
          ..color = _kRobotGlow.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(offset, r.ps * 1.8, paintObj);
        paintObj.maskFilter = null;
      }

      paintObj.color = r.color.withValues(alpha: r.alpha);
      canvas.drawCircle(offset, r.ps, paintObj);
    }
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.progress != progress ||
      old.tiltX != tiltX ||
      old.tiltY != tiltY;
}
