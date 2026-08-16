import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/universal_avatar_widget.dart';
import '../../widgets/particle_robot_model.dart';

class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({Key? key}) : super(key: key);

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final GeminiAIService _geminiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatSessionItem? _activeSession;
  List<ChatSessionItem> _pastSessions = [];
  bool _isSending = false;

  String _userAvatarPath = 'assets/lottie/avatar_runner.json';

  @override
  void initState() {
    super.initState();
    _userAvatarPath = _firebaseService.currentUser?.activeAvatarLottie ?? 'assets/lottie/avatar_runner.json';
    _loadChatSessions();
  }

  void _loadChatSessions() {
    final sessions = _firebaseService.getChatSessions();
    setState(() {
      _pastSessions = sessions;
    });
  }

  void _startNewChat() {
    final newSession = ChatSessionItem(
      id: 'cs_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Ny samtale',
      lastTimestamp: DateTime.now(),
      iconEmoji: '💬',
      category: 'useful',
      messages: [],
    );
    _firebaseService.addChatSession(newSession);
    setState(() {
      _activeSession = newSession;
      _pastSessions = _firebaseService.getChatSessions();
    });
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_activeSession == null) _startNewChat();
    _inputController.clear();

    final isFirstMessage = _activeSession!.messages.isEmpty;
    final meta = _firebaseService.generateSessionMeta(text);
    final msgCategory = meta['category']!;

    if (isFirstMessage) {
      final updated = ChatSessionItem(
        id: _activeSession!.id,
        title: meta['title']!,
        lastTimestamp: DateTime.now(),
        iconEmoji: meta['emoji']!,
        category: msgCategory,
        messages: List.from(_activeSession!.messages),
      );
      setState(() => _activeSession = updated);
    }

    final userMsg = ChatMessageItem(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      category: msgCategory,
    );

    setState(() {
      _activeSession!.messages.add(userMsg);
      _isSending = true;
    });
    _scrollToBottom();

    final lower = text.toLowerCase();
    String chosenLottie = 'assets/lottie/avatar_runner.json';
    if (lower.contains('armheving') || lower.contains('styrke') || lower.contains('trening')) {
      chosenLottie = 'assets/lottie/avatar_hero.json';
    } else if (lower.contains('spill') || lower.contains('game') || lower.contains('minecraft')) {
      chosenLottie = 'assets/lottie/avatar_dragon.json';
    }

    final aiResponseText = await _geminiService.getMentorChatResponse(text);

    final aiMsg = ChatMessageItem(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: aiResponseText,
      isUser: false,
      timestamp: DateTime.now(),
      lottiePath: chosenLottie,
      category: msgCategory,
    );

    _firebaseService.addMessageToActiveSession(_activeSession!.id, userMsg, aiMsg);

    if (mounted) {
      setState(() {
        _activeSession!.messages.add(aiMsg);
        _isSending = false;
        _pastSessions = _firebaseService.getChatSessions();
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAllSessionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alle samtaler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                '${_pastSessions.length} samtaler totalt',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _legendChip('Nyttig', const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _legendChip('Moro', const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _legendChip('Flagget', const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _pastSessions.length,
                  itemBuilder: (_, i) => _buildSessionCard(
                    _pastSessions[i],
                    onTap: () {
                      setState(() => _activeSession = _pastSessions[i]);
                      Navigator.pop(ctx);
                      _scrollToBottom();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Color _catColor(String cat) {
    if (cat == 'fun') return const Color(0xFFF59E0B);
    if (cat == 'dangerous') return const Color(0xFFEF4444);
    return const Color(0xFF10B981);
  }

  String _catLabel(String cat) {
    if (cat == 'fun') return 'Moro';
    if (cat == 'dangerous') return 'Flagget';
    return 'Nyttig';
  }

  Widget _buildSessionCard(ChatSessionItem session, {required VoidCallback onTap}) {
    final color = _catColor(session.category);
    final label = _catLabel(session.category);
    final timeStr = _formatSessionDate(session.lastTimestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(session.iconEmoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(timeStr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
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
          'Digital veileder',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: OutlinedButton(
              onPressed: _startNewChat,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              child: const Text('Ny chat'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Chat area ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dataene analyseres av et digitalt system, og svarene er ikke alltid 100 % nøyaktige.',
                              style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Gjeldende samtale',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),

                    // Empty state — no active session
                    if (_activeSession == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                               SizedBox(
                                 width: 140,
                                 height: 140,
                                 child: Center(
                                   child: ParticleRobotModel(
                                     size: 140,
                                     enableTilt: true,
                                   ),
                                 ),
                               ),
                              const SizedBox(height: 16),
                              const Text('Start en ny samtale',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Skriv en melding nedenfor for å begynne å chatte med AI-assistenten din.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeSession!.messages.length,
                        itemBuilder: (_, i) => _buildChatBubble(_activeSession!.messages[i]),
                      ),
                      if (_isSending)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: ParticleRobotModel(
                                    size: 36,
                                    enableTilt: false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0446BC)),
                              ),
                              const SizedBox(width: 10),
                              const Text('AI tenker...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ],
                          ),
                        ),
                    ],

                    const SizedBox(height: 28),

                    // ── Tidligere samtaler ─────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tidligere samtaler',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        GestureDetector(
                          onTap: _showAllSessionsModal,
                          child: const Text(
                            'Se alle',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pastSessions.length > 3 ? 3 : _pastSessions.length,
                      itemBuilder: (_, i) => _buildSessionCard(
                        _pastSessions[i],
                        onTap: () {
                          setState(() => _activeSession = _pastSessions[i]);
                          _scrollToBottom();
                        },
                      ),
                    ),

                    if (_pastSessions.length > 3)
                      GestureDetector(
                        onTap: _showAllSessionsModal,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Center(
                            child: Text(
                              '+ ${_pastSessions.length - 3} til',
                              style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Bottom input bar ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0446BC), size: 26),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bildevedlegg støttes av Food AI & Gemini Vision!')),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Skriv en melding...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(color: Color(0xFF0446BC), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat bubble builder ─────────────────────────────────────────────────

  Widget _buildChatBubble(ChatMessageItem msg) {
    if (msg.isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14, left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0446BC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // User avatar — right side, aligned to bubble bottom
            ClipOval(
              child: SizedBox(
                width: 34, height: 34,
                child: UniversalAvatarWidget(
                  avatarPath: _userAvatarPath,
                  size: 34,
                  level: _firebaseService.currentUser?.levelXp ?? 50,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 14, right: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 3D Particle Robot avatar for AI response
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              child: Center(
                child: ParticleRobotModel(
                  size: 36,
                  enableTilt: false,
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'I dag, ${DateFormat('HH:mm').format(date)}';
    if (diff == 1) return 'I går, ${DateFormat('HH:mm').format(date)}';
    return DateFormat('d. MMM, HH:mm', 'nb_NO').format(date);
  }
}

