import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HolographicCard
//
// A premium holographic trading-card widget with real-time 3-D tilt,
// a rainbow foil shimmer layer (BlendMode.screen) and a programmatic
// neon glassmorphism frame — no external image for the border.
//
// Usage:
//   HolographicCard(
//     width:           300,
//     height:          420,
//     backgroundAsset: 'assets/images/card_bg.png',
//     characterAsset:  'assets/images/card_character.png',
//     cardTitle:       'ULTRA RARE',
//     cardSubtitle:    'Cyber Warrior',
//   )
// ─────────────────────────────────────────────────────────────────────────────
class HolographicCard extends StatefulWidget {
  const HolographicCard({
    super.key,
    required this.width,
    required this.height,
    required this.backgroundAsset,
    required this.characterAsset,
    this.cardTitle = 'ULTRA RARE',
    this.cardSubtitle = '',
    this.borderRadius = 20.0,
    this.tiltAngle = 15.0,
    this.holoOpacity = 0.38,
  });

  final double width;
  final double height;
  final String backgroundAsset;
  final String characterAsset;
  final String cardTitle;
  final String cardSubtitle;
  final double borderRadius;
  final double tiltAngle;
  final double holoOpacity;

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard> {
  // Tilt area-progress: x/y each ∈ [-1, 1]
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // flutter_tilt 3.x: external control via StreamController<TiltStreamModel>
  final StreamController<TiltStreamModel> _tiltStreamController =
      StreamController<TiltStreamModel>.broadcast();

  void _onGestureMove(TiltDataModel data, GesturesType type) {
    if (!mounted) return;
    setState(() {
      _tiltX = data.areaProgress.dx;
      _tiltY = data.areaProgress.dy;
    });
  }

  void _onGestureLeave(TiltDataModel data, GesturesType type) {
    if (!mounted) return;
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  void dispose() {
    _tiltStreamController.close();
    super.dispose();
  }

  // ── Holographic gradient ─────────────────────────────────────────────────
  // The begin/end anchors shift with tilt so the rainbow sweeps across the
  // card surface as the player tilts it.
  LinearGradient _buildHoloGradient() {
    final double ax = (_tiltX * 0.7).clamp(-1.0, 1.0);
    final double ay = (_tiltY * 0.7).clamp(-1.0, 1.0);

    final begin = Alignment(-1.0 + ax, -1.0 + ay);
    final end   = Alignment( 1.0 + ax,  1.0 + ay);

    // Stop-shift so colours appear to travel across the card
    final double shift = ((_tiltX + _tiltY) * 0.5).clamp(-0.28, 0.28);

    return LinearGradient(
      begin: begin,
      end:   end,
      stops: [
        (0.00 + shift).clamp(0.0, 1.0),
        (0.20 + shift).clamp(0.0, 1.0),
        (0.40 + shift).clamp(0.0, 1.0),
        (0.60 + shift).clamp(0.0, 1.0),
        (0.80 + shift).clamp(0.0, 1.0),
        (1.00 + shift).clamp(0.0, 1.0),
      ],
      colors: const [
        Color(0xFFFF00FF), // magenta / pink
        Color(0xFF8B00FF), // violet
        Color(0xFF00FFFF), // cyan / teal
        Color(0xFF00FF88), // mint
        Color(0xFFFFD700), // gold
        Color(0xFFFF4488), // hot-pink
      ],
    );
  }

  // ── Neon border gradient ─────────────────────────────────────────────────
  static const LinearGradient _borderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [
      Color(0xFFFF00FF),
      Color(0xFF8B00FF),
      Color(0xFF00FFFF),
      Color(0xFFFFD700),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Tilt(
      tiltStreamController: _tiltStreamController,
      onGestureMove:  _onGestureMove,
      onGestureLeave: _onGestureLeave,
      tiltConfig: TiltConfig(
        angle:        widget.tiltAngle,
        enableRevert: true,
        leaveDuration: const Duration(milliseconds: 600),
        enableSensorRevert: true,
      ),
      shadowConfig: const ShadowConfig(
        color:         Color(0xFF000000),
        maxIntensity:  0.55,
        offsetFactor:  0.15,
        spreadFactor:  0.02,
        minBlurRadius: 12,
        maxBlurRadius: 36,
      ),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width:  widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 0 · Background
              _BackgroundLayer(asset: widget.backgroundAsset),

              // Layer 1 · Character PNG (transparent bg)
              _CharacterLayer(asset: widget.characterAsset),

              // Layer 2 · Holo foil — BlendMode.screen ≈ real iridescent foil
              _HoloFoilLayer(
                gradient: _buildHoloGradient(),
                opacity:  widget.holoOpacity,
              ),

              // Layer 3 · Programmatic glass frame + text
              _GlassFrameLayer(
                borderRadius:   widget.borderRadius,
                borderGradient: _borderGradient,
                title:          widget.cardTitle,
                subtitle:       widget.cardSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer 0 · Background image
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [Color(0xFF0D0D2B), Color(0xFF1A0033)],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer 1 · Character image (PNG with transparent background)
// ─────────────────────────────────────────────────────────────────────────────
class _CharacterLayer extends StatelessWidget {
  const _CharacterLayer({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top:    40,
      bottom: 52,
      child: Image.asset(
        asset,
        fit:       BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stack) => const Center(
          child: Icon(
            Icons.person_outline,
            color: Colors.white38,
            size:  120,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer 2 · Holographic foil overlay
// BlendMode.screen makes it behave like real iridescent foil / rainbow chrome
// ─────────────────────────────────────────────────────────────────────────────
class _HoloFoilLayer extends StatelessWidget {
  const _HoloFoilLayer({required this.gradient, required this.opacity});
  final LinearGradient gradient;
  final double         opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ShaderMask(
        blendMode:      BlendMode.screen,
        shaderCallback: (Rect bounds) => gradient.createShader(bounds),
        child: Container(color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer 3 · Glassmorphism frame — drawn entirely in code, no asset needed
// ─────────────────────────────────────────────────────────────────────────────
class _GlassFrameLayer extends StatelessWidget {
  const _GlassFrameLayer({
    required this.borderRadius,
    required this.borderGradient,
    required this.title,
    required this.subtitle,
  });

  final double         borderRadius;
  final LinearGradient borderGradient;
  final String         title;
  final String         subtitle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeonBorderPainter(
        gradient:     borderGradient,
        borderRadius: borderRadius,
        strokeWidth:  2.6,
      ),
      child: Stack(
        children: [
          // Top badge
          Positioned(
            top: 12, left: 14, right: 14,
            child: _TopBadge(title: title),
          ),
          // Bottom frosted panel
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomPanel(subtitle: subtitle),
          ),
          // Corner accent dots
          const _CornerAccents(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — neon gradient border with outer glow
// ─────────────────────────────────────────────────────────────────────────────
class _NeonBorderPainter extends CustomPainter {
  const _NeonBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  final LinearGradient gradient;
  final double         borderRadius;
  final double         strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2, strokeWidth / 2,
        size.width  - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    // Soft outer glow
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader      = gradient.createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 4
        ..maskFilter  = const MaskFilter.blur(BlurStyle.outer, 9),
    );

    // Crisp border line
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader      = gradient.createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_NeonBorderPainter old) =>
      old.gradient != gradient ||
      old.borderRadius != borderRadius ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top badge — rarity label + star rating
// ─────────────────────────────────────────────────────────────────────────────
class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.title});
  final String title;

  static const _kLabelGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF88CC)],
  );

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Container(
        width: 144.8, // Explicitly size to match the bounded layout constraints to prevent unbounded scaling
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily:    'monospace',
                      fontSize:      11,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 2.0,
                      foreground:    Paint()
                        ..shader = _kLabelGradient.createShader(
                          const Rect.fromLTWH(0, 0, 120, 20),
                        ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(
                5,
                (_) => const Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                  size:  13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom frosted-glass info panel
// ─────────────────────────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.black.withValues(alpha: 0.60),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          child: Column(
            mainAxisSize:        MainAxisSize.min,
            crossAxisAlignment:  CrossAxisAlignment.start,
            children: [
              if (subtitle.isNotEmpty) ...[
                Text(
                  subtitle,
                  style: const TextStyle(
                    color:         Color(0xFFCCCCFF),
                    fontSize:      12,
                    fontWeight:    FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: const [
                  _StatChip(label: 'ATK', value: 880,  color: Color(0xFFFF4466)),
                  SizedBox(width: 8),
                  _StatChip(label: 'DEF', value: 640,  color: Color(0xFF44AAFF)),
                  SizedBox(width: 8),
                  _StatChip(label: 'HP',  value: 9900, color: Color(0xFF44FF88)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int    value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text:  '$label ',
              style: TextStyle(
                color:         color.withValues(alpha: 0.75),
                fontSize:      9,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            TextSpan(
              text:  value.toString(),
              style: TextStyle(
                color:      color,
                fontSize:   11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner accent dots
// ─────────────────────────────────────────────────────────────────────────────
class _CornerAccents extends StatelessWidget {
  const _CornerAccents();

  Widget _dot() => Container(
        width:  6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFD700).withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color:        const Color(0xFFFFD700).withValues(alpha: 0.65),
              blurRadius:   6,
              spreadRadius: 1,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 8,    left:  8,  child: _dot()),
        Positioned(top: 8,    right: 8,  child: _dot()),
        Positioned(bottom: 8, left:  8,  child: _dot()),
        Positioned(bottom: 8, right: 8,  child: _dot()),
      ],
    );
  }
}
