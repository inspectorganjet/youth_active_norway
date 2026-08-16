import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/task_model.dart';
import '../models/avatar_item.dart';
import '../models/mood_log.dart';

class ChatMessageItem {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String lottiePath;
  final String category;

  ChatMessageItem({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.lottiePath = 'assets/lottie/avatar_runner.json',
    this.category = 'useful',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': Timestamp.fromDate(timestamp),
        'lottiePath': lottiePath,
        'category': category,
      };

  factory ChatMessageItem.fromMap(Map<String, dynamic> map) => ChatMessageItem(
        id: map['id'] ?? '',
        text: map['text'] ?? '',
        isUser: map['isUser'] ?? false,
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lottiePath: map['lottiePath'] ?? 'assets/lottie/avatar_runner.json',
        category: map['category'] ?? 'useful',
      );
}

class ChatSessionItem {
  final String id;
  final String title;       // AI-generated short title
  final DateTime lastTimestamp;
  final String iconEmoji;
  final List<ChatMessageItem> messages;
  /// 'useful' = green, 'fun' = yellow, 'dangerous' = red
  final String category;

  ChatSessionItem({
    required this.id,
    required this.title,
    required this.lastTimestamp,
    required this.iconEmoji,
    required this.messages,
    this.category = 'useful',
  });
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  final List<AvatarItem> _shopAvatars = [
    AvatarItem(
      id: 'neon_human_3d',
      name: 'Neon Atlet 🧬',
      lottiePath: 'custom_avatar_neon_human_3d',
      rarity: 'legendarisk',
      priceCoins: 0,
      isOwned: true,
    ),
    AvatarItem(
      id: 'boxing_2',
      name: 'Cyber Boxer 🥊',
      lottiePath: 'assets/lottie/boxing_2.json',
      rarity: 'legendarisk',
      priceCoins: 0,
      isOwned: true,
    ),
    AvatarItem(
      id: 'holographic_card',
      name: 'Holo Card 🎴',
      lottiePath: 'custom_avatar_holographic_card',
      rarity: 'legendarisk',
      priceCoins: 0,
      isOwned: true,
    ),
    AvatarItem(
      id: 'avatar_runner',
      name: 'Løper 🏃',
      lottiePath: 'assets/lottie/avatar_runner.json',
      rarity: 'alminnelig',
      priceCoins: 0,
      isOwned: true,
    ),
    AvatarItem(
      id: 'avatar_hero',
      name: 'Superhelt ⚡',
      lottiePath: 'assets/lottie/avatar_hero.json',
      rarity: 'sjelden',
      priceCoins: 500,
      isOwned: false,
    ),
  ];

