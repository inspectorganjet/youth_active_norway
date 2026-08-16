import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../widgets/xp_coins_bar.dart';
import '../../widgets/universal_avatar_widget.dart';
import '../shop/shop_screen.dart';
import '../shop/inventory_screen.dart';
import '../workout/pose_workout_screen.dart';
import '../reading/reading_screen.dart';
import '../nutrition/food_ai_screen.dart';
import '../calendar/calendar_screen.dart';
import '../logbook/logbook_screen.dart';
import '../ai_chat/mentor_chat_screen.dart';
import '../reports/pdf_export_screen.dart';
import '../mood/mood_popup_dialog.dart';
import '../../services/pose_detector_service.dart';
import '../cardio/cardio_screen.dart';
import '../meditation/wim_hof_meditation_screen.dart';
import '../shadow_boxing/shadow_boxing_screen.dart';
import '../../widgets/shield_core_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;
  Timer? _moodPopupTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkRandomMoodPopup();
  }

  void _loadUser() async {
    await _firebaseService.initializeMockDemoUser();
    setState(() {
      _user = _firebaseService.currentUser;
    });
  }

  void _checkRandomMoodPopup() {
    _moodPopupTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => MoodPopupDialog(
            timeOfDay: 'Ettermiddag',
            onSaved: () {
              setState(() {
                _user = _firebaseService.currentUser;
              });
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _moodPopupTimer?.cancel();
    super.dispose();
  }

  void _openWorkout(WorkoutType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PoseWorkoutScreen(workoutType: type),
      ),
    ).then((_) => setState(() => _user = _firebaseService.currentUser));
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3B82F6)),
            tooltip: 'NAV PDF Rapport',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PdfExportScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DEDICATED AVATAR WINDOW
              Container(
                width: double.infinity,
                height: (MediaQuery.of(context).size.height * 0.35).clamp(180.0, 280.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF3E8FF), Color(0xFFEEF2FF)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: (MediaQuery.of(context).size.height * 0.30).clamp(160.0, 240.0),
                    height: (MediaQuery.of(context).size.height * 0.30).clamp(160.0, 240.0),
                    child: UniversalAvatarWidget(
                      avatarPath: _user!.activeAvatarLottie,
                      size: (MediaQuery.of(context).size.height * 0.30).clamp(160.0, 240.0),
                      level: 50,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. XP & COINS PROGRESS BAR
              XpCoinsBar(user: _user!),

              const SizedBox(height: 24),

              // SHOP & INVENTORY BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ShopScreen()),
                        ).then((_) => setState(() {
                          _user = _firebaseService.currentUser;
                        }));
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                      label: const Text('Butikk', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0446BC),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const InventoryScreen()),
                        ).then((_) => setState(() {
                          _user = _firebaseService.currentUser;
                        }));
                      },
                      icon: const Icon(Icons.checkroom_outlined, color: Color(0xFF0F172A)),
                      label: const Text('Inventar', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF0F172A))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 3. MAIN DASHBOARD GRID
              const Text(
                'Aktiviteter',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width < 360 ? 0.95 : 1.15,
                children: [
                  _buildDashboardCard(
                    title: 'Armhevinger',
                    subtitle: 'AI Kameratelling',
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _openWorkout(WorkoutType.pushups),
                  ),
                  _buildDashboardCard(
                    title: 'Knebøy',
                    subtitle: 'AI Kameratelling',
                    icon: Icons.accessibility_new_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => _openWorkout(WorkoutType.squats),
                  ),
                  _buildDashboardCard(
                    title: 'Situps',
                    subtitle: 'AI Kameratelling',
                    icon: Icons.sports_gymnastics_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _openWorkout(WorkoutType.situps),
                  ),
                  _buildDashboardCard(
                    title: 'Skyggekamp 🥊',
                    subtitle: 'Bokse-AI Analyse',
                    icon: Icons.sports_mma_rounded,
                    color: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShadowBoxingScreen()),
                      ).then((_) => setState(() => _user = _firebaseService.currentUser));
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Kardio Økt',
                    subtitle: 'GPS Løp & Sykkel',
                    icon: Icons.directions_run_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CardioScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Pusteøvelser',
                    subtitle: 'Wim Hof Meditasjon',
                    icon: Icons.air_rounded,
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WimHofMeditationScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Digital Lesing',
                    subtitle: 'Les & Gjenfortell',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReadingScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Ernæring AI',
                    subtitle: 'Skann Matrett',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FoodAIScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Kalender & Mål',
                    subtitle: 'Ukeplan & Krav',
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CalendarScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Treningsdagbok',
                    subtitle: 'AI & Trenersvar',
                    icon: Icons.history_edu_rounded,
                    color: const Color(0xFF14B8A6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LogbookScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'AI Mentor Chat',
                    subtitle: 'Råd & Motivasjon',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFFF97316),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MentorChatScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
