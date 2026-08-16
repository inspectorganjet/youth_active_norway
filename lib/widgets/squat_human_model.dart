import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Muscle Zone
// ─────────────────────────────────────────────────────────────────────────────
enum _Zone {
  /// Rest of body — neon electric blue
  neutral,
  /// Quadriceps / thighs — neon violet (most activated during squats)
  quadriceps,
  /// Glutes — neon violet (secondary activation)
  glutes,
}

// ─────────────────────────────────────────────────────────────────────────────
//  Particle
// ─────────────────────────────────────────────────────────────────────────────
class _Pt {
  final double x, y, z;
  final double baseSize;
  final double phase;
  final double brightness;
  final _Zone zone;
  final bool isHighlight;

  const _Pt({
    required this.x, required this.y, required this.z,
    required this.baseSize, required this.phase,
    required this.brightness, required this.zone,
    required this.isHighlight,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Colours
// ─────────────────────────────────────────────────────────────────────────────
// Blue – neutral body
const Color _kBMid    = Color(0xFF2979FF);
const Color _kBBright = Color(0xFF82B1FF);
const Color _kBGlow   = Color(0xFF40C4FF);

// Violet – quads / glutes
const Color _kVMid    = Color(0xFFAA00FF);
const Color _kVBright = Color(0xFFEA80FC);
const Color _kVGlow   = Color(0xFFCE93D8);

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Dense neon-particle human model for the Squat workout screen.
///
/// • Blue neon  — full body (head, torso, arms, lower legs).
/// • Violet neon — quadriceps & glutes (primary squat muscles).
///
/// Responds to pointer-drag for 3-D rotation.
/// Particle count ~8 500 ensures excellent visual density.
class SquatHumanModel extends StatefulWidget {
  final double size;
  const SquatHumanModel({super.key, this.size = 220});

  @override
  State<SquatHumanModel> createState() => _SquatHumanModelState();
}

class _SquatHumanModelState extends State<SquatHumanModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _idle;
  late List<_Pt> _particles;

  double _tiltX = 0.0, _tiltY = 8.0; // slight default tilt for depth
  double _targetTiltX = 0.0, _targetTiltY = 8.0;

  static const int _kN = 8500;
  static final math.Random _rng = math.Random(99);

  @override
  void initState() {
    super.initState();
    _particles = _build(_kN);
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _idle.addListener(() {
      _tiltX += (_targetTiltX - _tiltX) * 0.08;
      _tiltY += (_targetTiltY - _tiltY) * 0.08;
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
      _targetTiltY = ((e.localPosition.dx - cx) / cx * 52.0).clamp(-58.0, 58.0);
      _targetTiltX = (-(e.localPosition.dy - cy) / cy * 28.0).clamp(-32.0, 32.0);
    });
  }

  void _onPointerExit(PointerEvent _) {
    setState(() { _targetTiltX = 0; _targetTiltY = 8; });
  }

  // ─── Mesh ─────────────────────────────────────────────────────────────────
  static List<_Pt> _build(int total) {
    final out = <_Pt>[];

    // HEAD
    _vol(out, cx:0, cy:-1.72, cz:0, rx:.18, ry:.21, rz:.18, n:400, z:_Zone.neutral, hi:.08);

    // NECK
    _tube(out, x0:0,y0:-1.50,z0:0, x1:0,y1:-1.38,z1:0, r0:.072,r1:.080, n:80, z:_Zone.neutral);

    // TORSO – chest
    _vol(out, cx:0, cy:-1.10, cz:0, rx:.34, ry:.25, rz:.155, n:780, z:_Zone.neutral, hi:.05);
    _vol(out, cx:-.13,cy:-1.08,cz:.09, rx:.12,ry:.11,rz:.06, n:200, z:_Zone.neutral, hi:.22);
    _vol(out, cx: .13,cy:-1.08,cz:.09, rx:.12,ry:.11,rz:.06, n:200, z:_Zone.neutral, hi:.22);
    // Sternum
    _tube(out, x0:0,y0:-1.28,z0:.10, x1:0,y1:-.86,z1:.11, r0:.016,r1:.012, n:55, z:_Zone.neutral);

    // ABS
    for (int row=0;row<3;row++) {
      for (final s in [-1.0,1.0]) {
        _vol(out, cx:s*.082,cy:-.86+row*.125,cz:.11, rx:.056,ry:.047,rz:.036, n:68, z:_Zone.neutral, hi:.25);
      }
    }
    // Obliques
    for (final s in [-1.0,1.0]) {
      _tube(out, x0:s*.28,y0:-.97,z0:.02, x1:s*.32,y1:-.63,z1:-.02, r0:.053,r1:.044, n:110, z:_Zone.neutral);
    }

    // BACK
    _vol(out, cx:0,cy:-1.12,cz:-.12, rx:.32,ry:.23,rz:.08, n:500, z:_Zone.neutral, hi:.07);
    for (final s in [-1.0,1.0]) {
      _tube(out, x0:s*.04,y0:-1.30,z0:-.10, x1:s*.05,y1:-.62,z1:-.11, r0:.048,r1:.038, n:130, z:_Zone.neutral);
    }

    // PELVIS
    _vol(out, cx:0,cy:-.63,cz:0, rx:.28,ry:.10,rz:.13, n:270, z:_Zone.neutral);

    // ── GLUTES (VIOLET) ───────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.13,cy:-.62,cz:-.12, rx:.16,ry:.14,rz:.10, n:320, z:_Zone.glutes, hi:.18);
      // Gluteus medius (top)
      _vol(out, cx:s*.18,cy:-.72,cz:-.08, rx:.09,ry:.09,rz:.07, n:180, z:_Zone.glutes, hi:.22);
    }

    // SHOULDERS
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.38,cy:-1.28,cz:0, rx:.11,ry:.09,rz:.09, n:140, z:_Zone.neutral, hi:.18);
    }