  final List<ActivityModel> _activities = [
    ActivityModel(
      id: 'act_today_1',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: 'pushups',
      reps: 30,
      durationSeconds: 180,
      coinsEarned: 300,
      moodEmoji: '💪',
      userComment: 'Morgenøkt: Armhevinger',
      aiReport: 'AI-analyse: Godkjent fullt bevegelsesutslag! 30 reps.',
      coachComments: [
        CoachComment(
          coachUid: 'coach_1',
          coachName: 'Trener Anders',
          commentText: 'Super teknikk på morgenøkten! Stå på!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          userReactionEmoji: '🔥',
        ),
      ],
    ),
    ActivityModel(
      id: 'act_today_2',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: 'reading',
      durationSeconds: 900,
      coinsEarned: 150,
      moodEmoji: '📖',
      userComment: 'Leste ferdig kapittel 4 i boken',
      aiReport: 'Tekstforståelse: 92% match. 15 minutter dyp lesing registrert.',
      coachComments: [],
    ),
    ActivityModel(
      id: 'act_yesterday_1',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: 'cardio',
      distanceKm: 5.4,
      durationSeconds: 1720,
      coinsEarned: 270,
      moodEmoji: '🏃',
      userComment: 'Kveldsløp i skogen',
      aiReport: '5.4 km fullført med snitt-tempo 5:18 min/km. Utmerket utholdenhet!',
      coachComments: [
        CoachComment(
          coachUid: 'coach_1',
          coachName: 'Trener Anders',
          commentText: 'Bra tempo på femkilometeren i går!',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          userReactionEmoji: '👏',
        ),
      ],
    ),
    ActivityModel(
      id: 'act_yesterday_2',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      type: 'food',
      durationSeconds: 60,
      coinsEarned: 150,
      moodEmoji: '🥗',
      userComment: 'Middag: Proteinrik laks & grønnsaker',
      aiReport: '520 kcal · 42g P · 18g F · 38g K. Næringsrikt måltid.',
      coachComments: [],
    ),
    ActivityModel(
      id: 'act_2days_1',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      type: 'squats',
      reps: 50,
      durationSeconds: 300,
      coinsEarned: 350,
      moodEmoji: '🦵',
      userComment: 'Knebøy økt',
      aiReport: '50 knebøy verifisert med digital analyse. Dype knebøy!',
      coachComments: [],
    ),
    ActivityModel(
      id: 'act_5days_1',
      timestamp: DateTime.now().subtract(const Duration(days: 5, hours: 6)),
      type: 'wim_hof_breathing',
      durationSeconds: 600,
      coinsEarned: 200,
      moodEmoji: '🧘',
      userComment: 'Pusteøvelse & restitusjon',
      aiReport: '3 runder Wim Hof pusteøvelser fullført. Puls senket fra 78 til 58 BPM.',
      coachComments: [],
    ),
  ];

