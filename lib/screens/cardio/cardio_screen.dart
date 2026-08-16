import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../services/audio_service.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';

enum CardioMode { running, cycling }

class CardioScreen extends StatefulWidget {
  const CardioScreen({Key? key}) : super(key: key);

  @override
  State<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends State<CardioScreen> {
  final AudioService _audioService = AudioService();
  final FirebaseService _firebaseService = FirebaseService();

  CardioMode _selectedMode = CardioMode.running;

  bool _isActive = false;
  bool _isPaused = false;
  int _secondsElapsed = 0;
  double _distanceKm = 0.0;
  Timer? _timer;

  List<ActivityModel> _cardioHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _cardioHistory = _firebaseService.getCardioActivities();
    });
  }

  void _startCardio() {
    _audioService.playStartSound();
    setState(() {
      _isActive = true;
      _isPaused = false;
      _secondsElapsed = 0;
      _distanceKm = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          _secondsElapsed++;
          // Simulerer Strava GPS-distanse i sanntid
          final speedFactor = _selectedMode == CardioMode.running ? 0.0035 : 0.008;
          _distanceKm += speedFactor;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopCardio() async {
    _timer?.cancel();
    _audioService.playFinishSound();

    final isRunning = _selectedMode == CardioMode.running;
    final int earnedCoins = (_distanceKm * 60).round() + 50;

    final activity = ActivityModel(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: isRunning ? 'cardio_running' : 'cardio_cycling',
      distanceKm: double.parse(_distanceKm.toStringAsFixed(2)),
      durationSeconds: _secondsElapsed,
      coinsEarned: earnedCoins,
      moodEmoji: isRunning ? '🏃' : '🚴',
      userComment: 'Gjennomførte ${isRunning ? 'løpeøkt' : 'sykkeløkt'} med Strava GPS!',
      aiReport: 'Fantastisk kardioinnsats! GPS-ruten din er synkronisert.',
      coachComments: [],
    );

    await _firebaseService.addActivity(activity);
    _loadHistory();

    if (mounted) {
      setState(() {
        _isActive = false;
        _isPaused = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Økt lagret! Du tjente +$earnedCoins Mynter! 💰'),
          backgroundColor: const Color(0xFF0446BC),
        ),
      );
    }
  }

  // Detaljert infovindu for kondisjonstrening
  void _showDetailedCardioSheet(ActivityModel item) {
    final isRunning = item.type == 'cardio_running' || item.moodEmoji == '🏃';
    final String modeTitle = isRunning ? 'Løping (Running)' : 'Sykling (Cycling)';
    final String distanceText = item.distanceKm > 0 ? '${item.distanceKm} km' : '4.8 km';
    final String paceText = isRunning ? '5:46 /km' : '22.4 km/t';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(isRunning ? '🏃' : '🚴', style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modeTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatHistoryDate(item.timestamp),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0446BC)),
                  ),
                  child: const Text(
                    'STRAVA GPS ⚡',
                    style: TextStyle(color: Color(0xFF0446BC), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Map Preview Card
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: StravaMapPainter(isCycling: !isRunning),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Metrics 3 Column Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Distanse', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          distanceText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Tid', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          item.formattedDuration != '00:00' ? item.formattedDuration : '24:15',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Gj.snitt Tempo', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          paceText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0446BC)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rewards Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 Mynter opptjent: +${item.coinsEarned}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 15)),
                  Text('🟪 +${item.xpEarned} Level-XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0446BC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('Lukk detaljer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _formattedTimer {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _formattedPace {
    if (_distanceKm <= 0.05 || _secondsElapsed < 5) return '0:00';
    final paceSecondsPerKm = (_secondsElapsed / _distanceKm).round();
    final min = paceSecondsPerKm ~/ 60;
    final sec = (paceSecondsPerKm % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  int get _liveCoins => (_distanceKm * 60).round();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _selectedMode == CardioMode.running;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kardiotrening',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Segment Switcher Pill Button (🏃 Løping vs 🚴 Sykling)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isActive) {
                            setState(() => _selectedMode = CardioMode.running);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isRunning ? const Color(0xFF0446BC) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🏃', style: TextStyle(fontSize: 18, color: isRunning ? Colors.white : const Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              Text(
                                'Løping',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isRunning ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isActive) {
                            setState(() => _selectedMode = CardioMode.cycling);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isRunning ? const Color(0xFF0446BC) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🚴', style: TextStyle(fontSize: 18, color: !isRunning ? Colors.white : const Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              Text(
                                'Sykling',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: !isRunning ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Strava Route Map Preview Card with Gold Badge (occupies ~60-70% active area)
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: StravaMapPainter(isCycling: !isRunning),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0446BC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 18),
                            SizedBox(width: 4),
                            Text(
                              '⚡ 142 Mynter',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Live Metrics Card (Distanse, Tid, Tempo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Distanse', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          '${_distanceKm.toStringAsFixed(2)} km',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Container(height: 40, width: 1, color: const Color(0xFFE2E8F0)),
                    Column(
                      children: [
                        const Text('Tid', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          _formattedTimer,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Container(height: 40, width: 1, color: const Color(0xFFE2E8F0)),
                    Column(
                      children: [
                        const Text('Tempo', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          _formattedPace,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0446BC)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Action Buttons (Start, Pause, Stopp)
              Row(
                children: [
                  if (_isActive) ...[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _stopCardio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF87171),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Stopp', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _togglePause,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(_isPaused ? 'Fortsett' : 'Pause', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _startCardio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0446BC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text(
                            'Start ${isRunning ? 'løpeøkt' : 'sykkeløkt'} 🚀',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),

              // 5. Historikk Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Historikk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Trykk for detaljer', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Cardio History List (Clicking opens Detailed Cardio Sheet!)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cardioHistory.length,
                itemBuilder: (context, index) {
                  final item = _cardioHistory[index];
                  final isRun = item.type == 'cardio_running' || item.moodEmoji == '🏃';
                  final dateText = _formatHistoryDate(item.timestamp);
                  final distText = item.distanceKm > 0 ? '${item.distanceKm} km' : '5.2 km';
                  final timeText = item.formattedDuration != '00:00' ? item.formattedDuration : '28:10';

                  return GestureDetector(
                    onTap: () => _showDetailedCardioSheet(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: isRun
                                  ? Lottie.asset(
                                      'assets/lottie/avatar_runner.json',
                                      width: 32,
                                      height: 32,
                                      errorBuilder: (ctx, err, stack) => const Text('🏃', style: TextStyle(fontSize: 24)),
                                    )
                                  : const Text('🚴', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateText,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$distText · $timeText',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '+${item.coinsEarned} Mynter',
                                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'I dag, ${DateFormat('HH:mm').format(date)}';
    } else if (difference == 1) {
      return 'I går, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('d. MMM, HH:mm', 'nb_NO').format(date);
    }
  }
}

// Strava Route Map Painter (Renders GPS route polyline & points on Oslo map)
class StravaMapPainter extends CustomPainter {
  final bool isCycling;

  StravaMapPainter({required this.isCycling});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE5EFFE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

    final routePaint = Paint()
      ..color = isCycling ? const Color(0xFF9333EA) : const Color(0xFF0284C7)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.55, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.25);
    path.lineTo(size.width * 0.85, size.height * 0.45);

    canvas.drawPath(path, routePaint);

    final startPin = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 7, startPin);

    final endPin = Paint()..color = const Color(0xFFEF4444);
    final endPulse = Paint()..color = const Color(0xFFEF4444).withOpacity(0.3);
    final currentPos = Offset(size.width * 0.85, size.height * 0.45);
    canvas.drawCircle(currentPos, 12, endPulse);
    canvas.drawCircle(currentPos, 6, endPin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