    // ARMS
    for (final s in [-1.0,1.0]) {
      _tube(out, x0:s*.38,y0:-1.22,z0:0, x1:s*.48,y1:-.85,z1:.02, r0:.088,r1:.073, n:270, z:_Zone.neutral);
      _vol(out, cx:s*.43,cy:-1.02,cz:.07, rx:.055,ry:.10,rz:.048, n:150, z:_Zone.neutral, hi:.25);
      _vol(out, cx:s*.43,cy:-1.02,cz:-.06, rx:.05,ry:.09,rz:.04,  n:100, z:_Zone.neutral, hi:.12);
      _vol(out, cx:s*.49,cy:-.83,cz:0, rx:.057,ry:.057,rz:.054, n:60, z:_Zone.neutral);
      _tube(out, x0:s*.50,y0:-.82,z0:0, x1:s*.55,y1:-.48,z1:.01, r0:.060,r1:.041, n:200, z:_Zone.neutral);
      _vol(out, cx:s*.56,cy:-.46,cz:0, rx:.040,ry:.040,rz:.027, n:48, z:_Zone.neutral);
      _vol(out, cx:s*.56,cy:-.38,cz:0, rx:.037,ry:.041,rz:.017, n:52, z:_Zone.neutral);
      for (int f=0;f<4;f++){
        final fx=s*.56+s*(f-1.5)*.016;
        _tube(out, x0:fx,y0:-.34,z0:.005, x1:fx,y1:-.285,z1:.005, r0:.010,r1:.007, n:14, z:_Zone.neutral);
      }
      _tube(out, x0:s*.596,y0:-.36,z0:.010, x1:s*.616,y1:-.32,z1:.012, r0:.011,r1:.008, n:12, z:_Zone.neutral);
    }

    // ── QUADRICEPS (VIOLET) ────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      // Hip connector
      _tube(out, x0:s*.13,y0:-.62,z0:0, x1:s*.16,y1:-.44,z1:0, r0:.155,r1:.166, n:175, z:_Zone.quadriceps);

      // Main quad mass — make extra dense (this is the primary squat muscle)
      _vol(out, cx:s*.17,cy:-.22,cz:.04, rx:.148,ry:.240,rz:.118, n:900, z:_Zone.quadriceps, hi:.14);

      // Vastus lateralis (outer head)
      _vol(out, cx:s*.248,cy:-.20,cz:-.042, rx:.072,ry:.165,rz:.070, n:260, z:_Zone.quadriceps, hi:.22);
      // Vastus medialis (inner teardrop at knee)
      _vol(out, cx:s*.108,cy:-.05,cz:.072, rx:.068,ry:.104,rz:.074, n:240, z:_Zone.quadriceps, hi:.34);
      // Rectus femoris (centre)
      _tube(out, x0:s*.165,y0:-.44,z0:.10, x1:s*.158,y1:-.05,z1:.10, r0:.042,r1:.036, n:170, z:_Zone.quadriceps);

      // Hamstrings
      _vol(out, cx:s*.162,cy:-.20,cz:-.108, rx:.112,ry:.212,rz:.072, n:400, z:_Zone.quadriceps, hi:.10);

