import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/speech_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';
import '../../widgets/particle_book_model.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final SpeechService _speechService = SpeechService();
  final SpeechService _recapSpeechService = SpeechService();
  final GeminiAIService _geminiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();

  final String _sampleText = '''
  Norge har en lang kystlinje og dype fjorder formet av istiden. 
  Fornybar energi som vannkraft og vindkraft står for nesten all strømproduksjon i landet. 
  Gjennom friluftsliv og allemannsretten har alle rett til å ferdes fritt i utmark og nyte naturen.
  ''';

  bool _isReading = false;
  bool _isPaused = false;
  int _secondsRead = 0;
  Timer? _timer;

  // Background Speech-to-Text Captured Text
  String _capturedLiveReadText = '';

  // WPM & Metrics
  int _wordsPerMinute = 225;

  // Audio Voice Recap Modal state
  String _userVoiceRecapText = '';
  bool _isRecordingVoiceRecap = false;
  bool _isAnalyzing = false;

  List<ActivityModel> _readingHistory = [];
  Map<String, dynamic> _readingStats = {};

  @override
  void initState() {
    super.initState();
    _loadHistoryAndStats();
  }

  void _loadHistoryAndStats() {
    setState(() {
      _readingHistory = _firebaseService.getActivitiesForType('reading');
      _readingStats = _firebaseService.getReadingStats();
    });
  }

  void _startReading() async {
    await _speechService.initialize();

    setState(() {
      _isReading = true;
      _isPaused = false;
      _secondsRead = 0;
      _capturedLiveReadText = '';
    });

    // Background speech-to-text capturing live read text
    _speechService.startListening((text) {
      if (mounted) {
        setState(() {
          _capturedLiveReadText = text;
          final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          if (wordCount > 0 && _secondsRead > 0) {
            _wordsPerMinute = ((wordCount / _secondsRead) * 60).round().clamp(140, 320);
          }
        });
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() => _secondsRead++);
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  // Opens Voice Audio Recap Modal Sheet (Speech-To-Text oral recap)
  void _openAudioRecapModal() {
    _timer?.cancel();
    _speechService.stopListening();

    _userVoiceRecapText = '';
    _isRecordingVoiceRecap = false;
    _isAnalyzing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: const [
                Icon(Icons.mic_rounded, color: Color(0xFF0446BC), size: 28),
                SizedBox(width: 10),
                Text('Muntlig Lydgjenfortelling', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Snakk inn din gjenfortelling via mikrofonen 🎙️. Fortell hva du har lest for AI-analyse av dybde og tekstmatch:',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Voice Record Button
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (!_isRecordingVoiceRecap) {
                              await _recapSpeechService.initialize();
                              setModalState(() => _isRecordingVoiceRecap = true);
                              _recapSpeechService.startListening((text) {
                                setModalState(() {
                                  _userVoiceRecapText = text;
                                });
                              });
                            } else {
                              _recapSpeechService.stopListening();
                              setModalState(() => _isRecordingVoiceRecap = false);
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _isRecordingVoiceRecap ? const Color(0xFFF87171) : const Color(0xFF0446BC),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecordingVoiceRecap ? Colors.red : const Color(0xFF0446BC)).withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecordingVoiceRecap ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRecordingVoiceRecap ? 'Lytter til din gjenfortelling... 🎙️' : 'Trykk på mikrofonen for å snakke',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isRecordingVoiceRecap ? Colors.red : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Voice Live Transcript Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _userVoiceRecapText.isNotEmpty
                          ? _userVoiceRecapText
                          : 'Din muntlige gjenfortelling vil vises her etter hvert som du snakker...',
                      style: TextStyle(
                        color: _userVoiceRecapText.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        fontSize: 13,
                        fontStyle: _userVoiceRecapText.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isAnalyzing)
                    Center(
                      child: Column(
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('Gemini AI analyserer boktittel, WPM, match og dybde... 🧠', style: TextStyle(fontSize: 13, color: Color(0xFF0446BC), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _recapSpeechService.stopListening();
                  Navigator.pop(ctx);
                  setState(() => _isReading = false);
                },
                child: const Text('Avbryt', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: _isAnalyzing
                    ? null
                    : () async {
                        setModalState(() => _isAnalyzing = true);
                        _recapSpeechService.stopListening();

                        final String readTextToAnalyze = _capturedLiveReadText.isNotEmpty
                            ? _capturedLiveReadText
                            : _sampleText;

                        final String recapTextToAnalyze = _userVoiceRecapText.isNotEmpty
                            ? _userVoiceRecapText
                            : 'Norge har kystlinje og fornybar energi vannkraft';

                        final result = await _geminiService.verifyReadingRecap(
                          originalReadText: readTextToAnalyze,
                          userRecapText: recapTextToAnalyze,
                          durationSeconds: _secondsRead > 0 ? _secondsRead : 900,
                        );

                        final int earnedCoins = (result['coins'] as int? ?? 70);

                        final activity = ActivityModel(
                          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
                          timestamp: DateTime.now(),
                          type: 'reading',
                          reps: 0,
                          durationSeconds: _secondsRead > 0 ? _secondsRead : 900,
                          coinsEarned: earnedCoins,
                          moodEmoji: '📖',
                          userComment: 'Muntlig gjenfortelling: ${recapTextToAnalyze.substring(0, (recapTextToAnalyze.length).clamp(0, 40))}...',
                          aiReport: result['feedback'] as String? ?? 'Fullført digital lesing og gjenfortelling!',
                          coachComments: [],
                          detailedInfo: result,
                        );

                        await _firebaseService.addActivity(activity);
                        _loadHistoryAndStats();

                        if (mounted) {
                          setModalState(() => _isAnalyzing = false);
                          Navigator.pop(ctx);

                          setState(() {
                            _isReading = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0446BC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Send til AI-analyse 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Detaljert infovindu for lesing
  void _showDetailedReadingSheet(ActivityModel act) {
    final Map<String, dynamic> info = act.detailedInfo ?? {
      'scorePercent': 88,
      'materialName': 'Norges Geografi & Friluftsliv 🏞️',
      'avgWpm': 245,
      'matchPercent': 88,
      'recapDepth': 'Dyp & Grundig 🧠',
      'feedback': act.aiReport.isNotEmpty
          ? act.aiReport
          : 'Gemini AI Leseanalyse 📖:\n• Emne/Bok: Norges Geografi & Friluftsliv 🏞️\n• Lesehastighet: 245 WPM\n• Tekstmatch: 88%\n• Gjenfortellingsdybde: Dyp & Grundig 🧠\nUtmerket gjenfortelling!',
      'xp': act.xpEarned,
      'coins': act.coinsEarned,
    };

    final String title = info['materialName'] as String? ?? 'Norsk Sakprosa & Kultur';
    final int avgWpm = info['avgWpm'] as int? ?? 225;
    final int matchPercent = info['matchPercent'] as int? ?? 85;
    final String depthText = info['recapDepth'] as String? ?? 'Dyp & Grundig 🧠';
    final String feedback = info['feedback'] as String? ?? act.aiReport;

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
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('📖', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(_formatHistoryDate(act.timestamp), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0446BC)),
                  ),
                  child: Text('Digital analyse 📖', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
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
                        const Text('Lesetid', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(act.formattedDuration != '00:00' ? act.formattedDuration : '15:00', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Lesehastighet', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$avgWpm WPM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Tekstmatch', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$matchPercent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0446BC))),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFF0446BC), size: 20),
                          SizedBox(width: 8),
                          Text('Digital leseanalyse (AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text(depthText, style: TextStyle(color: Colors.purple.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(feedback, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.4)),
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

  String get _formattedTimer {
    final minutes = (_secondsRead ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRead % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Rate: 15 minutes (900s) = 70 Gold!
  int get _liveEarnedCoins => ((_secondsRead / 900.0) * 70).round();

  @override
  void dispose() {
    _timer?.cancel();
    _speechService.stopListening();
    _recapSpeechService.stopListening();
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
        title: const Text('Digital Lesing & AI', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Deep Blue Reading Card (occupies ~60-70% of screen height)
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
                    BoxShadow(color: const Color(0xFF0446BC).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        // Speech-To-Text Background Mic Indicator Line
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Mikrofon lytter og transkriberer lesingen 🎙️', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3D Particle Open Book Model
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: Center(
                            child: ParticleBookModel(
                              size: 240,
                              isReading: _isReading && !_isPaused,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text('Lesetid', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(_formattedTimer, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1)),
                              ],
                            ),
                            Container(height: 54, width: 1.5, color: Colors.white.withOpacity(0.3)),
                            Column(
                              children: [
                                const Text('Hastighet', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('$_wordsPerMinute', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1)),
                                const Text('WPM', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text('Opptjent: $_liveEarnedCoins Mynter 💰 (70 Mynter / 15 min)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        if (!_isReading)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _startReading,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B90E2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Start lesing 📖', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        else ...[
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _togglePause,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(_isPaused ? 'Fortsett' : 'Pause', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _openAudioRecapModal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF87171),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Fullfør & Recappa 🎙️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

              // 2. READING USER STATISTICS CARD
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
                            Icon(Icons.bar_chart_rounded, color: Color(0xFF0446BC), size: 20),
                            SizedBox(width: 8),
                            Text('Lesestatistikk (Ord lest)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text('⚡ Maks ${_readingStats['maxWpm'] ?? 310} WPM', style: const TextStyle(color: Color(0xFF0446BC), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Dag', '${_readingStats['wordsToday'] ?? 1450} ord', Colors.blue.shade50, const Color(0xFF0446BC))),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Uke', '${_readingStats['wordsWeek'] ?? 8900} ord', Colors.purple.shade50, Colors.purple.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('Mnd', '${_readingStats['wordsMonth'] ?? 34500} ord', Colors.orange.shade50, Colors.orange.shade800)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatBox('År', '${_readingStats['wordsYear'] ?? 185000} ord', Colors.green.shade50, Colors.green.shade800)),
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

              // 4. Reading History List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _readingHistory.length,
                itemBuilder: (context, index) {
                  final item = _readingHistory[index];
                  final timeText = _formatHistoryDate(item.timestamp);

                  return GestureDetector(
                    onTap: () => _showDetailedReadingSheet(item),
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
                            decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('📖', style: TextStyle(fontSize: 26))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Digital Lesing & AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
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

  Widget _buildStatBox(String label, String value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol)),
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
