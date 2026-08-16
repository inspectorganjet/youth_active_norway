import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Public Zone Enum  (modular highlight selection)
// ─────────────────────────────────────────────────────────────────────────────
enum BodyZone {
  none,
  head,
  chest,
  abs,
  back,
  shoulders,
  arms,
  glutes,
  quadriceps,
  calves,
}

// ─────────────────────────────────────────────────────────────────────────────
//  Internal particle zone tags
// ─────────────────────────────────────────────────────────────────────────────
enum _Tag {
  head,
  chest,
  abs,
  back,
  shoulders,
  arms,
  glutes,
  quadriceps,
  calves,
}

// ─────────────────────────────────────────────────────────────────────────────
//  Particle
// ─────────────────────────────────────────────────────────────────────────────
class _Pt {
  final double x, y, z;
  final double baseSize;
  final double phase;
  final double brightness;
  final _Tag tag;
  final bool isHighlight;

  const _Pt({
    required this.x,
    required this.y,
    required this.z,
    required this.baseSize,
    required this.phase,
    required this.brightness,
    required this.tag,
    required this.isHighlight,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Neon-particle human body in **squat position**.
///
/// Parameters:
/// * [size]            — canvas size (widget is square).
/// * [highlightedZone] — which body zone gets the accent colour.
///                       Defaults to [BodyZone.quadriceps] (thighs/quads).
/// * [highlightColor]  — override the accent colour (default violet #BF55EC).
/// * [baseColor]       — override the neutral particle colour (default mint).
///
/// The widget responds to pointer-drag for Y-axis 3-D parallax.
class NeonSquatBodyWidget extends StatefulWidget {
  final double size;
  final BodyZone highlightedZone;
  final Color highlightColor;
  final Color baseColor;

  const NeonSquatBodyWidget({
    super.key,
    this.size = 280,
    this.highlightedZone = BodyZone.quadriceps,
    this.highlightColor = const Color(0xFFBF55EC),
    this.baseColor = const Color(0xFF00C48C),
  });

  @override
  State<NeonSquatBodyWidget> createState() => _NeonSquatBodyWidgetState();
}

class _NeonSquatBodyWidgetState extends State<NeonSquatBodyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _idle;
  late List<_Pt> _particles;

  double _tiltX = 0.0, _tiltY = 6.0;
  double _targetTiltX = 0.0, _targetTiltY = 6.0;

  static const int _kN = 9800;
  static final math.Random _rng = math.Random(77);

  @override
  void initState() {
    super.initState();
    _particles = _buildSquatMesh(_kN);
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _idle.addListener(() {
      _tiltX += (_targetTiltX - _tiltX) * 0.07;
      _tiltY += (_targetTiltY - _tiltY) * 0.07;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent e) {
    final cx = widget.size / 2;
    final cy = widget.size / 2;
    setState(() {
      _targetTiltY =
          ((e.localPosition.dx - cx) / cx * 55.0).clamp(-62.0, 62.0);
      _targetTiltX =
          (-(e.localPosition.dy - cy) / cy * 30.0).clamp(-35.0, 35.0);
    });
  }

  // ─── Map public BodyZone → internal _Tag set ───────────────────────────────
  static Set<_Tag> _tagsForZone(BodyZone zone) {
    switch (zone) {
      case BodyZone.head:       return {_Tag.head};
      case BodyZone.chest:      return {_Tag.chest};
      case BodyZone.abs:        return {_Tag.abs};
      case BodyZone.back:       return {_Tag.back};
      case BodyZone.shoulders:  return {_Tag.shoulders};
      case BodyZone.arms:       return {_Tag.arms};
      case BodyZone.glutes:     return {_Tag.glutes};
      case BodyZone.quadriceps: return {_Tag.quadriceps};
      case BodyZone.calves:     return {_Tag.calves};
      case BodyZone.none:       return {};
    }
  }

  // ─── Squat Mesh ─────────────────────────────────────────────────────────────
  //
  //  Coordinate space (normalised units):
  //    x: left(-) / right(+)
  //    y: up(-) / down(+)
  //    z: front(+) / back(-)
  //
  //  Squat pose:
  //    Head & torso : upright  y ∈ [-1.85, -0.50]
  //    Arms         : extended forward at chest height for balance
  //    Hips         : dropped to y ≈ -0.10  (deep squat)
  //    Thighs       : angled diagonally down-forward  hip→knee
  //    Knees        : y ≈ +0.48,  z ≈ +0.34  (pushed forward)
  //    Lower legs   : nearly vertical  knee→ankle
  //    Feet         : flat, toes slightly out
  // ───────────────────────────────────────────────────────────────────────────
  static List<_Pt> _buildSquatMesh(int total) {
    final out = <_Pt>[];

    // HEAD
    _vol(out, cx:0, cy:-1.80, cz:0, rx:.17, ry:.20, rz:.17, n:420, t:_Tag.head, hi:.08);
    _tube(out, x0:0, y0:-1.60, z0:0, x1:0, y1:-1.46, z1:0, r0:.068, r1:.076, n:80, t:_Tag.head);

    // TORSO — chest (upright, slight forward lean reflected in z offset)
    _vol(out, cx:0, cy:-1.14, cz:.04, rx:.33, ry:.24, rz:.15, n:780, t:_Tag.chest, hi:.05);
    _vol(out, cx:-.13, cy:-1.13, cz:.12, rx:.12, ry:.10, rz:.06, n:200, t:_Tag.chest, hi:.22);
    _vol(out, cx: .13, cy:-1.13, cz:.12, rx:.12, ry:.10, rz:.06, n:200, t:_Tag.chest, hi:.22);
    _tube(out, x0:0, y0:-1.30, z0:.12, x1:0, y1:-.88, z1:.13, r0:.015, r1:.011, n:55, t:_Tag.chest);

    // ABS
    for (int row = 0; row < 3; row++) {
      for (final s in [-1.0, 1.0]) {
        _vol(out, cx:s*.082, cy:-.86+row*.125, cz:.13, rx:.055, ry:.046, rz:.035, n:70, t:_Tag.abs, hi:.24);
      }
    }
    for (final s in [-1.0, 1.0]) {
      _tube(out, x0:s*.28, y0:-.98, z0:.03, x1:s*.32, y1:-.64, z1:-.01, r0:.052, r1:.042, n:110, t:_Tag.abs);
    }

    // BACK
    _vol(out, cx:0, cy:-1.12, cz:-.11, rx:.31, ry:.22, rz:.08, n:480, t:_Tag.back, hi:.07);
    for (final s in [-1.0, 1.0]) {
      _tube(out, x0:s*.04, y0:-1.28, z0:-.10, x1:s*.05, y1:-.58, z1:-.11, r0:.046, r1:.036, n:125, t:_Tag.back);
    }

    // PELVIS / HIPS (dropped in deep squat)
    _vol(out, cx:0, cy:-.12, cz:.04, rx:.30, ry:.10, rz:.14, n:260, t:_Tag.glutes);

    // GLUTES
    for (final s in [-1.0, 1.0]) {
      _vol(out, cx:s*.14, cy:-.10, cz:-.14, rx:.16, ry:.13, rz:.10, n:340, t:_Tag.glutes, hi:.18);
      _vol(out, cx:s*.19, cy:-.20, cz:-.09, rx:.09, ry:.09, rz:.07, n:180, t:_Tag.glutes, hi:.20);
    }

    // SHOULDERS
    for (final s in [-1.0, 1.0]) {
      _vol(out, cx:s*.38, cy:-1.30, cz:.04, rx:.11, ry:.09, rz:.09, n:140, t:_Tag.shoulders, hi:.18);
    }

    // ARMS — extended forward for balance in squat
    for (final s in [-1.0, 1.0]) {
      _tube(out, x0:s*.38, y0:-1.24, z0:.04, x1:s*.44, y1:-1.04, z1:.28, r0:.086, r1:.070, n:260, t:_Tag.arms);
      _vol(out, cx:s*.42, cy:-1.12, cz:.18, rx:.055, ry:.095, rz:.052, n:140, t:_Tag.arms, hi:.24);
      _vol(out, cx:s*.42, cy:-1.12, cz:.10, rx:.048, ry:.085, rz:.038, n:95, t:_Tag.arms, hi:.10);
      _vol(out, cx:s*.45, cy:-1.02, cz:.28, rx:.056, ry:.056, rz:.055, n:62, t:_Tag.arms);
      _tube(out, x0:s*.46, y0:-1.02, z0:.30, x1:s*.50, y1:-.96, z1:.50, r0:.060, r1:.040, n:200, t:_Tag.arms);
      _vol(out, cx:s*.51, cy:-.95, cz:.50, rx:.040, ry:.040, rz:.027, n:48, t:_Tag.arms);
      _vol(out, cx:s*.52, cy:-.92, cz:.56, rx:.038, ry:.040, rz:.022, n:55, t:_Tag.arms);
      for (int f = 0; f < 4; f++) {
        final fx = s * .52 + s * (f - 1.5) * .016;
        _tube(out, x0:fx, y0:-.90, z0:.58, x1:fx, y1:-.86, z1:.63, r0:.010, r1:.007, n:14, t:_Tag.arms);
      }
    }

    // QUADRICEPS — primary squat muscle (violet highlight)
    //   Hip: (s*0.15, -0.12, 0) → Knee: (s*0.34, +0.48, +0.34)
    for (final s in [-1.0, 1.0]) {
      // Hip-proximal connector
      _tube(out, x0:s*.15, y0:-.12, z0:.02, x1:s*.22, y1:.14, z1:.14, r0:.160, r1:.168, n:200, t:_Tag.quadriceps);
      // Main quad mass
      _vol(out, cx:s*.26, cy:.20, cz:.22, rx:.150, ry:.240, rz:.120, n:980, t:_Tag.quadriceps, hi:.14);
      // Vastus lateralis (outer, very visible in squat)
      _vol(out, cx:s*.355, cy:.18, cz:.14, rx:.076, ry:.180, rz:.074, n:300, t:_Tag.quadriceps, hi:.24);
      // Vastus medialis (inner teardrop at knee)
      _vol(out, cx:s*.195, cy:.38, cz:.28, rx:.072, ry:.112, rz:.080, n:260, t:_Tag.quadriceps, hi:.36);
      // Rectus femoris centre stripe
      _tube(out, x0:s*.25, y0:.04, z0:.32, x1:s*.24, y1:.42, z1:.30, r0:.044, r1:.038, n:180, t:_Tag.quadriceps);
      // Hamstrings (posterior thigh)
      _vol(out, cx:s*.26, cy:.18, cz:-.04, rx:.116, ry:.220, rz:.076, n:420, t:_Tag.quadriceps, hi:.10);
      // Adductors
      _vol(out, cx:s*.12, cy:.20, cz:.12, rx:.058, ry:.200, rz:.064, n:190, t:_Tag.quadriceps, hi:.08);
      // IT band
      _tube(out, x0:s*.38, y0:-.04, z0:.08, x1:s*.39, y1:.42, z1:.18, r0:.016, r1:.012, n:60, t:_Tag.quadriceps);
      // Muscle fibre detail lines
      for (int fi = 0; fi < 6; fi++) {
        final fy = .04 + fi * .070;
        _tube(out, x0:s*.19, y0:fy, z0:.30, x1:s*.33, y1:fy+.018, z1:.24, r0:.008, r1:.006, n:14, t:_Tag.quadriceps);
      }
    }

    // KNEES
    for (final s in [-1.0, 1.0]) {
      _vol(out, cx:s*.34, cy:.48, cz:.34, rx:.090, ry:.074, rz:.082, n:110, t:_Tag.calves);
    }

    // LOWER LEGS (nearly vertical in deep squat)
    //   Knee: (s*0.34, +0.48, +0.34) → Ankle: (s*0.26, +1.08, +0.12)
    for (final s in [-1.0, 1.0]) {
      _tube(out, x0:s*.34, y0:.50, z0:.34, x1:s*.26, y1:1.08, z1:.12, r0:.078, r1:.044, n:340, t:_Tag.calves);
      _vol(out, cx:s*.24, cy:.72, cz:.12, rx:.060, ry:.150, rz:.056, n:260, t:_Tag.calves, hi:.16);
      _vol(out, cx:s*.30, cy:.70, cz:.10, rx:.055, ry:.138, rz:.050, n:210, t:_Tag.calves, hi:.12);
      _vol(out, cx:s*.27, cy:.84, cz:.08, rx:.062, ry:.108, rz:.044, n:130, t:_Tag.calves);
      for (int cf = 0; cf < 4; cf++) {
        final fy = .56 + cf * .10;
        _tube(out, x0:s*.23, y0:fy, z0:.14, x1:s*.29, y1:fy+.06, z1:.10, r0:.007, r1:.005, n:10, t:_Tag.calves);
      }
    }

    // ANKLES + FEET (toes slightly out — squat stance)
    for (final s in [-1.0, 1.0]) {
      _vol(out, cx:s*.26, cy:1.085, cz:.12, rx:.045, ry:.048, rz:.045, n:58, t:_Tag.calves);
      _vol(out, cx:s*.26, cy:1.14, cz:-.02, rx:.052, ry:.036, rz:.052, n:70, t:_Tag.calves);
      final toeX = s * .042;
      _vol(out, cx:s*.26+toeX, cy:1.17, cz:.22, rx:.065, ry:.036, rz:.055, n:88, t:_Tag.calves);
    }

    return out;
  }

  // ─── Geometry Primitives ───────────────────────────────────────────────────
  static void _vol(List<_Pt> out, {
    required double cx, required double cy, required double cz,
    required double rx, required double ry, required double rz,
    required int n, required _Tag t, double hi = 0.0,
  }) {
    for (int i = 0; i < n; i++) {
      final u = _rng.nextDouble(), v = _rng.nextDouble();
      final th = u * 2 * math.pi, ph = math.acos(2 * v - 1);
      final r = math.pow(_rng.nextDouble(), 1 / 3.0).toDouble();
      final px = cx + rx * r * math.sin(ph) * math.cos(th);
      final py = cy + ry * r * math.cos(ph);
      final pz = cz + rz * r * math.sin(ph) * math.sin(th);
      final isHi = hi > 0.1 && _rng.nextDouble() > 0.62;
      final br = (0.50 + _rng.nextDouble() * 0.50 + hi).clamp(0.0, 1.0);
      out.add(_Pt(
        x: px, y: py, z: pz,
        baseSize: isHi ? 2.4 + _rng.nextDouble() * 1.2 : 0.85 + _rng.nextDouble() * 1.8,
        phase: _rng.nextDouble() * math.pi * 2,
        brightness: br, tag: t, isHighlight: isHi,
      ));
    }
  }

  static void _tube(List<_Pt> out, {
    required double x0, required double y0, required double z0,
    required double x1, required double y1, required double z1,
    required double r0, required double r1,
    required int n, required _Tag t, double hi = 0.0,
  }) {
    final dx = x1 - x0, dy = y1 - y0, dz = z1 - z0;
    final len = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (len < 1e-6) return;
    final ux = dx / len, uy = dy / len, uz = dz / len;
    double pvx, pvy, pvz;
    if (ux.abs() < 0.9) { pvx = 0; pvy = -uz; pvz = uy; }
    else { pvx = -uz; pvy = 0; pvz = ux; }
    final pL = math.sqrt(pvx * pvx + pvy * pvy + pvz * pvz);
    pvx /= pL; pvy /= pL; pvz /= pL;
    final qx = uy * pvz - uz * pvy;
    final qy = uz * pvx - ux * pvz;
    final qz = ux * pvy - uy * pvx;
    for (int i = 0; i < n; i++) {
      final tl = _rng.nextDouble(), th = _rng.nextDouble() * 2 * math.pi;
      final r = math.sqrt(_rng.nextDouble()) * (r0 + (r1 - r0) * tl);
      final mx = x0 + ux * len * tl, my = y0 + uy * len * tl, mz = z0 + uz * len * tl;
      final px2 = mx + r * (math.cos(th) * pvx + math.sin(th) * qx);
      final py2 = my + r * (math.cos(th) * pvy + math.sin(th) * qy);
      final pz2 = mz + r * (math.cos(th) * pvz + math.sin(th) * qz);
      final br = (0.48 + _rng.nextDouble() * 0.52 + hi).clamp(0.0, 1.0);
      out.add(_Pt(
        x: px2, y: py2, z: pz2,
        baseSize: 0.85 + _rng.nextDouble() * 1.7,
        phase: _rng.nextDouble() * math.pi * 2,
        brightness: br, tag: t, isHighlight: false,
      ));
    }
  }

  // ─── 3-D Projection ────────────────────────────────────────────────────────
  //  Squat body y-span: [-1.95, +1.22]  → height ≈ 3.17 units
  //  center_y = (-1.95 + 1.22) / 2 = -0.365
  static ({double sx, double sy, double wz}) _project(
    double x, double y, double z,
    double rxDeg, double ryDeg, double canvasH,
  ) {
    final rxR = rxDeg * math.pi / 180;
    final ryR = ryDeg * math.pi / 180;
    final x1 = x * math.cos(ryR) + z * math.sin(ryR);
    final z1 = -x * math.sin(ryR) + z * math.cos(ryR);
    final y2 = y * math.cos(rxR) - z1 * math.sin(rxR);
    final z2 = y * math.sin(rxR) + z1 * math.cos(rxR);
    const double bodyH = 3.17;
    const double bodyCenter = -0.365;
    final double scale = (canvasH * 0.87) / bodyH;
    final double persp = 1.0 + z2 * 0.035;
    return (sx: x1 * scale * persp, sy: (y2 - bodyCenter) * scale * persp, wz: z2);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final highlightTags = _tagsForZone(widget.highlightedZone);
    return MouseRegion(
      onExit: (_) => setState(() { _targetTiltX = 0; _targetTiltY = 6; }),
      child: Listener(
        onPointerMove: _onPointerMove,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SquatBodyPainter(
              particles: _particles,
              tiltX: _tiltX,
              tiltY: _tiltY,
              t: _idle.value * 12,
              highlightTags: highlightTags,
              highlightColor: widget.highlightColor,
              baseColor: widget.baseColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────────────────────
class _SquatBodyPainter extends CustomPainter {
  final List<_Pt> particles;
  final double tiltX, tiltY, t;
  final Set<_Tag> highlightTags;
  final Color highlightColor;
  final Color baseColor;

  const _SquatBodyPainter({
    required this.particles,
    required this.tiltX,
    required this.tiltY,
    required this.t,
    required this.highlightTags,
    required this.highlightColor,
    required this.baseColor,
  });

  static _Palette _paletteFrom(Color c) => _Palette(
    mid: c,
    bright: Color.lerp(c, Colors.white, 0.40)!,
    glow: Color.lerp(c, const Color(0xFF00FFA3), 0.28)!,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pScale = (size.height / 320.0).clamp(0.28, 1.8);

    final neutralPal   = _paletteFrom(baseColor);
    final highlightPal = _paletteFrom(highlightColor);

    // Project + depth-sort (painter's algorithm)
    final list = <({_Pt p, double sx, double sy, double wz})>[];
    for (final p in particles) {
      final r = _NeonSquatBodyWidgetState._project(
          p.x, p.y, p.z, tiltX, tiltY, size.height);
      list.add((p: p, sx: r.sx, sy: r.sy, wz: r.wz));
    }
    list.sort((a, b) => a.wz.compareTo(b.wz));

    final paint = Paint()..style = PaintingStyle.fill;

    for (final item in list) {
      final screenX = cx + item.sx;
      final screenY = cy + item.sy;
      if (screenX < -10 || screenX > size.width  + 10) continue;
      if (screenY < -10 || screenY > size.height + 10) continue;

      final p = item.p;
      final isHot = highlightTags.contains(p.tag);
      final pal = isHot ? highlightPal : neutralPal;

      // Breathing shimmer — quad zone pulses faster & stronger
      final pulseSpeed = isHot ? 3.8 : 2.2;
      final pulseAmp   = isHot ? 0.22 : 0.13;
      final shimmer = math.sin(t * pulseSpeed + p.phase) * pulseAmp;
      final alpha = ((p.brightness + shimmer) * 255).clamp(60, 255).toInt();

      final depthF   = (item.wz * 0.11 + 1.0).clamp(0.72, 1.32);
      final zoneSc   = isHot ? 1.18 : 1.0;
      final sz = p.baseSize * depthF * pScale * zoneSc;

      if (p.isHighlight) {
        // Triple-layer bloom
        paint.color = pal.glow.withAlpha((alpha * 0.18).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 3.0, paint);
        paint.color = pal.glow.withAlpha((alpha * 0.38).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 1.75, paint);
        paint.color = pal.bright.withAlpha(alpha);
        canvas.drawCircle(Offset(screenX, screenY), sz, paint);
      } else {
        // Standard two-layer glow
        paint.color = pal.mid.withAlpha((alpha * 0.24).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 1.55, paint);
        paint.color = (p.brightness > 0.70 ? pal.bright : pal.mid).withAlpha(alpha);
        canvas.drawCircle(Offset(screenX, screenY), sz * 0.70, paint);
      }
    }

    // Ground ambient glow (dual-colour ellipse)
    final groundY = cy + size.height * 0.42;
    for (final rec in [
      (neutralPal.glow,   size.width * 0.72, size.height * 0.055),
      (highlightPal.glow, size.width * 0.50, size.height * 0.036),
    ]) {
      final (Color c, double w, double h) = rec;
      final r = Rect.fromCenter(center: Offset(cx, groundY), width: w, height: h * 2.6);
      paint.color = Colors.transparent;
      final gPaint = Paint()
        ..shader = RadialGradient(colors: [c.withAlpha(28), Colors.transparent])
            .createShader(r)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, groundY), width: w, height: h),
          gPaint);
    }
  }

  @override
  bool shouldRepaint(_SquatBodyPainter old) => true;
}

// Small colour palette helper
class _Palette {
  final Color mid, bright, glow;
  const _Palette({required this.mid, required this.bright, required this.glow});
}
