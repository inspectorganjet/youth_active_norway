import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A high-density 3D sphere composed of glowing blue neon particles (~1500 particles) that:
///  1. Breathes — expands/contracts and scales text synchronously with [breathProgress] (0.0 → 1.0).
///  2. Tilts — reacts in real-time to physical device tilt (accelerometer/gyroscope) + pointer hover on web + continuous 3D orbital rotation.
///  3. Delivers a visually stunning "WOW" particle effect with glowing cyan/neon-blue layering.
class BreathingParticleOrb extends StatefulWidget {
  /// Current breathing progress supplied by the parent AnimationController value (0.0 → 1.0).
  final double breathProgress;

  /// Bounding size of the square canvas (e.g. 185).
  final double size;

  /// Text shown in the centre of the orb (e.g. "PUST INN\n🫁").
  final String centerText;

  /// Whether the session is currently active.
  final bool isActive;

  const BreathingParticleOrb({
    super.key,
    required this.breathProgress,
    required this.centerText,
    this.size = 185,
    this.isActive = false,
  });

  @override
  State<BreathingParticleOrb> createState() => _BreathingParticleOrbState();
}

class _BreathingParticleOrbState extends State<BreathingParticleOrb>
    with SingleTickerProviderStateMixin {
  // ─── Sensor subscriptions ────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;
  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;

  // ─── Ticker controller for 3D continuous rotation & shimmer ────────────────
  late AnimationController _driftController;

  // ─── High-density 3D Particle Cloud (~1500 particles) ────────────────────
  late List<_Particle> _particles;
  static const int _kParticleCount = 1450; // 4.5x more particles!

  @override
  void initState() {
    super.initState();

    _particles = _buildParticles(_kParticleCount);

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _initSensors();
  }

  void _initSensors() {
    // Accelerometer stream
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (AccelerometerEvent e) {
          if (!mounted) return;
          // In portrait: e.x is tilt left/right, e.y is tilt forward/back
          // Standard gravity is ~9.8 on Z when flat, or on Y when standing
          final double pitch = (e.y * 6.0).clamp(-50.0, 50.0);
          final double roll = (-e.x * 6.0).clamp(-50.0, 50.0);

          _targetTiltX = pitch;
          _targetTiltY = roll;
        },
        onError: (_) {},
      );
    } catch (_) {}

    // Gyroscope stream fallback/enhancement for instantaneous rotation speed
    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (GyroscopeEvent e) {
          if (!mounted) return;
          _targetTiltX = (_targetTiltX + e.x * 3.0).clamp(-60.0, 60.0);
          _targetTiltY = (_targetTiltY + e.y * 3.0).clamp(-60.0, 60.0);
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _driftController.dispose();
    super.dispose();
  }

  static List<_Particle> _buildParticles(int count) {
    final rng = math.Random(1337);
    final List<_Particle> list = [];

    for (int i = 0; i < count; i++) {
      // Fibonacci sphere mapping for perfect uniform density
      final double phi = math.acos(1 - 2 * (i + 0.5) / count);
      final double theta = math.pi * (1 + math.sqrt(5)) * i;

      final double x = math.sin(phi) * math.cos(theta);
      final double y = math.sin(phi) * math.sin(theta);
      final double z = math.cos(phi);

      // Varied particle sizes: micro dots + sparkling bright focal points
      final double size = 0.9 + rng.nextDouble() * 2.6;
      final double phase = rng.nextDouble() * math.pi * 2;
      final double brightness = 0.4 + rng.nextDouble() * 0.6;
      final double radialJitter = 0.94 + rng.nextDouble() * 0.12;

      // Color variation: 0 = deep sapphire blue, 1 = electric cyan / white
      final double colorType = rng.nextDouble();

      list.add(_Particle(
        nx: x * radialJitter,
        ny: y * radialJitter,
        nz: z * radialJitter,
        baseSize: size,
        shimmerPhase: phase,
        brightness: brightness,
        colorType: colorType,
      ));
    }
    return list;
  }

  void _onPointerMove(PointerEvent event) {
    final Size canvasSize = Size(widget.size, widget.size);
    final double dx = (event.localPosition.dx - canvasSize.width / 2) / (canvasSize.width / 2);
    final double dy = (event.localPosition.dy - canvasSize.height / 2) / (canvasSize.height / 2);

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
          animation: _driftController,
          builder: (context, child) {
            // Smoothly interpolate tilt angles per frame
            _currentTiltX += (_targetTiltX - _currentTiltX) * 0.12;
            _currentTiltY += (_targetTiltY - _currentTiltY) * 0.12;

            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _OrbPainter(
                particles: _particles,
                breathProgress: widget.breathProgress,
                tiltX: _currentTiltX,
                tiltY: _currentTiltY,
                driftT: _driftController.value,
                isActive: widget.isActive,
                centerText: widget.centerText,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final double nx, ny, nz;
  final double baseSize;
  final double shimmerPhase;
  final double brightness;
  final double colorType; // 0.0 → 1.0 spectrum

  const _Particle({
    required this.nx,
    required this.ny,
    required this.nz,
    required this.baseSize,
    required this.shimmerPhase,
    required this.brightness,
    required this.colorType,
  });
}

class _OrbPainter extends CustomPainter {
  final List<_Particle> particles;
  final double breathProgress;
  final double tiltX;
  final double tiltY;
  final double driftT;
  final bool isActive;
  final String centerText;

  late final double _cosX, _sinX, _cosY, _sinY, _cosZ, _sinZ;

  _OrbPainter({
    required this.particles,
    required this.breathProgress,
    required this.tiltX,
    required this.tiltY,
    required this.driftT,
    required this.isActive,
    required this.centerText,
  }) {
    // Add continuous slow 3D orbital spin + tilt
    final double orbitalSpin = driftT * math.pi * 2;
    final double rx = (tiltX * math.pi / 180) + math.sin(orbitalSpin * 0.5) * 0.15;
    final double ry = (tiltY * math.pi / 180) + orbitalSpin * 0.6;
    final double rz = math.cos(orbitalSpin * 0.3) * 0.1;

    _cosX = math.cos(rx);
    _sinX = math.sin(rx);
    _cosY = math.cos(ry);
    _sinY = math.sin(ry);
    _cosZ = math.cos(rz);
    _sinZ = math.sin(rz);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Radius breathes dynamically: 48px (exhale) → 78px (inhale)
    final double baseRadius = 48.0 + breathProgress * 30.0;

    // ── 1. Multilayer Glowing Aura Background ────────────────────────────────
    final double glowRadius = baseRadius * (1.2 + breathProgress * 0.3);

    // Deep outer blue diffuse glow
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00F0FF).withValues(alpha: 0.25 + breathProgress * 0.2),
          const Color(0xFF3B82F6).withValues(alpha: 0.15 + breathProgress * 0.15),
          const Color(0xFF1E1B4B).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius * 1.35));
    canvas.drawCircle(Offset(cx, cy), glowRadius * 1.35, outerGlow);

    // Bright intense cyan core aura
    final coreAura = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.35 + breathProgress * 0.2),
          const Color(0xFF0284C7).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius * 0.7));
    canvas.drawCircle(Offset(cx, cy), baseRadius * 0.7, coreAura);

    // ── 2. Project 1450 Particles in 3D ─────────────────────────────────────
    final List<_ProjectedParticle> projected = [];

    for (final p in particles) {
      // Rotate 3D point (Rx * Ry * Rz)
      double y1 = p.ny * _cosX - p.nz * _sinX;
      double z1 = p.ny * _sinX + p.nz * _cosX;

      double x2 = p.nx * _cosY + z1 * _sinY;
      double z2 = -p.nx * _sinY + z1 * _cosY;

      double x3 = x2 * _cosZ - y1 * _sinZ;
      double y3 = x2 * _sinZ + y1 * _cosZ;
      double z3 = z2;

      // Perspective projection factor
      final double fov = 3.0;
      final double scale = fov / (fov + z3);
      final double sx = cx + x3 * baseRadius * scale;
      final double sy = cy + y3 * baseRadius * scale;

      // Depth 0.0 (back) → 1.0 (front)
      final double depthFactor = (z3 + 1.0) * 0.5;

      // Sparkling pulse
      final double shimmer = 0.65 +
          0.35 * math.sin(p.shimmerPhase + driftT * math.pi * 4 + depthFactor * math.pi * 2);

      final double alpha = (p.brightness * (0.2 + 0.8 * depthFactor) * shimmer).clamp(0.0, 1.0);
      final double pSize = p.baseSize * scale * (0.45 + depthFactor * 0.55);

      projected.add(_ProjectedParticle(
        sx: sx,
        sy: sy,
        wz: z3,
        alpha: alpha,
        size: pSize,
        depthFactor: depthFactor,
        colorType: p.colorType,
      ));
    }

    // Painter's algorithm: sort back-to-front
    projected.sort((a, b) => a.wz.compareTo(b.wz));

    // ── 3. Render High-Density Neon Particles ──────────────────────────────
    final paintObj = Paint();

    for (final pp in projected) {
      if (pp.alpha < 0.04) continue;

      // Neon color gradient: Deep Electric Blue → Bright Cyan → Ultra White
      Color particleColor;
      if (pp.colorType < 0.6) {
        particleColor = Color.lerp(
          const Color(0xFF2563EB), // Royal blue
          const Color(0xFF38BDF8), // Electric cyan
          pp.depthFactor,
        )!;
      } else if (pp.colorType < 0.9) {
        particleColor = Color.lerp(
          const Color(0xFF0284C7), // Deep sky
          const Color(0xFFE0F2FE), // Ice cyan
          pp.depthFactor,
        )!;
      } else {
        particleColor = Color.lerp(
          const Color(0xFF60A5FA), // Blue
          Colors.white, // Pure white sparkle
          pp.depthFactor,
        )!;
      }

      final Offset pt = Offset(pp.sx, pp.sy);

      // Glow halo for larger / front particles
      if (pp.size > 1.4 && pp.depthFactor > 0.35) {
        paintObj
          ..color = particleColor.withValues(alpha: pp.alpha * 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pp.size * 1.5);
        canvas.drawCircle(pt, pp.size * 2.2, paintObj);
        paintObj.maskFilter = null;
      }

      // Core particle dot
      paintObj.color = particleColor.withValues(alpha: pp.alpha);
      canvas.drawCircle(pt, pp.size, paintObj);
    }

    // ── 4. Synchronized Breathing Text ──────────────────────────────────────
    // Font size & glow intensity scale continuously with breathProgress (11.5px → 16.5px)
    final double fontSize = 12.0 + breathProgress * 5.0;
    final double textGlowBlur = 6.0 + breathProgress * 8.0;

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.95),
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      height: 1.35,
      letterSpacing: 0.4,
      shadows: [
        Shadow(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
          blurRadius: textGlowBlur,
        ),
        Shadow(
          color: const Color(0xFF1D4ED8).withValues(alpha: 0.8),
          blurRadius: textGlowBlur * 1.5,
        ),
      ],
    );

    final textSpan = TextSpan(text: centerText, style: textStyle);
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.65);

    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.breathProgress != breathProgress ||
      old.tiltX != tiltX ||
      old.tiltY != tiltY ||
      old.driftT != driftT ||
      old.isActive != isActive ||
      old.centerText != centerText;
}

class _ProjectedParticle {
  final double sx, sy, wz, alpha, size, depthFactor, colorType;
  const _ProjectedParticle({
    required this.sx,
    required this.sy,
    required this.wz,
    required this.alpha,
    required this.size,
    required this.depthFactor,
    required this.colorType,
  });
}
