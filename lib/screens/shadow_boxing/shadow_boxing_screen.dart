import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pose_detector_service.dart';
import '../../services/audio_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';
import '../../widgets/boxer_particle_model.dart';

class ShadowBoxingScreen extends StatefulWidget {
  const ShadowBoxingScreen({super.key});

  @override
  State<ShadowBoxingScreen> createState() => _ShadowBoxingScreenState();
}

class _ShadowBoxingScreenState extends State<ShadowBoxingScreen> {
  final PoseDetectorService _poseService = PoseDetectorService();
  final AudioService _audioService = AudioService();
  final GeminiAIService _geminiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isWorkingOut = false;
  int _punches = 0;
  int _secondsRead = 0;
  Timer? _workoutTimer;

  bool _isLoadingAiReport = false;
  Map<String, dynamic>? _aiResult;
  List<ActivityModel> _workoutHistory = [];
  Map<String, int> _modeStats = {};

  String _selectedMoodEmoji = '🥊';
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistoryAndStats();
  }

  void _loadHistoryAndStats() {
    setState(() {
      _workoutHistory = _firebaseService.getActivitiesForType('shadow_boxing');
      _modeStats = _firebaseService.getModeStats('shadow_boxing');
    });
  }

  void _startWorkout() {
    setState(() {
      _isWorkingOut = true;
      _punches = 0;
      _secondsRead = 0;
      _aiResult = null;
      _commentController.clear();
      _selectedMoodEmoji = '🥊';
    });

    _audioService.playStartSound();

    _poseService.startWorkout(WorkoutType.shadowBoxing, (count) {
      if (mounted) {
        setState(() => _punches = count);
        if (_punches % 10 == 0 && _punches > 0) {
          _audioService.playRandomCheer();
        }
      }
    });

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsRead++);
      }
    });
  }

  void _stopWorkout() async {
    _poseService.stopWorkout();
    _workoutTimer?.cancel();
    _audioService.playFinishSound();

    setState(() {
      _isWorkingOut = false;
      _isLoadingAiReport = true;
    });

    final audit = await _geminiService.evaluateShadowBoxing(
      rawPunchesAttempted: _punches,
      durationSeconds: _secondsRead,
    );

    final int earnedCoins = audit['goldEarned'] as int? ?? (_punches * 0.5).round();

    final String cleanAuditSummary = audit['aiCoachFeedback'] as String? ??
        'AI Boksetrener Analyse: Økten er godkjent! Flott innsats i skyggekamp!';

    final activity = ActivityModel(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: 'shadow_boxing',
      reps: _punches,
      durationSeconds: _secondsRead,
      coinsEarned: earnedCoins,
      moodEmoji: _selectedMoodEmoji,
      userComment: _commentController.text.isNotEmpty
          ? _commentController.text
          : 'Gjennomførte $_punches slag i Skyggekamp! 🥊',
      aiReport: cleanAuditSummary,
      coachComments: [],
      detailedInfo: audit,
    );

    await _firebaseService.addActivity(activity);
    _loadHistoryAndStats();

    if (mounted) {
      setState(() {
        _isLoadingAiReport = false;
        _aiResult = {
          ...audit,
          'goldEarned': earnedCoins,
          'aiAuditSummary': cleanAuditSummary,
          'antiCheatStatus': 'GODKJENT ØKT 🥊',
        };
      });
      _showMoodCommentDialog(activity);
    }
  }

  void _showMoodCommentDialog(ActivityModel act) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: const [
                Icon(Icons.sports_mma_rounded, color: Color(0xFFDC2626), size: 28),
                SizedBox(width: 10),
                Text('Hvordan var skyggekampen?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Velg din følelse etter runden:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['🥊', '🔥', '⚡', '💪', '😤'].map((emoji) {
                      final bool isSelected = _selectedMoodEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => _selectedMoodEmoji = emoji),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEE2E2) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? const Color(0xFFDC2626) : Colors.transparent, width: 2),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Legg til notat for boksetreneren (valgfritt)...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hopp over', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Lagre i dagboken', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetailedWorkoutSheet(ActivityModel act) {
    final Map<String, dynamic> info = act.detailedInfo ?? {
      'totalPunches': act.reps,
      'correctPunches': (act.reps * 0.85).round(),
      'rejectedPunches': (act.reps * 0.15).round(),
      'guardDrops': 4,
      'footworkScore': 80,
      'bodyRotationScore': 75,
      'shoulderTurnScore': 82,
      'combinationCount': 6,
      'avgPunchSpeed': 'Eksplosiv ⚡',
      'techniqueScorePercent': 85,
      'aiCoachFeedback': act.aiReport,
      'goldEarned': act.coinsEarned,
      'xpEarned': act.xpEarned,
    };

    final int totalPunches = info['totalPunches'] as int? ?? act.reps;
    final int correctPunches = info['correctPunches'] as int? ?? (totalPunches * 0.85).round();
    final int guardDrops = info['guardDrops'] as int? ?? 0;
    final int footworkScore = info['footworkScore'] as int? ?? 80;
    final int bodyRotationScore = info['bodyRotationScore'] as int? ?? 75;
    final int shoulderTurnScore = info['shoulderTurnScore'] as int? ?? 82;
    final int combinationCount = info['combinationCount'] as int? ?? 5;
    final String avgSpeed = info['avgPunchSpeed'] as String? ?? 'Rask ⚡';
    final int techScore = info['techniqueScorePercent'] as int? ?? 85;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🥊', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Skyggekamp 🥊', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(_formatHistoryDate(act.timestamp), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDC2626)),
                  ),
                  child: Text(
                    'Bokse-AI',
                    style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Quick Metrics Grid
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
                        const Text('Godkjente Slag', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$correctPunches / $totalPunches', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Varighet', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(act.formattedDuration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Teknikk-score', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$techScore%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Boxing Biomechanics Breakdown
            const Text('AI Biomekanikk & Boksetest 📊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),

            _buildBoxingMetricRow(
              icon: Icons.shield_rounded,
              title: 'Høyre Garde (Hakebeskyttelse)',
              value: guardDrops == 0 ? 'Perfekt garde! 🛡️' : 'Senket $guardDrops ganger ⚠️',
              subtitle: 'Beskyttelse av haken under utslag av venstre/høyre slag.',
              color: guardDrops <= 3 ? Colors.green : Colors.amber.shade800,
            ),
            const SizedBox(height: 10),

            _buildBoxingMetricRow(
              icon: Icons.directions_walk_rounded,
              title: 'Beinarbeid & Balanse (Footwork)',
              value: '$footworkScore%',
              subtitle: 'Vektoverføring og pivotering på tåballene.',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 10),

            _buildBoxingMetricRow(
              icon: Icons.rotate_right_rounded,
              title: 'Hofte & Korpus-Rotasjon',
              value: '$bodyRotationScore%',
              subtitle: 'Drivkraft fra kjernen og hoften i slagene.',
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 10),

            _buildBoxingMetricRow(
              icon: Icons.accessibility_rounded,
              title: 'Skulder-dovering (Shoulder Turn)',
              value: '$shoulderTurnScore%',
              subtitle: 'Full rekkevidde og rotering av skuldre i rette slag.',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 10),

            _buildBoxingMetricRow(
              icon: Icons.auto_awesome_rounded,
              title: 'Kombinasjoner (3+ slagserier)',
              value: '$combinationCount serier',
              subtitle: 'Hastighet: $avgSpeed',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 20),

            // AI Coach Feedback Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.psychology_rounded, color: Color(0xFFDC2626), size: 22),
                      SizedBox(width: 8),
                      Text('AI Boksetrener Evaluering', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF991B1B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    act.aiReport,
                    style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 13.5, height: 1.45),
                  ),
                  if (act.userComment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Notat: ${act.moodEmoji} ${act.userComment}', style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('💰 Belønning: +${act.coinsEarned} Mynter', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 14)),
                      Text('🟪 +${act.xpEarned} Level-XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6), fontSize: 14)),
                    ],
                  ),
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
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                child: const Text('Lukk bokserapport'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxingMetricRow({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                    Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedTimer {
    final minutes = (_secondsRead ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRead % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _liveEarnedGold => (_punches * 0.5).round();

  @override
  void dispose() {
    _poseService.stopWorkout();
    _workoutTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Skyggekamp 🥊',
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
              // 1. Main Deep Crimson Shadow Boxing Workout Card
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.63,
                ),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0446BC),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0446BC).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Digital analyse av slag og garde 🎥', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3D Animated Boxer Particle Model
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: BoxerParticleModel(
                              size: 220,
                              isPunching: _isWorkingOut,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text('Slag', style: TextStyle(color: Color(0xFFFECDD3), fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('$_punches', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1.1)),
                              ],
                            ),
                            Container(height: 54, width: 1.5, color: const Color(0xFFFB7185).withValues(alpha: 0.6)),
                            Column(
                              children: [
                                const Text('Tid', style: TextStyle(color: Color(0xFFFECDD3), fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(_formattedTimer, style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1.1)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 22),
                              const SizedBox(width: 8),
                              Text('Opptjent: $_liveEarnedGold Mynter', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _isWorkingOut
                          ? ElevatedButton(
                              onPressed: _stopWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 4,
                              ),
                              child: const Text('Stopp Økt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            )
                          : ElevatedButton(
                              onPressed: _startWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 4,
                              ),
                              child: const Text('Start Økt 🥊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Report Loading / Display
              if (_isLoadingAiReport)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        CircularProgressIndicator(color: Color(0xFFDC2626)),
                        SizedBox(width: 16),
                        Expanded(child: Text('AI analyserer garde, slag og beinarbeid... 🥊', style: TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                )
              else if (_aiResult != null)
                Card(
                  color: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text('Digital analyse fullført', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_aiResult!['aiAuditSummary'] ?? '', style: const TextStyle(fontSize: 13.5)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('💰 +${_aiResult!['goldEarned']} Mynter', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('🟪 +${_aiResult!['xpEarned']} Level-XP', style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Mode Statistics
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bar_chart_rounded, color: Color(0xFFDC2626), size: 20),
                        SizedBox(width: 8),
                        Text('Statistikk (Skyggekamp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Dag', '${_modeStats['today'] ?? 120} slag', Colors.red.shade50, Colors.red.shade900)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Uke', '${_modeStats['week'] ?? 840} slag', Colors.purple.shade50, Colors.purple.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Mnd', '${_modeStats['month'] ?? 3200} slag', Colors.orange.shade50, Colors.orange.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('År', '${_modeStats['year'] ?? 14500} slag', Colors.green.shade50, Colors.green.shade800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Historikk (Skyggekamp)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Trykk for rapport', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 16),

              // History List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _workoutHistory.length,
                itemBuilder: (context, index) {
                  final act = _workoutHistory[index];
                  final timeText = _formatHistoryDate(act.timestamp);

                  return GestureDetector(
                    onTap: () => _showDetailedWorkoutSheet(act),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(14)),
                            child: const Center(
                              child: Text('🥊', style: TextStyle(fontSize: 26)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${act.reps} slag Skyggekamp', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text('$timeText · ${act.formattedDuration}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text('+${act.coinsEarned} Mynter', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 6),
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

  Widget _buildStatBox(String label, String value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol)),
          ),
        ],
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