  final List<TaskModel> _tasks = [
    // === I DAG ===
    TaskModel(
      id: 'task_today_1',
      title: 'Armhevinger (Obligatorisk)',
      description: 'Gjør 30 armhevinger foran kameraet. Systemet teller og verifiserer bevegelsene.',
      scheduledTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        9,
        0,
      ),
      taskType: 'pushups',
      targetGoal: 30,
      completed: false,
      createdByRole: 'coach',
      goldReward: 250,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      workoutMode: 'Pose AI (Kamera)',
    ),
    TaskModel(
      id: 'task_today_2',
      title: 'Digital lesing (Obligatorisk)',
      description: 'Les i 15 minutter og gjenfortell hva du leste med egne ord.',
      scheduledTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        14,
        0,
      ),
      taskType: 'reading',
      targetGoal: 15,
      completed: true,
      createdByRole: 'parent',
      goldReward: 150,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      completionMoodEmoji: '📚',
      completionComment: 'Leste om teknologi og fremtiden.',
    ),
    TaskModel(
      id: 'task_today_3',
      title: 'Ernæringskontroll (Obligatorisk)',
      description: 'Skann og logg hvert måltid i dag med Food AI.',
      scheduledTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        12,
        0,
      ),
      taskType: 'food',
      targetGoal: 3,
      completed: false,
      createdByRole: 'nav',
      goldReward: 200,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    // === I GÅR ===
    TaskModel(
      id: 'task_yesterday_1',
      title: 'Knebøy (Obligatorisk ukesmål)',
      description: 'Gjør 20 knebøy med korrekt form – digital analyse verifiserer.',
      scheduledTime: DateTime(
        DateTime.now().subtract(const Duration(days: 1)).year,
        DateTime.now().subtract(const Duration(days: 1)).month,
        DateTime.now().subtract(const Duration(days: 1)).day,
        10,
        0,
      ),
      taskType: 'squats',
      targetGoal: 20,
      completed: true,
      createdByRole: 'coach',
      goldReward: 300,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      workoutMode: 'Pose AI (Kamera)',
      completionMoodEmoji: '🦵',
      completionComment: 'Klarte alle 20 knebøy!',
    ),
    TaskModel(
      id: 'task_yesterday_2',
      title: 'Wim Hof Pusteøvelse',
      description: '3 runder med Wim Hof-pusting. Fokus på ro og restitusjon.',
      scheduledTime: DateTime(
        DateTime.now().subtract(const Duration(days: 1)).year,
        DateTime.now().subtract(const Duration(days: 1)).month,
        DateTime.now().subtract(const Duration(days: 1)).day,
        20,
        0,
      ),
      taskType: 'meditation',
      targetGoal: 3,
      completed: true,
      createdByRole: 'coach',
      goldReward: 180,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      workoutMode: 'Timer & Guidet Pusting',
      completionMoodEmoji: '🧘',
      completionComment: 'Veldig avslappende.',
    ),
    // === FOR 2 DAGER SIDEN ===
    TaskModel(
      id: 'task_2days_1',
      title: 'Kardioøkt: 5 km løp',
      description: 'Løp 5 km med GPS-sporing. Mål: under 30 minutter.',
      scheduledTime: DateTime(
        DateTime.now().subtract(const Duration(days: 2)).year,
        DateTime.now().subtract(const Duration(days: 2)).month,
        DateTime.now().subtract(const Duration(days: 2)).day,
        17,
        0,
      ),
      taskType: 'cardio_running',
      targetGoal: 5,
      completed: true,
      createdByRole: 'coach',
      goldReward: 350,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      workoutMode: 'GPS Sporing (Løp)',
      completionMoodEmoji: '🏃',
      completionComment: 'Løp 5.4 km på 27 min. Ny personlig rekord!',
    ),
    // === I MORGEN ===
    TaskModel(
      id: 'task_tomorrow_1',
      title: 'Situps (Obligatorisk)',
      description: 'Gjør 25 situps foran kameraet for AI-verifisering.',
      scheduledTime: DateTime(
        DateTime.now().add(const Duration(days: 1)).year,
        DateTime.now().add(const Duration(days: 1)).month,
        DateTime.now().add(const Duration(days: 1)).day,
        8,
        0,
      ),
      taskType: 'situps',
      targetGoal: 25,
      completed: false,
      createdByRole: 'coach',
      goldReward: 200,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      workoutMode: 'Pose AI (Kamera)',
    ),
    TaskModel(
      id: 'task_tomorrow_2',
      title: 'AI Mentor møte',
      description: 'Sjekk inn med AI Mentor – sett ukemål og diskuter fremgang.',
      scheduledTime: DateTime(
        DateTime.now().add(const Duration(days: 1)).year,
        DateTime.now().add(const Duration(days: 1)).month,
        DateTime.now().add(const Duration(days: 1)).day,
        15,
        0,
      ),
      taskType: 'ai_chat',
      targetGoal: 1,
      completed: false,
      createdByRole: 'parent',
      goldReward: 100,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    // === FOR 5 DAGER SIDEN ===
    TaskModel(
      id: 'task_5days_1',
      title: 'Styrkeøkt: Armhevinger + Knebøy',
      description: 'Kombinert styrkeøkt: 20 armhevinger + 30 knebøy med AI-teller.',
      scheduledTime: DateTime(
        DateTime.now().subtract(const Duration(days: 5)).year,
        DateTime.now().subtract(const Duration(days: 5)).month,
        DateTime.now().subtract(const Duration(days: 5)).day,
        11,
        0,
      ),
      taskType: 'pushups',
      targetGoal: 20,
      completed: true,
      createdByRole: 'coach',
      goldReward: 400,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      workoutMode: 'Pose AI (Kamera)',
      completionMoodEmoji: '💪',
      completionComment: 'Super styrkeøkt! Følte meg sterk.',
    ),
  ];
  final List<MoodLog> _moodLogs = [];

