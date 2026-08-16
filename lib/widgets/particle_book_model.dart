import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color Palette
// ─────────────────────────────────────────────────────────────────────────────
const Color _kPagesGold = Color(0xFFFFD740);
const Color _kCoverCyan = Color(0xFF00E5FF);
const Color _kIqGold = Color(0xFFFFAB00);
const Color _kIqWhite = Color(0xFFFFFFFF);
const Color _kSpineBlue = Color(0xFF2979FF);

// ─────────────────────────────────────────────────────────────────────────────
// Helper structs
// ─────────────────────────────────────────────────────────────────────────────

class _BookParticle {
  final double x;
  final double y;
  final double z;
  final double size;
  final Color color;
  final double alpha;
  final double shimmer;

  const _BookParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.color,
    required this.alpha,
    required this.shimmer,
  });
}

class _FloatingIqText {
  final double startX;
  final double startY;
  final double speed;
  final double scale;
  final double phaseOffset;

  const _FloatingIqText({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.scale,
    required this.phaseOffset,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// 3D Particle Open Book with interactive tilt / gyro reaction & rising "IQ" particles.
class ParticleBookModel extends StatefulWidget {
  final double size;

  /// Whether reading session is active (triggers rising IQ particles)
  final bool isReading;

  const ParticleBookModel({
    super.key,
    this.size = 240.0,
    this.isReading = false,
  });

  @override
  State<ParticleBookModel> createState() => _ParticleBookModelState();
}

class _ParticleBookModelState extends State<ParticleBookModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late List<_BookParticle> _bookParticles;
  late List<_FloatingIqText> _iqItems;

  // Real-time tilt offsets driven by mouse/touch or phone gyroscope sensors
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Smoothed tilt offsets for silky movement
  double _smoothTiltX = 0.0;
  double _smoothTiltY = 0.0;

  static const int _kBookParticleCount = 4500;
  static const int _kIqItemCount = 12;

  @override
  void initState() {
    super.initState();
    _bookParticles = _buildBookMesh(_kBookParticleCount);
    _iqItems = _buildIqItems(_kIqItemCount);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // Generate 3D Open Book structure out of 4,500 particles
  static List<_BookParticle> _buildBookMesh(int total) {
    final rng = math.Random(42);
    final list = <_BookParticle>[];

    for (int i = 0; i < total; i++) {
      final part = rng.nextDouble();
      double x, y, z;
      Color col;
      double size = 1.0 + rng.nextDouble() * 0.8;
      double alpha = 0.7 + rng.nextDouble() * 0.3;

      if (part < 0.20) {
        // Hardcover & Spine
        final u = (rng.nextDouble() - 0.5) * 2.2;
        final v = (rng.nextDouble() - 0.5) * 1.6;
        x = u;
        y = 0.3 + 0.15 * math.cos(u * 1.2);
        z = v;
        col = Color.lerp(_kSpineBlue, _kCoverCyan, rng.nextDouble())!;
      } else if (part < 0.58) {
        // Left open page wing
        final u = rng.nextDouble();
        final v = (rng.nextDouble() - 0.5) * 1.5;
        final lx = -u * 1.15;
        final ly = -0.3 * math.sin(u * math.pi * 0.85) + (rng.nextDouble() * 0.04);
        x = lx;
        y = ly;
        z = v;
        col = Color.lerp(_kIqWhite, _kPagesGold, u * 0.6)!;
      } else if (part < 0.96) {
        // Right open page wing
        final u = rng.nextDouble();
        final v = (rng.nextDouble() - 0.5) * 1.5;
        final rx = u * 1.15;
        final ry = -0.3 * math.sin(u * math.pi * 0.85) + (rng.nextDouble() * 0.04);
        x = rx;
        y = ry;
        z = v;
        col = Color.lerp(_kIqWhite, _kPagesGold, u * 0.6)!;
      } else {
        // Center gutter knowledge dust
        x = (rng.nextDouble() - 0.5) * 0.4;
        y = -0.15 - rng.nextDouble() * 0.3;
        z = (rng.nextDouble() - 0.5) * 1.2;
        col = _kPagesGold;
        size = 1.4 + rng.nextDouble() * 0.6;
        alpha = 0.9;
      }

      list.add(_BookParticle(
        x: x,
        y: y,
        z: z,
        size: size,
        color: col,
        alpha: alpha,
        shimmer: rng.nextDouble() * math.pi * 2,
      ));
    }

    return list;
  }

  // Generate floating IQ text configurations
  static List<_FloatingIqText> _buildIqItems(int count) {
    final rng = math.Random(1337);
    return List.generate(count, (i) {
      return _FloatingIqText(
        startX: (rng.nextDouble() - 0.5) * 1.4,
        startY: 0.0,
        speed: 0.3 + rng.nextDouble() * 0.4,
        scale: 0.7 + rng.nextDouble() * 0.6,
        phaseOffset: (i / count) * math.pi * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tilt(
      tiltConfig: const TiltConfig(
        angle: 18.0,
        enableRevert: true,
        enableSensorRevert: true,
        leaveDuration: Duration(milliseconds: 1000),
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
        animation: _animCtrl,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ParticleBookPainter(
              particles: _bookParticles,
              iqItems: _iqItems,
              progress: _animCtrl.value,
              isReading: widget.isReading,
              tiltX: _smoothTiltX,
              tiltY: _smoothTiltY,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticleBookPainter extends CustomPainter {
  final List<_BookParticle> particles;
  final List<_FloatingIqText> iqItems;
  final double progress;
  final bool isReading;
  final double tiltX;
  final double tiltY;

  _ParticleBookPainter({
    required this.particles,
    required this.iqItems,
    required this.progress,
    required this.isReading,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0 + size.height * 0.08;
    final scale = size.width * 0.38;

    // Ultra-smooth 3D perspective rotation
    final double yaw = math.sin(progress * math.pi * 2) * 0.10 + (tiltX * 0.40);
    final double pitch = 0.38 + math.sin(progress * math.pi * 2 * 0.5) * 0.03 + (tiltY * 0.30);

    final cosY = math.cos(yaw), sinY = math.sin(yaw);
    final cosX = math.cos(pitch), sinX = math.sin(pitch);

    // Render Ambient Aura Glow behind the book
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kSpineBlue.withValues(alpha: isReading ? 0.38 : 0.22),
          _kCoverCyan.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.50));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.50, auraPaint);

    // Project and Sort Book Particles
    final renderList = <({double sx, double sy, double z, double ps, Color color, double alpha})>[];

    for (final p in particles) {
      final floatY = p.y + math.sin(progress * math.pi * 2 + p.x) * 0.02;

      // 3D rotation matrix including tilt
      final x1 = p.x * cosY + p.z * sinY;
      final z1 = -p.x * sinY + p.z * cosY;
      final y2 = floatY * cosX - z1 * sinX;
      final z2 = floatY * sinX + z1 * cosX;

      const fov = 3.2;
      final persp = fov / (fov + z2 * 0.5);
      final sx = cx + x1 * scale * persp;
      final sy = cy + y2 * scale * persp;

      // Silky soft shimmer
      final shimmer = 0.85 + 0.15 * math.sin(p.shimmer + progress * math.pi * 2);
      final alpha = (p.alpha * shimmer).clamp(0.0, 1.0);

      renderList.add((
        sx: sx,
        sy: sy,
        z: z2,
        ps: p.size * persp,
        color: p.color,
        alpha: alpha,
      ));
    }

    // Depth sort (render back to front)
    renderList.sort((a, b) => a.z.compareTo(b.z));

    final pPaint = Paint();
    for (final r in renderList) {
      if (r.alpha < 0.02) continue;
      final offset = Offset(r.sx, r.sy);

      if (r.ps > 1.4) {
        pPaint
          ..color = r.color.withValues(alpha: r.alpha * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.ps * 1.5);
        canvas.drawCircle(offset, r.ps * 1.6, pPaint);
        pPaint.maskFilter = null;
      }

      pPaint.color = r.color.withValues(alpha: r.alpha);
      canvas.drawCircle(offset, r.ps, pPaint);
    }

    // Draw Floating "IQ" Glyphs (Slow, majestic rise)
    if (isReading) {
      for (int i = 0; i < iqItems.length; i++) {
        final item = iqItems[i];
        final t = (progress * item.speed * 0.85 + item.phaseOffset) % 1.0;

        final rx = item.startX + math.sin(t * math.pi * 2 + i) * 0.05;
        final ry = -0.2 - (t * 1.1);
        final rz = (i % 2 == 0 ? 0.15 : -0.15);

        final x1 = rx * cosY + rz * sinY;
        final z1 = -rx * sinY + rz * cosY;
        final y2 = ry * cosX - z1 * sinX;
        final z2 = ry * sinX + z1 * cosX;

        const fov = 3.2;
        final persp = fov / (fov + z2 * 0.5);
        final sx = cx + x1 * scale * persp;
        final sy = cy + y2 * scale * persp;

        final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
        final currentScale = item.scale * persp * (0.85 + t * 0.3);

        if (alpha > 0.05) {
          _drawParticleIqText(canvas, Offset(sx, sy), currentScale, alpha);
        }
      }
    }
  }

  // Custom Point-Particle Rasterized "IQ" Text Renderer
  void _drawParticleIqText(Canvas canvas, Offset center, double textScale, double alpha) {
    final List<Offset> iPoints = [
      const Offset(-14, -12), const Offset(-10, -12), const Offset(-6, -12),
      const Offset(-10, -8),  const Offset(-10, -4),  const Offset(-10, 0),
      const Offset(-10, 4),   const Offset(-10, 8),   const Offset(-10, 12),
      const Offset(-14, 12),  const Offset(-10, 12),  const Offset(-6, 12),
    ];

    final List<Offset> qPoints = [
      const Offset(2, -12), const Offset(6, -12), const Offset(10, -12),
      const Offset(-2, -8), const Offset(14, -8),
      const Offset(-2, -4), const Offset(14, -4),
      const Offset(-2, 0),  const Offset(14, 0),
      const Offset(-2, 4),  const Offset(14, 4),
      const Offset(2, 8),   const Offset(6, 8),   const Offset(10, 8),
      const Offset(8, 6),   const Offset(12, 10), const Offset(16, 14),
    ];

    final paintGlow = Paint()
      ..color = _kIqGold.withValues(alpha: alpha * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final paintCore = Paint()
      ..color = Colors.white.withValues(alpha: alpha);

    final s = textScale * 0.7;

    for (final pt in [...iPoints, ...qPoints]) {
      final pos = Offset(center.dx + pt.dx * s, center.dy + pt.dy * s);
      canvas.drawCircle(pos, 2.2 * s, paintGlow);
      canvas.drawCircle(pos, 1.3 * s, paintCore);
    }
  }

  @override
  bool shouldRepaint(_ParticleBookPainter old) =>
      old.progress != progress ||
      old.isReading != isReading ||
      old.tiltX != tiltX ||
      old.tiltY != tiltY;
}
