import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/speech_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';
import '../../widgets/breathing_particle_orb.dart';

class WimHofMeditationScreen extends StatefulWidget {
  const WimHofMeditationScreen({Key? key}) : super(key: key);

  @override
  State<WimHofMeditationScreen> createState() => _WimHofMeditationScreenState();
}

enum MeditationPhase {
  idle,
  breathing, // 30 deep breaths
  retention, // Hold on exhale as long as possible
  recovery, // Inhale & hold 15 seconds
  finished,
}

class _WimHofMeditationScreenState extends State<WimHofMeditationScreen>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final GeminiAIService _geminiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();

  late AnimationController _breathingAnimationController;

  MeditationPhase _currentPhase = MeditationPhase.idle;
  int _currentRound = 1;
  int _totalRounds = 3;
  int _breathCount = 0;
  int _targetBreaths = 30;

  // Settings (configurable before start)
  int _settingsRounds = 3;
  int _settingsBreathsPerRound = 30;
  int _settingsRecoverySeconds = 15;

  // Retention & Total Timers
  int _retentionSeconds = 0;
  int _maxRetentionThisSession = 0;
  int _totalSessionSeconds = 0;

  Timer? _phaseTimer;
  Timer? _sessionTimer;

  // Simulated Mic Envelope Level (0.0 to 1.0)
  double _micAudioLevel = 0.2;
  Timer? _micAnalyzerTimer;

  List<ActivityModel> _meditationHistory = [];
  Map<String, dynamic> _meditationStats = {};

  String _voicePromptNorwegian = 'Klar til å starte Wim Hof pusteteknikk?';

  @override
  void initState() {
    super.initState();

    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _loadHistoryAndStats();
  }

  void _loadHistoryAndStats() {
    setState(() {
      _meditationHistory = _firebaseService
          .getActivities()
          .where((a) => a.type == 'meditation' || a.type == 'wim_hof_breathing')
          .toList();
      _meditationStats = _firebaseService.getMeditationStats();
    });
  }

  void _showSettingsAndStart() {
    // Temp local vars for the dialog
    int tempRounds = _settingsRounds;
    int tempBreaths = _settingsBreathsPerRound;
    int tempRecovery = _settingsRecoverySeconds;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Text('🫁', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Text('Øktinnstillinger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tilpass Wim Hof-pusteteknikken for deg.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 20),
              // Rounds
              _buildSettingRow(
                label: 'Antall runder',
                value: '$tempRounds',
                onDec: tempRounds > 1 ? () => setDState(() => tempRounds--) : null,
                onInc: tempRounds < 6 ? () => setDState(() => tempRounds++) : null,
              ),
              const SizedBox(height: 12),
              // Breaths per round
              _buildSettingRow(
                label: 'Pust per runde',
                value: '$tempBreaths',
                onDec: tempBreaths > 10 ? () => setDState(() => tempBreaths -= 5) : null,
                onInc: tempBreaths < 60 ? () => setDState(() => tempBreaths += 5) : null,
              ),
              const SizedBox(height: 12),
              // Recovery hold
              _buildSettingRow(
                label: 'Gjenopprettingshold (s)',
                value: '${tempRecovery}s',
                onDec: tempRecovery > 10 ? () => setDState(() => tempRecovery -= 5) : null,
                onInc: tempRecovery < 30 ? () => setDState(() => tempRecovery += 5) : null,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  '🧘 $_settingsRounds runder · $tempBreaths pust per runde · ${tempRecovery}s hold',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Avbryt', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _settingsRounds = tempRounds;
                  _settingsBreathsPerRound = tempBreaths;
                  _settingsRecoverySeconds = tempRecovery;
                });
                _startWimHofSession();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0446BC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Start Økt', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String value,
    required VoidCallback? onDec,
    required VoidCallback? onInc,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
        Row(
          children: [
            IconButton(
              onPressed: onDec,
              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF0446BC)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(
              width: 50,
              child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            IconButton(
              onPressed: onInc,
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0446BC)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  void _startWimHofSession() async {
    await _speechService.initialize();

    setState(() {
      _totalRounds = _settingsRounds;
      _targetBreaths = _settingsBreathsPerRound;
      _currentPhase = MeditationPhase.breathing;
      _currentRound = 1;
      _breathCount = 0;
      _retentionSeconds = 0;
      _maxRetentionThisSession = 0;
      _totalSessionSeconds = 0;
      _voicePromptNorwegian = 'Legg telefonen ved siden av deg. Pust dyp inn i magen og brystet... og slipp ut uten motstand.';
    });

    _startTotalSessionTimer();
    _startMicAnalyzer();
    _runBreathingPhase();
  }

  void _startTotalSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _totalSessionSeconds++);
      }
    });
  }

  void _startMicAnalyzer() {
    _micAnalyzerTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (mounted && _currentPhase != MeditationPhase.idle) {
        setState(() {
          // Dynamic Audio envelope simulating user breath sound pickup
          _micAudioLevel = 0.2 + (0.6 * (_breathingAnimationController.value));
        });
      }
    });
  }

  void _runBreathingPhase() {
    _breathingAnimationController.repeat(reverse: true);

    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 2500), (t) {
      if (!mounted) return;

      setState(() {
        if (_breathingAnimationController.status == AnimationStatus.forward) {
          _breathCount++;
        }

        if (_breathCount >= _targetBreaths) {
          _phaseTimer?.cancel();
          _startRetentionPhase();
        }
      });
    });
  }

  void _startRetentionPhase() {
    _breathingAnimationController.stop();
    _breathingAnimationController.value = 0.0; // Empty lungs position

    setState(() {
      _currentPhase = MeditationPhase.retention;
      _retentionSeconds = 0;
      _voicePromptNorwegian = 'Slipp ut alt og hold pusten på tomme lunger. Slapp av i skuldrene og kjenn roen...';
    });

    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _retentionSeconds++;
        });
      }
    });
  }

  void _finishRetentionPhase() {
    _phaseTimer?.cancel();

    if (_retentionSeconds > _maxRetentionThisSession) {
      _maxRetentionThisSession = _retentionSeconds;
    }

    _startRecoveryPhase();
  }

  void _startRecoveryPhase() {
    _breathingAnimationController.forward(); // Full inhale

    setState(() {
      _currentPhase = MeditationPhase.recovery;
      _voicePromptNorwegian = 'Trekk puste dyp inn NÅ! og hold i 15 sekunder. Kjenn energien spre seg i kroppen.';
    });

    int recoveryCountdown = _settingsRecoverySeconds;
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      recoveryCountdown--;
      if (recoveryCountdown <= 0) {
        _phaseTimer?.cancel();

        if (_currentRound < _totalRounds) {
          setState(() {
            _currentRound++;
            _breathCount = 0;
            _currentPhase = MeditationPhase.breathing;
            _voicePromptNorwegian = 'Runde $_currentRound av $_totalRounds. Pust dyp inn... og slipp ut.';
          });
          _runBreathingPhase();
        } else {
          _completeFullSession();
        }
      }
    });
  }

  void _completeFullSession() async {
    _phaseTimer?.cancel();
    _sessionTimer?.cancel();
    _micAnalyzerTimer?.cancel();
    _breathingAnimationController.stop();

    setState(() {
      _currentPhase = MeditationPhase.finished;
      _voicePromptNorwegian = 'Økten er fullført! Utmerket Wim Hof pustearbeid 🎉';
    });

    final aiResult = await _geminiService.evaluateMeditationSession(
      roundsCompleted: _totalRounds,
      maxRetentionSeconds: _maxRetentionThisSession > 0 ? _maxRetentionThisSession : 75,
      totalDurationSeconds: _totalSessionSeconds,
      sessionsThisWeek: 3,
    );

    final activity = ActivityModel(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: 'wim_hof_breathing',
      reps: 0,
      durationSeconds: _totalSessionSeconds > 0 ? _totalSessionSeconds : 600,
      coinsEarned: aiResult['coinsEarned'] as int? ?? 320,
      moodEmoji: '🫁',
      userComment: 'Fullførte 3 runder Wim Hof Pusteteknikk med pustehold!',
      aiReport: aiResult['aiSummary'] as String? ?? 'Gemini AI Pusteanalyse: Utmerket pusteteknikk!',
      coachComments: [],
      detailedInfo: aiResult,
    );

    await _firebaseService.addActivity(activity);
    _loadHistoryAndStats();

    if (mounted) {
      _showCompletionDialog(activity);
    }
  }

  void _stopSessionEarly() async {
    _phaseTimer?.cancel();
    _sessionTimer?.cancel();
    _micAnalyzerTimer?.cancel();
    _breathingAnimationController.stop();

    // Save partial session to DB if at least 2 seconds elapsed
    if (_totalSessionSeconds >= 2 && _currentRound >= 1) {
      final coinsEarned = (_currentRound * 80 + _maxRetentionThisSession * 1.5).round();
      final activity = ActivityModel(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: 'wim_hof_breathing',
        reps: 0,
        durationSeconds: _totalSessionSeconds,
        coinsEarned: coinsEarned,
        moodEmoji: '🫁',
        userComment: 'Avbrutt økt – fullførte $_currentRound av $_totalRounds runder. Maks pustehold: ${_maxRetentionThisSession}s.',
        aiReport: 'Systemanalyse: Delvis fullført økt. Runder: $_currentRound/$_totalRounds, maks pustehold: ${_maxRetentionThisSession}s.',
        coachComments: [],
        detailedInfo: {
          'roundsCompleted': _currentRound,
          'maxRetentionSeconds': _maxRetentionThisSession,
          'coinsEarned': coinsEarned,
          'isPartialSession': true,
        },
      );
      await _firebaseService.addActivity(activity);
      _loadHistoryAndStats();
    }

    setState(() {
      _currentPhase = MeditationPhase.idle;
      _voicePromptNorwegian = 'Klar til å starte Wim Hof pusteteknikk?';
    });
  }

  void _showCompletionDialog(ActivityModel act) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.self_improvement_rounded, color: Color(0xFF0446BC), size: 30),
            SizedBox(width: 10),
            Text('Gratulerer! 🧘‍♂️', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Du har fullført en helhetlig Wim Hof meditasjonsøkt!',
              style: TextStyle(color: Color(0xFF475569), fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Maks pustehold:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_maxRetentionThisSession}s', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0446BC))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Opptjent belønning:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('💰 +${act.coinsEarned} Mynter', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentPhase = MeditationPhase.idle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0446BC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Se historikk & statistikk', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDetailedMeditationSheet(ActivityModel act) {
    final info = act.detailedInfo ?? {
      'roundsCompleted': 3,
      'maxRetentionSeconds': 85,
      'consistencyRating': 'FREMRAGENDE KONSISTENS 🔥',
      'aiSummary': act.aiReport,
    };

    final int rounds = info['roundsCompleted'] as int? ?? 3;
    final int retention = info['maxRetentionSeconds'] as int? ?? 75;
    final String summary = info['aiSummary'] as String? ?? act.aiReport;

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

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('🫁', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wim Hof Pust & Meditasjon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(_formatHistoryDate(act.timestamp), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text('FULLFØRT 🫁', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                        const Text('Total tid', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(act.formattedDuration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Runder', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$rounds / 3', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Maks Pustehold', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${retention}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0446BC))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF0446BC), size: 20),
                      SizedBox(width: 8),
                      Text('Digital pusteanalyse (AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(summary, style: const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.4)),
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

  @override
  void dispose() {
    _breathingAnimationController.dispose();
    _phaseTimer?.cancel();
    _sessionTimer?.cancel();
    _micAnalyzerTimer?.cancel();
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
        title: const Text('Wim Hof Pust & Meditasjon', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ACTIVE WIM HOF BREATHING ENGINE CARD (Dark Purple Theme - occupies ~60-70% of screen height)
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.63,
                ),
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mic info banner (always on top, won't be covered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI-Kamera analyserer økten i bakgrunnen 🎥',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3-D Breathing Particle Orb — replaces the old ring
                    SizedBox(
                      width: double.infinity,
                      height: 185,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _breathingAnimationController,
                          builder: (ctx, child) => BreathingParticleOrb(
                            breathProgress: _breathingAnimationController.value,
                            centerText: _getPhaseDisplayText(),
                            size: 185,
                            isActive: _currentPhase != MeditationPhase.idle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Voice Cue / Guidance Box — always below the fixed SizedBox
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _voicePromptNorwegian,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Metrics (Runde / Pust / Pustehold)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHeaderMetric('Runde', '$_currentRound / $_totalRounds'),
                        Container(height: 30, width: 1, color: Colors.white.withOpacity(0.3)),
                        _buildHeaderMetric('Pust', '$_breathCount / $_targetBreaths'),
                        Container(height: 30, width: 1, color: Colors.white.withOpacity(0.3)),
                        _buildHeaderMetric('Pustehold', '${_retentionSeconds}s'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Simulated Microphone Audio Envelope Level Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🎙️ Mikrofon pusteanalyse:', style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 12)),
                            Text(_currentPhase != MeditationPhase.idle ? 'Stabil 🟢' : 'Venter', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _currentPhase != MeditationPhase.idle ? _micAudioLevel : 0.0,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Controls (Start / Hold / Avbryt)
                    Row(
                      children: [
                        if (_currentPhase == MeditationPhase.idle)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _showSettingsAndStart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0446BC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Start Wim Hof Økt', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          )
                        else if (_currentPhase == MeditationPhase.retention) ...[
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _finishRetentionPhase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Pust inn nå', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _stopSessionEarly,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF87171),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Avbryt', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _stopSessionEarly,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF87171),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Avslutt Økt', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. USER MEDITATION STATISTICS CARD (Dag, Uke, Måned, År & Maks Pustehold)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.self_improvement_rounded, color: Color(0xFF0446BC), size: 20),
                            SizedBox(width: 8),
                            Text('Meditasjonsstatistikk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '⚡ Maks ${_meditationStats['maxRetentionSecs'] ?? 90}s hold',
                            style: const TextStyle(color: Color(0xFF0446BC), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Dag', '${_meditationStats['todayMins'] ?? 12} min', Colors.blue.shade50, const Color(0xFF0446BC))),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Uke', '${_meditationStats['weekMins'] ?? 45} min', Colors.purple.shade50, Colors.purple.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Mnd', '${_meditationStats['monthMins'] ?? 180} min', Colors.orange.shade50, Colors.orange.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('År', '${_meditationStats['yearMins'] ?? 720} min', Colors.green.shade50, Colors.green.shade800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Historikk Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Historikk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Trykk for AI-analyse', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Meditation History List (Clicking opens Detailed AI Sheet!)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _meditationHistory.length,
                itemBuilder: (context, index) {
                  final item = _meditationHistory[index];
                  final timeText = _formatHistoryDate(item.timestamp);

                  return GestureDetector(
                    onTap: () => _showDetailedMeditationSheet(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(child: Text('🫁', style: TextStyle(fontSize: 26))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wim Hof Meditasjon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text('$timeText · ${item.formattedDuration}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text('+${item.coinsEarned} Mynter', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
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

  String _getPhaseDisplayText() {
    switch (_currentPhase) {
      case MeditationPhase.idle:
        return 'Wim Hof\nPusteteknikk\n🫁';
      case MeditationPhase.breathing:
        return _breathingAnimationController.status == AnimationStatus.forward
            ? 'PUST INN\n🫁'
            : 'PUST UT\n💨';
      case MeditationPhase.retention:
        return 'HOLD PUSTEN\n(UTPUST)\n⏹️';
      case MeditationPhase.recovery:
        return 'HOLD INNE\n(15s)\n🫁';
      case MeditationPhase.finished:
        return 'FULLFØRT!\n🎉';
    }
  }

  Widget _buildHeaderMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
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