  final List<ChatSessionItem> _chatSessions = [
    ChatSessionItem(
      id: 'cs_demo_1',
      title: 'Hvordan forbedre armhevingsteknikk?',
      lastTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      iconEmoji: '💪',
      category: 'useful',
      messages: [
        ChatMessageItem(
          id: 'u1', text: 'Hvordan kan jeg forbedre teknikken min på armhevinger?',
          isUser: true, timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          category: 'useful',
        ),
        ChatMessageItem(
          id: 'ai1',
          text: 'Flott spørsmål! For bedre armhevingsteknikk: hold kroppen i rett linje, gå ned til 90° albuevinkel og pust ut når du presser opp. Trèn 3 sett med 10-15 reps daglig.',
          isUser: false, timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: -1)),
          lottiePath: 'assets/lottie/avatar_hero.json',
          category: 'useful',
        ),
      ],
    ),
    ChatSessionItem(
      id: 'cs_demo_2',
      title: 'Beste matvalg før kveldsøkt?',
      lastTimestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      iconEmoji: '🥗',
      category: 'useful',
      messages: [
        ChatMessageItem(
          id: 'u2', text: 'Hva bør jeg spise før en kveldsøkt?',
          isUser: true, timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          category: 'useful',
        ),
        ChatMessageItem(
          id: 'ai2',
          text: 'Før en kveldsøkt anbefales et lett måltid 1-2 timer før: banan med nøttesmør, havregrøt med bær, eller kylling med ris. Unngå tungt fettrikt mat som tar lang tid å fordøye.',
          isUser: false, timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3, minutes: -1)),
          lottiePath: 'assets/lottie/avatar_runner.json',
          category: 'useful',
        ),
      ],
    ),
    ChatSessionItem(
      id: 'cs_demo_3',
      title: 'Hvem er den sterkeste Minecraft-bossen?',
      lastTimestamp: DateTime.now().subtract(const Duration(days: 2)),
      iconEmoji: '🎮',
      category: 'fun',
      messages: [
        ChatMessageItem(
          id: 'u3', text: 'Hvem er den sterkeste bossen i Minecraft?',
          isUser: true, timestamp: DateTime.now().subtract(const Duration(days: 2)),
          category: 'fun',
        ),
        ChatMessageItem(
          id: 'ai3',
          text: 'Den sterkeste bossen er Wither! Den har 300 helsepoeng i Java Edition og spårer eksplosjoner og skyt piler som gir Wither-effekt. Ender Dragon er også utfordrende, men Wither er vanskeligere å drepe.',
          isUser: false, timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: -1)),
          lottiePath: 'assets/lottie/avatar_dragon.json',
          category: 'fun',
        ),
      ],
    ),
    ChatSessionItem(
      id: 'cs_demo_4',
      title: 'Lesestrategi for bedre forståelse',
      lastTimestamp: DateTime.now().subtract(const Duration(days: 3)),
      iconEmoji: '📚',
      category: 'useful',
      messages: [
        ChatMessageItem(
          id: 'u4', text: 'Hvordan kan jeg lese raskere og huske mer?',
          isUser: true, timestamp: DateTime.now().subtract(const Duration(days: 3)),
          category: 'useful',
        ),
        ChatMessageItem(
          id: 'ai4',
          text: 'Tips for bedre lesing: 1) Les aktivt – still deg spørsmål underveis. 2) Ta pauser hvert 25. minutt (Pomodoro). 3) Skriv ett-setnings oppsummeringer etter hvert avsnitt. 4) Gjenfortell det du leste med egne ord etterpå.',
          isUser: false, timestamp: DateTime.now().subtract(const Duration(days: 3, minutes: -1)),
          lottiePath: 'assets/lottie/avatar_runner.json',
          category: 'useful',
        ),
      ],
    ),
    ChatSessionItem(
      id: 'cs_demo_5',
      title: 'Spørring om farlig innhold (flagget)',
      lastTimestamp: DateTime.now().subtract(const Duration(days: 5)),
      iconEmoji: '⚠️',
      category: 'dangerous',
      messages: [
        ChatMessageItem(
          id: 'u5', text: 'Hvordan kan jeg skade meg for å slippe trening?',
          isUser: true, timestamp: DateTime.now().subtract(const Duration(days: 5)),
          category: 'dangerous',
        ),
        ChatMessageItem(
          id: 'ai5',
          text: '⚠️ Jeg kan ikke hjelpe med det. Dersom du føler deg presset eller sliten, snakk med en voksen du stoler på. Din helse og trivsel er viktigst! Vi finner alltid en løsning sammen 💙',
          isUser: false, timestamp: DateTime.now().subtract(const Duration(days: 5, minutes: -1)),
          lottiePath: 'assets/lottie/avatar_runner.json',
          category: 'dangerous',
        ),
      ],
    ),
  ];

  Future<bool> isNicknameAvailable(String nickname) async => true;

  Future<void> saveUserProfile(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', user.nickname);
  }

  Future<bool> purchaseAvatar(AvatarItem avatar) async {
    await buyAvatar(avatar);
    return true;
  }

  Map<String, dynamic> getReadingStats() => {
        'totalMinutes': 45,
        'booksCompleted': 3,
        'streakDays': 5,
      };

  Map<String, dynamic> getMeditationStats() => {
        'totalMinutes': 30,
        'sessionsCompleted': 4,
      };

  Map<String, int> getChatSafetyStatistics() => {
        'totalMessages': 15,
        'flaggedMessages': 0,
        'safetyScore': 100,
      };

  void markTaskComplete(String taskId, String emoji, String comment) {
    completeCalendarTask(taskId, emoji, comment);
  }

  void addChatSession(ChatSessionItem session) {
    _chatSessions.insert(0, session);
  }

  void addMessageToActiveSession(String sessionId, ChatMessageItem userMsg, ChatMessageItem aiMsg) {
    addChatMessage(sessionId, userMsg);
    addChatMessage(sessionId, aiMsg);
  }

  Future<void> initializeMockDemoUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNick = prefs.getString('user_nickname') ?? 'KariNordmann';
    final savedRoleStr = prefs.getString('user_role') ?? 'user';
    final savedAvatar = prefs.getString('user_avatar') ?? 'custom_avatar_neon_human_3d';

    _currentUser = UserModel(
      uid: 'demo_user_123',
      nickname: savedNick,
      role: UserRoleExtension.fromString(savedRoleStr),
      clubId: 'Oslo Aktiv Ungdom',
      coins: 1420,
      levelXp: 850,
      activeAvatarLottie: savedAvatar,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  List<AvatarItem> getShopAvatars() => List.unmodifiable(_shopAvatars);

  List<ActivityModel> getActivities() => List.unmodifiable(_activities);

  List<ActivityModel> getActivitiesForType(String type) {
    return _activities.where((a) => a.type == type).toList();
  }

  List<ActivityModel> getCardioActivities() {
    return _activities
        .where((a) => a.type == 'cardio_running' || a.type == 'cardio_cycling' || a.type == 'cardio')
        .toList();
  }

  List<TaskModel> getTasks() => List.unmodifiable(_tasks);

  /// Returns tasks scheduled exactly on [date] (by year/month/day)
  List<TaskModel> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      return task.scheduledTime.year == date.year &&
          task.scheduledTime.month == date.month &&
          task.scheduledTime.day == date.day;
    }).toList();
  }

  /// Returns activities logged exactly on [date] (by year/month/day)
  List<ActivityModel> getActivitiesForDate(DateTime date) {
    return _activities.where((act) {
      return act.timestamp.year == date.year &&
          act.timestamp.month == date.month &&
          act.timestamp.day == date.day;
    }).toList();
  }

  List<MoodLog> getMoodLogs() => List.unmodifiable(_moodLogs);

  Map<String, int> getModeStats(String typeKey) {
    final now = DateTime.now();
    final modeActivities = _activities.where((a) => a.type == typeKey).toList();

    int today = 0;
    int week = 0;
    int month = 0;
    int year = 0;

    for (var act in modeActivities) {
      final diff = now.difference(act.timestamp);
      final repsCount = act.reps > 0 ? act.reps : 25;

      if (diff.inDays == 0 && act.timestamp.day == now.day) {
        today += repsCount;
      }
      if (diff.inDays <= 7) {
        week += repsCount;
      }
      if (diff.inDays <= 30) {
        month += repsCount;
      }
      if (diff.inDays <= 365) {
        year += repsCount;
      }
    }

    return {
      'today': today,
      'week': week,
      'month': month,
      'year': year,
    };
  }

  Future<void> addActivity(ActivityModel activity) async {
    _activities.insert(0, activity);
    if (_currentUser != null) {
      final newCoins = _currentUser!.coins + activity.coinsEarned;
      final newXp = _currentUser!.levelXp + (activity.coinsEarned ~/ 2);
      _currentUser = _currentUser!.copyWith(
        coins: newCoins,
        levelXp: newXp,
      );
    }
  }

  Future<void> addMoodLog(MoodLog moodLog) async {
    _moodLogs.insert(0, moodLog);
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        coins: _currentUser!.coins + 50,
      );
    }
  }

  Future<void> updateActiveAvatar(String lottiePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar', lottiePath);

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(activeAvatarLottie: lottiePath);
    }
  }

  Future<void> updateAvatarRotation(double rotationY) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarRotationY: rotationY);
    }
  }

  Future<void> buyAvatar(AvatarItem avatar) async {
    if (_currentUser == null) return;
    if (_currentUser!.coins < avatar.priceCoins) return;

    final newCoins = _currentUser!.coins - avatar.priceCoins;
    _currentUser = _currentUser!.copyWith(
      coins: newCoins,
      activeAvatarLottie: avatar.lottiePath,
    );

    final idx = _shopAvatars.indexWhere((a) => a.id == avatar.id);
    if (idx != -1) {
      _shopAvatars[idx] = AvatarItem(
        id: avatar.id,
        name: avatar.name,
        lottiePath: avatar.lottiePath,
        rarity: avatar.rarity,
        priceCoins: avatar.priceCoins,
        isOwned: true,
      );
    }
    await updateActiveAvatar(avatar.lottiePath);
  }

  List<ChatSessionItem> getChatSessions() => List.unmodifiable(_chatSessions);

  void addChatMessage(String sessionId, ChatMessageItem msg) {
    final idx = _chatSessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final old = _chatSessions[idx];
      final updatedMsgs = List<ChatMessageItem>.from(old.messages)..add(msg);
      _chatSessions[idx] = ChatSessionItem(
        id: old.id,
        title: old.title,
        lastTimestamp: msg.timestamp,
        iconEmoji: old.iconEmoji,
        category: old.category,
        messages: updatedMsgs,
      );
    }
  }

  /// Generates a short AI-style session title from the first user message.
  /// Also classifies category: 'useful', 'fun', or 'dangerous'.
  Map<String, String> generateSessionMeta(String firstUserMessage) {
    final lower = firstUserMessage.toLowerCase();

    // --- Category classification ---
    String category = 'useful';
    if (lower.contains('skade') || lower.contains('sloss') || lower.contains('død') ||
        lower.contains('farlig') || lower.contains('18+') || lower.contains('pornografi') ||
        lower.contains('alkohol') || lower.contains('narkotika') || lower.contains('stjele') ||
        lower.contains('slå') || lower.contains('vold') || lower.contains('rømme')) {
      category = 'dangerous';
    } else if (lower.contains('game') || lower.contains('spill') || lower.contains('minecraft') ||
        lower.contains('fortnite') || lower.contains('roblox') || lower.contains('moro') ||
        lower.contains('lol') || lower.contains('vits') || lower.contains('meme') ||
        lower.contains('serie') || lower.contains('film') || lower.contains('anime') ||
        lower.contains('hvem er') || lower.contains('hva heter') || lower.contains('karakter') ||
        lower.contains('tegnefilm') || lower.contains('youtube') || lower.contains('tiktok')) {
      category = 'fun';
    }

    // --- Short title generation (max ~40 chars) ---
    String title = firstUserMessage.trim();
    // Remove question marks and clean up
    title = title.replaceAll('?', '').replaceAll('!', '').trim();
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    // Truncate to 40 chars
    if (title.length > 40) {
      title = '${title.substring(0, 37)}...';
    }
    if (title.isEmpty) {
      title = 'Ny samtale';
    }

    // Choose icon emoji based on category and keywords
    String emoji = '💬';
    if (category == 'dangerous') {
      emoji = '⚠️';
    } else if (category == 'fun') {
      emoji = '🎮';
    } else if (lower.contains('trening') || lower.contains('armheving') || lower.contains('styrke')) {
      emoji = '💪';
    } else if (lower.contains('mat') || lower.contains('spise') || lower.contains('næring')) {
      emoji = '🥗';
    } else if (lower.contains('les') || lower.contains('skole') || lower.contains('lekse')) {
      emoji = '📚';
    } else if (lower.contains('løp') || lower.contains('kardio') || lower.contains('sykkel')) {
      emoji = '🏃';
    } else if (lower.contains('puste') || lower.contains('meditation') || lower.contains('ro')) {
      emoji = '🧘';
    }

    return {'title': title, 'category': category, 'emoji': emoji};
  }

  void createNewChatSession(String title, String iconEmoji) {
    final newId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _chatSessions.insert(
      0,
      ChatSessionItem(
        id: newId,
        title: title,
        lastTimestamp: DateTime.now(),
        iconEmoji: iconEmoji,
        messages: [
          ChatMessageItem(
            id: 'init_1',
            text: 'Hei! Hva vil du snakke om i dag ($title)?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void completeCalendarTask(String taskId, String emoji, String comment) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final old = _tasks[idx];
      _tasks[idx] = TaskModel(
        id: old.id,
        title: old.title,
        description: old.description,
        scheduledTime: old.scheduledTime,
        taskType: old.taskType,
        targetGoal: old.targetGoal,
        completed: true,
        createdByRole: old.createdByRole,
        completionMoodEmoji: emoji,
        completionComment: comment,
      );

      final activity = ActivityModel(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        type: old.taskType,
        reps: 0,
        durationSeconds: 60,
        coinsEarned: 150,
        moodEmoji: emoji,
        userComment: comment,
        aiReport: 'Obligatorisk oppgave fra kalenderen er godkjent! 🎉',
        coachComments: [],
      );

      addActivity(activity);
    }
  }

  void configureFirestoreOfflinePersistence() {
    try {
      if (_db != null) {
        _db!.settings = const Settings(persistenceEnabled: true);
      }
    } catch (_) {}
  }

  void addCoachCommentToActivity(String activityId, String commentText, String coachName) {
    final idx = _activities.indexWhere((a) => a.id == activityId);
    if (idx != -1) {
      final old = _activities[idx];
      final newComment = CoachComment(
        coachUid: 'coach_1',
        coachName: coachName,
        commentText: commentText,
        timestamp: DateTime.now(),
      );
      final updatedComments = List<CoachComment>.from(old.coachComments)..add(newComment);
      _activities[idx] = ActivityModel(
        id: old.id,
        timestamp: old.timestamp,
        type: old.type,
        reps: old.reps,
        distanceKm: old.distanceKm,
        durationSeconds: old.durationSeconds,
        coinsEarned: old.coinsEarned,
        xpEarned: old.xpEarned,
        moodEmoji: old.moodEmoji,
        userComment: old.userComment,
        aiReport: old.aiReport,
        coachComments: updatedComments,
        detailedInfo: old.detailedInfo,
      );
    }
  }
}
