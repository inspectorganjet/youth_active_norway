import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Zone enum
// ─────────────────────────────────────────────────────────────────────────────
enum _Zone { neutral, quadriceps }

// ─────────────────────────────────────────────────────────────────────────────
//  Particle
// ─────────────────────────────────────────────────────────────────────────────
class _P3 {
  final double x, y, z;
  final double baseSize;
  final double phase;
  final double brightness;
  final _Zone zone;
  final bool isHighlight;
  const _P3({
    required this.x, required this.y, required this.z,
    required this.baseSize, required this.phase,
    required this.brightness, required this.zone,
    required this.isHighlight,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Colour palettes
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBMid    = Color(0xFF2979FF);
const Color _kBBright = Color(0xFF82B1FF);
const Color _kBGlow   = Color(0xFF40C4FF);
const Color _kVMid    = Color(0xFFAA00FF);
const Color _kVBright = Color(0xFFEA80FC);
const Color _kVGlow   = Color(0xFFCE93D8);

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────
class NeonHuman3DWidget extends StatefulWidget {
  final double size;
  const NeonHuman3DWidget({super.key, this.size = 300});

  @override
  State<NeonHuman3DWidget> createState() => _NeonHuman3DWidgetState();
}

class _NeonHuman3DWidgetState extends State<NeonHuman3DWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<_P3> _particles;
  double _tiltX = 0.0, _tiltY = 0.0;
  double _targetTiltX = 0.0, _targetTiltY = 0.0;
  double _t = 0.0;

  static const int _kCount = 9000;
  Object? _accelSub;

  @override
  void initState() {
    super.initState();
    _particles = _buildMesh(_kCount);
    try {
      _accelSub = accelerometerEventStream().listen((e) {
        if (!mounted) return;
        setState(() {
          _targetTiltY = (e.x * 7.0).clamp(-55.0, 55.0);
          _targetTiltX = (e.y * 4.5).clamp(-35.0, 35.0);
        });
      });
    } catch (_) {}
    _ticker = createTicker((elapsed) {
      _t = elapsed.inMilliseconds / 1000.0;
      _tiltX += (_targetTiltX - _tiltX) * 0.08;
      _tiltY += (_targetTiltY - _tiltY) * 0.08;
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    try { (_accelSub as dynamic).cancel(); } catch (_) {}
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent e) {
    final cx = widget.size / 2;
    final cy = widget.size / 2;
    setState(() {
      _targetTiltY = ((e.localPosition.dx - cx) / cx * 50.0).clamp(-55.0, 55.0);
      _targetTiltX = (-(e.localPosition.dy - cy) / cy * 30.0).clamp(-35.0, 35.0);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Mesh build — coordinate space:
  //    x: left(-) / right(+),  y: up(-) / down(+),  z: front(-) / back(+)
  //    Body fits in  y ∈ [-1.95, +0.68]  →  total 2.63 units tall
  // ─────────────────────────────────────────────────────────────────────────
  static final math.Random _rng = math.Random(42);

  static List<_P3> _buildMesh(int total) {
    final out = <_P3>[];

    // ── HEAD ──────────────────────────────────────────────────────────────
    _vol(out, cx:0, cy:-1.72, cz:0, rx:.18, ry:.22, rz:.18, n:400, z:_Zone.neutral, hi:.08);

    // ── NECK ──────────────────────────────────────────────────────────────
    _tube(out, ax:0,ay:-1.50,az:0, bx:0,by:-1.38,bz:0, r0:.075,r1:.082, n:90, z:_Zone.neutral);

    // ── CHEST / TORSO ─────────────────────────────────────────────────────
    _vol(out, cx:0, cy:-1.10, cz:0, rx:.34, ry:.25, rz:.16, n:750, z:_Zone.neutral, hi:.05);
    // Pec left / right
    _vol(out, cx:-.14,cy:-1.08,cz:.09, rx:.12,ry:.11,rz:.06, n:200, z:_Zone.neutral, hi:.22);
    _vol(out, cx: .14,cy:-1.08,cz:.09, rx:.12,ry:.11,rz:.06, n:200, z:_Zone.neutral, hi:.22);
    // Sternum line
    _tube(out, ax:0,ay:-1.28,az:.11, bx:0,by:-.87,bz:.12, r0:.018,r1:.014, n:60, z:_Zone.neutral);

    // ── ABS (6-pack + obliques) ────────────────────────────────────────────
    for (int row=0; row<3; row++) {
      for (final s in [-1.0,1.0]) {
        _vol(out, cx:s*.085,cy:-.86+row*.125,cz:.11, rx:.058,ry:.048,rz:.038, n:70, z:_Zone.neutral, hi:.24);
      }
    }
    for (final s in [-1.0,1.0]) {
      _tube(out, ax:s*.29,ay:-.98,az:.02, bx:s*.33,by:-.64,bz:-.02, r0:.055,r1:.045, n:120, z:_Zone.neutral);
    }

    // ── BACK ──────────────────────────────────────────────────────────────
    _vol(out, cx:0,cy:-1.12,cz:-.12, rx:.32,ry:.23,rz:.08, n:500, z:_Zone.neutral, hi:.07);
    // Spine erectors
    for (final s in [-1.0,1.0]) {
      _tube(out, ax:s*.04,ay:-1.30,az:-.10, bx:s*.05,by:-.62,bz:-.12, r0:.05,r1:.04, n:140, z:_Zone.neutral);
    }

    // ── PELVIS / HIPS ─────────────────────────────────────────────────────
    _vol(out, cx:0,cy:-.63,cz:0, rx:.28,ry:.10,rz:.13, n:280, z:_Zone.neutral, hi:0);

    // ── SHOULDERS ─────────────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.38,cy:-1.28,cz:0, rx:.11,ry:.09,rz:.09, n:140, z:_Zone.neutral, hi:.18);
    }

    // ── ARMS ──────────────────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      // Upper arm
      _tube(out, ax:s*.38,ay:-1.22,az:0, bx:s*.48,by:-.85,bz:.02, r0:.088,r1:.074, n:280, z:_Zone.neutral);
      // Bicep bulge
      _vol(out, cx:s*.43,cy:-1.02,cz:.07, rx:.055,ry:.10,rz:.048, n:150, z:_Zone.neutral, hi:.25);
      // Tricep
      _vol(out, cx:s*.43,cy:-1.02,cz:-.06, rx:.05,ry:.09,rz:.04, n:100, z:_Zone.neutral, hi:.12);
      // Elbow
      _vol(out, cx:s*.49,cy:-.83,cz:0, rx:.058,ry:.058,rz:.055, n:65, z:_Zone.neutral);
      // Forearm
      _tube(out, ax:s*.50,ay:-.82,az:0, bx:s*.55,by:-.48,bz:.01, r0:.062,r1:.042, n:210, z:_Zone.neutral);
      // Wrist
      _vol(out, cx:s*.56,cy:-.46,cz:0, rx:.042,ry:.042,rz:.028, n:50, z:_Zone.neutral);
      // Hand (palm + fingers)
      _vol(out, cx:s*.56,cy:-.38,cz:0, rx:.038,ry:.042,rz:.018, n:55, z:_Zone.neutral);
      for (int f=0;f<4;f++) {
        final fx = s*.56 + s*(f-1.5)*.016;
        _tube(out, ax:fx,ay:-.34,az:.005, bx:fx,by:-.285,bz:.005, r0:.011,r1:.008, n:16, z:_Zone.neutral);
      }
      _tube(out, ax:s*.596,ay:-.36,az:.01, bx:s*.616,by:-.32,bz:.012, r0:.012,r1:.009, n:14, z:_Zone.neutral);
    }

    // ── THIGHS / QUADRICEPS (VIOLET) ──────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      // Hip/groin connector
      _tube(out, ax:s*.13,ay:-.61,az:0, bx:s*.16,by:-.44,bz:0, r0:.155,r1:.165, n:180, z:_Zone.quadriceps);

      // Main quad mass
      _vol(out, cx:s*.17,cy:-.22,cz:.04, rx:.145,ry:.235,rz:.115, n:800, z:_Zone.quadriceps, hi:.12);

      // Vastus lateralis (outer)
      _vol(out, cx:s*.245,cy:-.20,cz:-.04, rx:.07,ry:.16,rz:.068, n:240, z:_Zone.quadriceps, hi:.20);
      // Vastus medialis (inner – teardrop at knee)
      _vol(out, cx:s*.108,cy:-.06,cz:.07, rx:.065,ry:.10,rz:.072, n:220, z:_Zone.quadriceps, hi:.32);
      // Rectus femoris (centre stripe)
      _tube(out, ax:s*.165,ay:-.44,az:.10, bx:s*.158,by:-.06,bz:.10, r0:.04,r1:.035, n:160, z:_Zone.quadriceps);

      // Hamstrings (back of thigh)
      _vol(out, cx:s*.162,cy:-.20,cz:-.105, rx:.11,ry:.21,rz:.07, n:380, z:_Zone.quadriceps, hi:.10);

      // Adductors (inner thigh)
      _vol(out, cx:s*.065,cy:-.22,cz:.02, rx:.055,ry:.19,rz:.06, n:160, z:_Zone.quadriceps, hi:.08);

      // Fiber detail lines across quad
      for (int fi=0;fi<5;fi++) {
        final fy = -.44 + fi*.09;
        _tube(out, ax:s*.12,ay:fy,az:.10, bx:s*.22,by:fy+.02,bz:.07, r0:.008,r1:.006, n:12, z:_Zone.quadriceps);
      }
    }

    // ── KNEES ─────────────────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.16,cy:.045,cz:.04, rx:.088,ry:.072,rz:.078, n:100, z:_Zone.neutral);
    }

    // ── LOWER LEGS ────────────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      // Shin
      _tube(out, ax:s*.153,ay:.06,az:.032, bx:s*.148,by:.55,bz:.024, r0:.078,r1:.044, n:320, z:_Zone.neutral);
      // Gastrocnemius medial head
      _vol(out, cx:s*.128,cy:.24,cz:-.072, rx:.058,ry:.145,rz:.052, n:240, z:_Zone.neutral, hi:.16);
      // Gastrocnemius lateral head
      _vol(out, cx:s*.175,cy:.25,cz:-.068, rx:.052,ry:.130,rz:.048, n:200, z:_Zone.neutral, hi:.12);
      // Soleus (behind)
      _vol(out, cx:s*.15,cy:.34,cz:-.09, rx:.06,ry:.10,rz:.04, n:120, z:_Zone.neutral, hi:.08);
      // Calf fibers
      for (int cf=0;cf<4;cf++) {
        final fy = .14+cf*.08;
        _tube(out, ax:s*.13,ay:fy,az:-.06, bx:s*.17,by:fy+.05,bz:-.065, r0:.007,r1:.005, n:10, z:_Zone.neutral);
      }
    }

    // ── ANKLES + FEET ─────────────────────────────────────────────────────
    for (final s in [-1.0,1.0]) {
      _vol(out, cx:s*.15,cy:.572,cz:0, rx:.044,ry:.048,rz:.042, n:55, z:_Zone.neutral);
      _vol(out, cx:s*.15,cy:.635,cz:.062, rx:.062,ry:.038,rz:.048, n:85, z:_Zone.neutral);
    }

    return out;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Geometry primitives
  // ─────────────────────────────────────────────────────────────────────────
  static void _vol(List<_P3> out,{
    required double cx,required double cy,required double cz,
    required double rx,required double ry,required double rz,
    required int n, required _Zone z, double hi=0.0}) {
    for (int i=0;i<n;i++) {
      final u=_rng.nextDouble(), v=_rng.nextDouble();
      final th=u*2*math.pi, ph=math.acos(2*v-1);
      final r=math.pow(_rng.nextDouble(),1/3.0).toDouble();
      final px=cx+rx*r*math.sin(ph)*math.cos(th);
      final py=cy+ry*r*math.cos(ph);
      final pz=cz+rz*r*math.sin(ph)*math.sin(th);
      final isHi=hi>0.1&&_rng.nextDouble()>0.62;
      final br=(0.50+_rng.nextDouble()*0.50+hi).clamp(0.0,1.0);
      out.add(_P3(x:px,y:py,z:pz,
        baseSize:isHi?2.5+_rng.nextDouble()*1.2:0.9+_rng.nextDouble()*1.8,
        phase:_rng.nextDouble()*math.pi*2, brightness:br, zone:z, isHighlight:isHi));
    }
  }

  static void _tube(List<_P3> out,{
    required double ax,required double ay,required double az,
    required double bx,required double by,required double bz,
    required double r0,required double r1,required int n,required _Zone z,double hi=0.0}) {
    final dx=bx-ax,dy=by-ay,dz=bz-az;
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
      final mx=ax+ux*len*t,my=ay+uy*len*t,mz=az+uz*len*t;
      final px2=mx+r*(math.cos(th)*px+math.sin(th)*qx);
      final py2=my+r*(math.cos(th)*py+math.sin(th)*qy);
      final pz2=mz+r*(math.cos(th)*pz+math.sin(th)*qz);
      final br=(0.48+_rng.nextDouble()*0.52+hi).clamp(0.0,1.0);
      out.add(_P3(x:px2,y:py2,z:pz2,
        baseSize:0.9+_rng.nextDouble()*1.7,
        phase:_rng.nextDouble()*math.pi*2, brightness:br, zone:z, isHighlight:false));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Rotation
  //  Body y-span: -1.95 to +0.68  →  center_y = -0.635
  //  scale = (canvas * 0.86) / 2.63  so body fills 86% of canvas height
  // ─────────────────────────────────────────────────────────────────────────
  static ({double sx, double sy, double wz}) _project(
      double x, double y, double z,
      double rxDeg, double ryDeg,
      double canvasH) {
    final rxR = rxDeg * math.pi / 180;
    final ryR = ryDeg * math.pi / 180;

    // Rotate Y
    final x1 = x * math.cos(ryR) + z * math.sin(ryR);
    final z1 = -x * math.sin(ryR) + z * math.cos(ryR);
    // Rotate X
    final y2 = y * math.cos(rxR) - z1 * math.sin(rxR);
    final z2 = y * math.sin(rxR) + z1 * math.cos(rxR);

    // Fixed scale so body fits canvas height
    const double bodyH = 2.63;   // y spans -1.95..+0.68
    const double bodyCenter = -0.635; // (−1.95+0.68)/2
    final double scale = (canvasH * 0.86) / bodyH;

    // Subtle perspective
    final double perspective = 1.0 + z2 * 0.04;

    final sx = x1 * scale * perspective;
    final sy = (y2 - bodyCenter) * scale * perspective;

    return (sx: sx, sy: sy, wz: z2);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _onPointerMove,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _NeonHumanPainter(
            particles: _particles,
            tiltX: _tiltX,
            tiltY: _tiltY,
            t: _t,
            canvasSize: widget.size,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────────────────────
class _NeonHumanPainter extends CustomPainter {
  final List<_P3> particles;
  final double tiltX, tiltY, t, canvasSize;

  _NeonHumanPainter({
    required this.particles,
    required this.tiltX,
    required this.tiltY,
    required this.t,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Project + depth-sort
    final projected = <({_P3 p, double sx, double sy, double wz})>[];
    for (final p in particles) {
      final r = _NeonHuman3DWidgetState._project(
          p.x, p.y, p.z, tiltX, tiltY, size.height);
      projected.add((p: p, sx: r.sx, sy: r.sy, wz: r.wz));
    }
    projected.sort((a, b) => a.wz.compareTo(b.wz));

    final paint = Paint()..style = PaintingStyle.fill;
    // Particle size multiplier: scales with canvas but stays readable on small cards
    final pScale = (size.height / 300.0).clamp(0.35, 1.6);

    for (final item in projected) {
      final p = item.p;
      final screenX = cx + item.sx;
      final screenY = cy + item.sy;

      // Cull offscreen
      if (screenX < -8 || screenX > size.width + 8) continue;
      if (screenY < -8 || screenY > size.height + 8) continue;

      final shimmer = math.sin(t * 2.2 + p.phase) * 0.14;
      final alpha = ((p.brightness + shimmer) * 255).clamp(70, 255).toInt();

      final depthF = (item.wz * 0.12 + 1.0).clamp(0.75, 1.30);
      final sz = p.baseSize * depthF * pScale;

      final Color mid, bright, glow;
      if (p.zone == _Zone.quadriceps) {
        mid = _kVMid; bright = _kVBright; glow = _kVGlow;
      } else {
        mid = _kBMid; bright = _kBBright; glow = _kBGlow;
      }

      if (p.isHighlight) {
        paint.color = glow.withAlpha((alpha * 0.20).toInt());
        canvas.drawCircle(Offset(screenX, screenY), sz * 2.8, paint);
        paint.color = glow.withAlpha((alpha * 0.40).toInt());
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

    // Ground ambient glow
    final gPaint = Paint()
      ..shader = RadialGradient(
        colors: [_kBGlow.withAlpha(25), Colors.transparent],
      ).createShader(Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.36),
          width: size.width * 0.6, height: size.height * 0.10))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * 0.36),
            width: size.width * 0.6, height: size.height * 0.055),
        gPaint);
  }

  @override
  bool shouldRepaint(_NeonHumanPainter old) => true;
}