      // Adductors (inner thigh)
      _vol(out, cx:s*.065,cy:-.22,cz:.02, rx:.055,ry:.192,rz:.060, n:175, z:_Zone.quadriceps, hi:.08);

      // Quad fiber detail (5 transverse lines)
      for (int fi=0;fi<5;fi++){
        final fy=-.44+fi*.088;
        _tube(out, x0:s*.12,y0:fy,z0:.10, x1:s*.22,y1:fy+.018,z1:.07, r0:.009,r1:.007, n:14, z:_Zone.quadriceps);
      }
    }

    // KNEES
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.16,cy:.048,cz:.040, rx:.088,ry:.072,rz:.078, n:100, z:_Zone.neutral);
    }

    // LOWER LEGS
    for (final s in [-1.0,1.0]) {
      _tube(out, x0:s*.152,y0:.06,z0:.032, x1:s*.147,y1:.55,z1:.024, r0:.077,r1:.043, n:320, z:_Zone.neutral);
      _vol(out, cx:s*.128,cy:.24,cz:-.072, rx:.058,ry:.145,rz:.052, n:240, z:_Zone.neutral, hi:.16);
      _vol(out, cx:s*.175,cy:.25,cz:-.068, rx:.052,ry:.130,rz:.048, n:195, z:_Zone.neutral, hi:.12);
      _vol(out, cx:s*.15,cy:.34,cz:-.09, rx:.060,ry:.102,rz:.040, n:120, z:_Zone.neutral);
      for (int cf=0;cf<4;cf++){
        final fy=.14+cf*.08;
        _tube(out, x0:s*.13,y0:fy,z0:-.06, x1:s*.17,y1:fy+.05,z1:-.065, r0:.007,r1:.005, n:10, z:_Zone.neutral);
      }
    }

    // ANKLES + FEET
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.15,cy:.572,cz:0, rx:.044,ry:.048,rz:.042, n:55, z:_Zone.neutral);
      _vol(out, cx:s*.15,cy:.635,cz:.062, rx:.062,ry:.038,rz:.048, n:85, z:_Zone.neutral);
    }

    return out;
  }

  // ─── Geometry ─────────────────────────────────────────────────────────────
  static void _vol(List<_Pt> out, {
    required double cx,required double cy,required double cz,
    required double rx,required double ry,required double rz,
    required int n, required _Zone z, double hi=0.0}) {
    for (int i=0;i<n;i++){
      final u=_rng.nextDouble(),v=_rng.nextDouble();
      final th=u*2*math.pi, ph=math.acos(2*v-1);
      final r=math.pow(_rng.nextDouble(),1/3.0).toDouble();
      final px=cx+rx*r*math.sin(ph)*math.cos(th);
      final py=cy+ry*r*math.cos(ph);
      final pz=cz+rz*r*math.sin(ph)*math.sin(th);
      final isHi=hi>0.1&&_rng.nextDouble()>0.62;
      final br=(0.50+_rng.nextDouble()*0.50+hi).clamp(0.0,1.0);
      out.add(_Pt(x:px,y:py,z:pz,
        baseSize:isHi?2.5+_rng.nextDouble()*1.2:0.9+_rng.nextDouble()*1.8,
        phase:_rng.nextDouble()*math.pi*2, brightness:br, zone:z, isHighlight:isHi));
    }
  }

  static void _tube(List<_Pt> out, {
    required double x0,required double y0,required double z0,
    required double x1,required double y1,required double z1,
    required double r0,required double r1,required int n,required _Zone z,double hi=0.0}) {
    final dx=x1-x0,dy=y1-y0,dz=z1-z0;
    final len=math.sqrt(dx*dx+dy*dy+dz*dz);
    if(len<1e-6)return;
    final ux=dx/len,uy=dy/len,uz=dz/len;
    double px,py,pz;
    if(ux.abs()<0.9){px=0;py=-uz;pz=uy;}else{px=-uz;py=0;pz=ux;}
    final pL=math.sqrt(px*px+py*py+pz*pz);
    px/=pL;py/=pL;pz/=pL;
    final qx=uy*pz-uz*py,qy=uz*px-ux*pz,qz=ux*py-uy*px;
    for(int i=0;i<n;i++){
      final t=_rng.nextDouble(),th=_rng.nextDouble()*2*math.pi;
      final r=math.sqrt(_rng.nextDouble())*(r0+(r1-r0)*t);
      final mx=x0+ux*len*t,my=y0+uy*len*t,mz=z0+uz*len*t;
      final px2=mx+r*(math.cos(th)*px+math.sin(th)*qx);
      final py2=my+r*(math.cos(th)*py+math.sin(th)*qy);
      final pz2=mz+r*(math.cos(th)*pz+math.sin(th)*qz);
      final br=(0.48+_rng.nextDouble()*0.52+hi).clamp(0.0,1.0);
      out.add(_Pt(x:px2,y:py2,z:pz2,
        baseSize:0.9+_rng.nextDouble()*1.7,
        phase:_rng.nextDouble()*math.pi*2, brightness:br, zone:z, isHighlight:false));
    }
  }

  // ─── Projection ───────────────────────────────────────────────────────────
  // Body y-span: -1.95 → +0.68  (height = 2.63 units)
  // center_y = (-1.95 + 0.68) / 2 = -0.635
  static ({double sx, double sy, double wz}) _proj(
      double x, double y, double z, double rxDeg, double ryDeg, double canvasH) {
    final rxR = rxDeg * math.pi / 180;
    final ryR = ryDeg * math.pi / 180;
    final x1 = x*math.cos(ryR) + z*math.sin(ryR);
    final z1 = -x*math.sin(ryR) + z*math.cos(ryR);
    final y2 = y*math.cos(rxR) - z1*math.sin(rxR);
    final z2 = y*math.sin(rxR) + z1*math.cos(rxR);

    const double bodyH = 2.63;
    const double bodyCenter = -0.635;
    final double scale = (canvasH * 0.86) / bodyH;
    final double persp = 1.0 + z2 * 0.04;

    return (
      sx: x1 * scale * persp,
      sy: (y2 - bodyCenter) * scale * persp,
      wz: z2,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => setState(() { _targetTiltX = 0; _targetTiltY = 8; }),
      child: Listener(
        onPointerMove: _onPointerMove,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SquatPainter(
              particles: _particles,
              tiltX: _tiltX,
              tiltY: _tiltY,
              t: _idle.value * 10,
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
class _SquatPainter extends CustomPainter {
  final List<_Pt> particles;
  final double tiltX, tiltY, t;

  const _SquatPainter({
    required this.particles,
    required this.tiltX,
    required this.tiltY,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pScale = (size.height / 300.0).clamp(0.35, 1.6);

    // Project + sort
    final list = <({_Pt p, double sx, double sy, double wz})>[];
    for (final p in particles) {
      final r = _SquatHumanModelState._proj(p.x, p.y, p.z, tiltX, tiltY, size.height);
      list.add((p: p, sx: r.sx, sy: r.sy, wz: r.wz));
    }
    list.sort((a, b) => a.wz.compareTo(b.wz));

    final paint = Paint()..style = PaintingStyle.fill;

    for (final item in list) {
      final screenX = cx + item.sx;
      final screenY = cy + item.sy;
      if (screenX < -8 || screenX > size.width + 8) continue;
      if (screenY < -8 || screenY > size.height + 8) continue;

      final p = item.p;
      final shimmer = math.sin(t * 2.2 + p.phase) * 0.14;
      final alpha = ((p.brightness + shimmer) * 255).clamp(70, 255).toInt();
      final depthF = (item.wz * 0.12 + 1.0).clamp(0.75, 1.30);
      final sz = p.baseSize * depthF * pScale;

      final Color mid, bright, glow;
      if (p.zone == _Zone.neutral) {
        mid = _kBMid; bright = _kBBright; glow = _kBGlow;
      } else {
        // Quadriceps AND Glutes → violet
        mid = _kVMid; bright = _kVBright; glow = _kVGlow;
      }

      if (p.isHighlight) {
        paint.color = glow.withAlpha((alpha * 0.20).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 2.8, paint);
        paint.color = glow.withAlpha((alpha * 0.42).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 1.7, paint);
        paint.color = bright.withAlpha(alpha);
        canvas.drawCircle(Offset(screenX, screenY), sz, paint);
      } else {
        paint.color = mid.withAlpha((alpha * 0.26).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 1.55, paint);
        paint.color = (p.brightness > 0.72 ? bright : mid).withAlpha(alpha);
        canvas.drawCircle(Offset(screenX, screenY), sz * 0.72, paint);
      }
    }

    // Ground glow
    final gPaint = Paint()
      ..shader = RadialGradient(
        colors: [_kVGlow.withAlpha(22), Colors.transparent],
      ).createShader(Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.36),
          width: size.width * 0.58, height: size.height * 0.10))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * 0.36),
            width: size.width * 0.58, height: size.height * 0.05),
        gPaint);
  }

  @override
  bool shouldRepaint(_SquatPainter old) => true;
}
