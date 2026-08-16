import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'cyber_boxer_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in widget that renders the animated cyber boxer.
///
/// Usage:
/// ```dart
/// CyberBoxerWidget(level: 75, size: 300)
/// ```
///
/// Tap anywhere on the widget to trigger a punch animation.
class CyberBoxerWidget extends StatefulWidget {
  /// Player level controlling smoke colour:
  ///  0-9   → no smoke
  ///  10-49 → blue smoke
  ///  50-99 → yellow smoke
  ///  100+  → purple smoke
  final int level;

  /// Render size (widget will be a square of this side length).
  final double size;

  /// If provided, the punch animation will be driven externally (0.0 → 1.0).
  /// When null, a tap triggers the punch automatically.
  final double? externalPunchT;

  const CyberBoxerWidget({
    super.key,
    this.level = 0,
    this.size = 320,
    this.externalPunchT,
  });

  @override
  State<CyberBoxerWidget> createState() => _CyberBoxerWidgetState();
}

class _CyberBoxerWidgetState extends State<CyberBoxerWidget>
    with TickerProviderStateMixin {
  // ── Idle animation (breathing loop) ───────────────────────────────────────
  late final AnimationController _idleCtrl;

  // ── Punch animation ────────────────────────────────────────────────────────
  late final AnimationController _punchCtrl;
  late final Animation<double> _punchAnim;

  // ── Smoke particles ───────────────────────────────────────────────────────
  final List<SmokeParticle> _particles = [];
  late Ticker _smokeTicker;
  final _rng = math.Random();
  double _smokeAccum = 0.0;

  @override
  void initState() {
    super.initState();

    // Idle: 3-second loop
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Punch: 0.75 s one-shot, custom easing
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _punchAnim = CurvedAnimation(
      parent: _punchCtrl,
      curve: Curves.easeInOut,
    );

    // Particle ticker at ~60 FPS
    _smokeTicker = createTicker(_onSmokeTick)..start();
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _punchCtrl.dispose();
    _smokeTicker.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SMOKE SIM
  // ─────────────────────────────────────────────────────────────────────────
  void _onSmokeTick(Duration elapsed) {
    if (widget.level < 10) {
      if (_particles.isNotEmpty) {
        setState(() => _particles.clear());
      }
      return;
    }

    const dt = 1 / 60.0;
    _smokeAccum += dt;

    // Spawn interval depends on level (higher level → denser smoke)
    final spawnInterval = widget.level >= 100
        ? 0.06
        : widget.level >= 50
            ? 0.10
            : 0.16;

    if (_smokeAccum >= spawnInterval) {
      _smokeAccum = 0;
      _particles.add(SmokeParticle(
        x: (_rng.nextDouble() - 0.5) * 20,
        y: -30.0 - _rng.nextDouble() * 20,
        size: 6 + _rng.nextDouble() * 10,
        life: 1.0,
        vx: (_rng.nextDouble() - 0.5) * 0.6,
        vy: -(0.4 + _rng.nextDouble() * 0.6),
      ));
    }

    // Update existing particles
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.size += 0.08;
      p.life -= dt / 2.8; // live ~2.8 s
    }
    _particles.removeWhere((p) => p.life <= 0);

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUNCH TRIGGER
  // ─────────────────────────────────────────────────────────────────────────
  void _triggerPunch() {
    _punchCtrl.forward(from: 0.0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.externalPunchT == null ? _triggerPunch : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleCtrl, _punchAnim]),
        builder: (context, _) {
          final punchT =
              widget.externalPunchT ?? _punchAnim.value;
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CyberBoxerPainter(
              punchT: punchT,
              idleT: _idleCtrl.value,
              level: widget.level,
              smokeParticles: List.unmodifiable(_particles),
            ),
          );
        },
      ),
    );
  }
}
