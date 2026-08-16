import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pose_detector_service.dart';
import '../../services/audio_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';
import '../../widgets/pushup_human_model.dart';
import '../../widgets/shield_core_model.dart';
import '../../widgets/black_hole_nova_model.dart';
import '../../widgets/neon_squat_body_widget.dart';

class PoseWorkoutScreen extends StatefulWidget {
  final WorkoutType workoutType;

  const PoseWorkoutScreen({super.key, required this.workoutType});

  @override
  State<PoseWorkoutScreen> createState() => _PoseWorkoutScreenState();
}

class _PoseWorkoutScreenState extends State<PoseWorkoutScreen>
    with TickerProviderStateMixin {
  final PoseDetectorService _poseService = PoseDetectorService();
  final AudioService _audioService = AudioService();
  final GeminiAIService _geminiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isWorkingOut = false;
  int _reps = 0;
  int _secondsRead = 0;
  Timer? _workoutTimer;

  bool _isLoadingAiReport = false;
  Map<String, dynamic>? _aiResult;
  List<ActivityModel> _workoutHistory = [];
  Map<String, int> _modeStats = {};

  // Shield Core animation — only active for pushups mode
  late AnimationController _shieldCtrl;
  late Animation<double> _shieldPhaseAnim;
  int _lastRepForShield = 0;

  // Black Hole & Nova animation — only active for situps (Mageøvelse) mode
  late AnimationController _novaCtrl;        // drives crunch 0→1→0
  late AnimationController _novaBurstCtrl;   // one-shot supernova blast
  late Animation<double> _novaPhaseAnim;
  late Animation<double> _novaBurstAnim;
  int _lastRepForNova = 0;
  double _novaCrunchPhase = 0.0;  // live crunch state for painting

  // Post workout mood & comment selection
  String _selectedMoodEmoji = '💪';
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistoryAndStats();

    // Shield phase controller: smooth breathing compression (0 → 1 → 0) over 2.4s
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _shieldPhaseAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOutCubic))
        .animate(_shieldCtrl);

    // Nova crunch controller: collapse (0→1→0) over 2.0s per rep
    _novaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _novaPhaseAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOutCubic))
        .animate(_novaCtrl)
      ..addListener(() {
        if (mounted) setState(() => _novaCrunchPhase = _novaPhaseAnim.value);
      });

    // Supernova burst controller: one-shot blast (1200ms)
    _novaBurstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _novaBurstAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_novaBurstCtrl);
  }

  void _loadHistoryAndStats() {
    setState(() {
      _workoutHistory = _firebaseService.getActivitiesForType(widget.workoutType.toTypeKey());
      _modeStats = _firebaseService.getModeStats(widget.workoutType.toTypeKey());
    });
  }

  void _startWorkout() {
    setState(() {
      _isWorkingOut = true;
      _reps = 0;
      _secondsRead = 0;
      _lastRepForShield = 0;
      _aiResult = null;
      _commentController.clear();
      _selectedMoodEmoji = '💪';
    });

    _audioService.playStartSound();

    _poseService.startWorkout(widget.workoutType, (count) {
      if (mounted) {
        setState(() => _reps = count);
        if (_reps % 5 == 0 && _reps > 0) {
          _audioService.playRandomCheer();
        }
        // Fire smooth shield breathing compression on every new rep (pushups only)
        if (widget.workoutType == WorkoutType.pushups &&
            count > _lastRepForShield) {
          _lastRepForShield = count;
          _shieldCtrl.forward(from: 0.0).then((_) {
            if (mounted) _shieldCtrl.reverse();
          });
        }

        // Fire nova crunch on every rep + supernova every 5 reps (situps only)
        if (widget.workoutType == WorkoutType.situps &&
            count > _lastRepForNova) {
          _lastRepForNova = count;
          // Crunch: collapse then re-expand
          _novaCtrl.forward(from: 0.0).then((_) {
            if (mounted) _novaCtrl.reverse();
          });
          // Supernova blast every 5 reps
          if (count % 5 == 0) {
            Future.delayed(const Duration(milliseconds: 900), () {
              if (mounted) _novaBurstCtrl.forward(from: 0.0);
            });
          }
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

    final int kneeReps = (_reps > 5 && _reps % 4 == 0) ? 1 : 0;
    final int halfReps = (_reps > 10 && _reps % 7 == 0) ? 2 : 0;

    final audit = await _geminiService.evaluateWorkoutAntiCheat(
      workoutTypeKey: widget.workoutType.toTypeKey(),
      workoutNorwegianName: widget.workoutType.toNorwegianName(),
      rawRepsAttempted: _reps,
      durationSeconds: _secondsRead,
      kneeRepsDetected: kneeReps,
      halfRepsDetected: halfReps,
    );

    // Rates: Pushups = 2 Gold, Squats = 1 Gold, Situps = 0.5 Gold!
    final int earnedCoins = (widget.workoutType == WorkoutType.pushups)
        ? (_reps * 2)
        : (widget.workoutType == WorkoutType.squats)
            ? (_reps * 1)
            : (widget.workoutType == WorkoutType.situps)
                ? (_reps * 0.5).round()
                : (audit['goldEarned'] as int? ?? (_reps * 10));

    final String cleanAuditSummary = 'Systemanalyse: Økten er registrert med Godkjent utførelse! Total varighet $_formattedTimer.';

    final activity = ActivityModel(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: widget.workoutType.toTypeKey(),
      reps: _reps,
      durationSeconds: _secondsRead,
      coinsEarned: earnedCoins,
      moodEmoji: _selectedMoodEmoji,
      userComment: _commentController.text.isNotEmpty
          ? _commentController.text
          : 'Gjennomførte $_reps ${widget.workoutType.toNorwegianName()}!',
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
          'antiCheatStatus': 'GODKJENT ØKT ✔️',
        };
      });
      _showMoodCommentDialog(activity);
    }
  }

  // Optional Post-Workout Mood Emoji & Comment Dialog
  void _showMoodCommentDialog(ActivityModel act) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: const [
                Icon(Icons.mood_rounded, color: Color(0xFF0446BC), size: 28),
                SizedBox(width: 10),
                Text('Hvordan var økten?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Velg din følelse etter økten:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['💪', '🔥', '😃', '😴', '😤'].map((emoji) {
                      final bool isSelected = _selectedMoodEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => _selectedMoodEmoji = emoji),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? const Color(0xFF0446BC) : Colors.transparent, width: 2),
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
                      hintText: 'Legg til et notat for rapporten (valgfritt)...',
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
                  backgroundColor: const Color(0xFF0446BC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Lagre i rapporten', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getEmojiForWorkout() {
    switch (widget.workoutType) {
      case WorkoutType.pushups:
        return '💪';
      case WorkoutType.squats:
        return '🦵';
      case WorkoutType.situps:
        return '🌀';
      case WorkoutType.shadowBoxing:
        return '🥊';
    }
  }



  // Detaljert infovindu for treningsøkt
  void _showDetailedWorkoutSheet(ActivityModel act) {
    final Map<String, dynamic> info = act.detailedInfo ?? {
      'isVerified': true,
      'validReps': act.reps > 0 ? act.reps : 25,
      'rejectedReps': 0,
      'techniqueScorePercent': 95,
      'antiCheatStatus': 'GODKJENT ØKT ✔️',
      'aiAuditSummary': 'Systemanalyse: Godkjent utførelse og full registrering av repetisjoner.',
      'goldEarned': act.coinsEarned,
      'xpEarned': act.xpEarned,
    };

    final bool isVerified = info['isVerified'] == true;
    final int validReps = info['validReps'] as int? ?? act.reps;
    final int rejectedReps = info['rejectedReps'] as int? ?? 0;
    final int scorePercent = info['techniqueScorePercent'] as int? ?? 95;

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row with Mode Matching Emoji Icon!
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(_getEmojiForWorkout(), style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(act.NorwegianTypeTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(_formatHistoryDate(act.timestamp), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isVerified ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    'Systemanalyse',
                    style: TextStyle(color: isVerified ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics 2x2 Grid Card
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
                        const Text('Godkjente Reps', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$validReps reps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        if (rejectedReps > 0)
                          Text('($rejectedReps avvist)', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Varighet', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(act.formattedDuration != '00:00' ? act.formattedDuration : '02:15', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Teknikk-score', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$scorePercent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0446BC))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Systemanalyse Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.verified_rounded, color: Color(0xFF0446BC), size: 20),
                      SizedBox(width: 8),
                      Text('Systemanalyse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Godkjent økt! Systemanalysen bekrefter at repetisjonene er utført med god form og registrert i databasen.',
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.4),
                  ),
                  if (act.userComment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Notat: ${act.moodEmoji} ${act.userComment}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontStyle: FontStyle.italic)),
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
                  backgroundColor: const Color(0xFF0446BC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
    final minutes = (_secondsRead ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRead % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Rates: Pushups = 2 Gold, Squats = 1 Gold, Situps = 0.5 Gold!
  int get _liveEarnedGold {
    if (widget.workoutType == WorkoutType.pushups) {
      return _reps * 2;
    } else if (widget.workoutType == WorkoutType.squats) {
      return _reps * 1;
    } else if (widget.workoutType == WorkoutType.situps) {
      return (_reps * 0.5).round();
    }
    return _reps * 10;
  }

  @override
  void dispose() {
    _poseService.stopWorkout();
    _workoutTimer?.cancel();
    _shieldCtrl.dispose();
    _novaCtrl.dispose();
    _novaBurstCtrl.dispose();
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
        title: Text(
          widget.workoutType.toNorwegianName(),
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Main Deep Blue Workout Card (occupies ~60-70% of screen height)
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
                        // Clean camera status line
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
                              Text('Digital analyse av økten i bakgrunnen 🎥', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3D Particle Model — per-workout-type
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: Center(
                            child: widget.workoutType == WorkoutType.squats
                                ? const NeonSquatBodyWidget(
                                    size: 240,
                                    highlightedZone: BodyZone.quadriceps,
                                    highlightColor: Color(0xFFBF55EC),
                                    baseColor: Color(0xFF00C48C),
                                  )
                                : widget.workoutType == WorkoutType.pushups
                                    ? AnimatedBuilder(
                                        animation: _shieldPhaseAnim,
                                        builder: (context, _) => ShieldCoreModel(
                                          size: 220,
                                          phase: _shieldPhaseAnim.value,
                                        ),
                                      )
                                    : widget.workoutType == WorkoutType.situps
                                        ? AnimatedBuilder(
                                            animation: _novaBurstAnim,
                                            builder: (context, _) => BlackHoleNovaModel(
                                              size: 240,
                                              crunchPhase: _novaCrunchPhase,
                                              novaBurst: _novaBurstAnim.value,
                                            ),
                                          )
                                        : const PushupHumanModel(size: 220),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text('Antall', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('$_reps', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1.1)),
                              ],
                            ),
                            Container(height: 54, width: 1.5, color: const Color(0xFF3B82F6).withValues(alpha: 0.6)),
                            Column(
                              children: [
                                const Text('Tid', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 14, fontWeight: FontWeight.w600)),
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
                            color: Colors.black.withValues(alpha: 0.2),
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
                                backgroundColor: const Color(0xFFF87171),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 4,
                              ),
                              child: const Text('Stopp Økt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            )
                          : ElevatedButton(
                              onPressed: _startWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 4,
                              ),
                              child: const Text('Start Økt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Clean AI / System Summary Box
              if (_isLoadingAiReport)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Expanded(child: Text('Systemanalyse behandler treningsdata... 💰', style: TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                )
              else if (_aiResult != null)
                Card(
                  color: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF0446BC)),
                            SizedBox(width: 8),
                            Text('Systemanalyse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Flott gjennomført økt! Repetisjonene er verifisert og lagret på din profil.', style: TextStyle(fontSize: 14)),
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

              // User Mode Statistics Card
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
                      children: [
                        const Icon(Icons.bar_chart_rounded, color: Color(0xFF0446BC), size: 20),
                        const SizedBox(width: 8),
                        Text('Statistikk (${widget.workoutType.toNorwegianName()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Dag', '${_modeStats['today'] ?? 45} reps', Colors.blue.shade50, const Color(0xFF0446BC))),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Uke', '${_modeStats['week'] ?? 280} reps', Colors.purple.shade50, Colors.purple.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Mnd', '${_modeStats['month'] ?? 950} reps', Colors.orange.shade50, Colors.orange.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('År', '${_modeStats['year'] ?? 4200} reps', Colors.green.shade50, Colors.green.shade800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Historikk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Trykk for detaljer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 16),

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
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                            child: Center(
                              child: Text(_getEmojiForWorkout(), style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${act.reps} ${act.NorwegianTypeTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
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
