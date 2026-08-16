import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';
import '../../models/user_model.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({Key? key}) : super(key: key);

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _adminCommentController = TextEditingController();

  late DateTime _focusedWeekStart;
  DateTime _selectedDate = DateTime.now();

  List<ActivityModel> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _focusedWeekStart = _getMonday(DateTime.now());
    _selectedDate = DateTime.now();
    _loadActivities();
  }

  DateTime _getMonday(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeWeek(int weekDelta) {
    setState(() {
      _focusedWeekStart = _focusedWeekStart.add(Duration(days: weekDelta * 7));
      _selectedDate = _focusedWeekStart;
      _filterActivitiesByDate();
    });
  }

  void _loadActivities() {
    setState(() {
      _filterActivitiesByDate();
    });
  }

  void _filterActivitiesByDate() {
    // Strict date filtering — uses service method for consistency
    _filteredActivities = _firebaseService.getActivitiesForDate(_selectedDate);
  }

  bool _hasActiveTasksForDate(DateTime date) {
    return _firebaseService.getTasksForDate(date).any((task) => !task.completed);
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    final isAdminOrCoach = user != null &&
        (user.role == UserRole.admin || user.role == UserRole.coach);

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
          'Aktivitetsdagbok',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Week Header Bar with Navigation Arrows (Venstre / Høyre)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 30, color: Color(0xFF0F172A)),
                    onPressed: () => _changeWeek(-1),
                    tooltip: 'Forrige uke',
                  ),
                  Text(
                    _formatWeekHeader(_focusedWeekStart),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 30, color: Color(0xFF0F172A)),
                    onPressed: () => _changeWeek(1),
                    tooltip: 'Neste uke',
                  ),
                ],
              ),
            ),

            // 2. 7 Days of Week Across Full Screen Width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: List.generate(7, (index) {
                  final date = _focusedWeekStart.add(Duration(days: index));
                  final isSelected = _isSameDay(_selectedDate, date);
                  final dayName = _getShortDayName(date.weekday);
                  final hasActive = _hasActiveTasksForDate(date);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                          _filterActivitiesByDate();
                        });
                      },
                      child: Container(
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0446BC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0446BC) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF0446BC).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasActive
                                    ? const Color(0xFF10B981)
                                    : (isSelected ? Colors.white70 : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Selected Date Header & Filter Button (Matching screenshot)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatNorwegianDateHeader(_selectedDate),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 22),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Activity Feed List — Empty state with proper Norwegian message
            Expanded(
              child: _filteredActivities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ingen aktiviteter funnet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ingen treningsøkter eller trenerrapporter er registrert for denne dagen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        final act = _filteredActivities[index];
                        final IconData typeIcon = _getTypeIcon(act.type);
                        final String categoryName = act.NorwegianTypeTitle;
                        final String timeStr = DateFormat('HH:mm').format(act.timestamp);
                        final String title = act.userComment.isNotEmpty ? act.userComment : categoryName;

                        return GestureDetector(
                          onTap: () => _showDetailedActivitySheet(act, isAdminOrCoach),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Soft Blue Icon Box
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(typeIcon, color: const Color(0xFF0446BC), size: 24),
                                ),
                                const SizedBox(width: 14),

                                // Title & Subtitle Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        categoryName,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Time & Gold Badge + Chevron Arrow
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '+${act.coinsEarned} Mynter',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 4. Bottom Deep Blue Action Button: Nytt aktivitetsnotat
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _showAddCustomActivityDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0446BC), // Deep Primary Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: const Text('Nytt aktivitetsnotat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detailed Modal BottomSheet automatically pulling full mode data from databases!
  void _showDetailedActivitySheet(ActivityModel act, bool isAdminOrCoach) {
    final user = _firebaseService.currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Type Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getTypeIcon(act.type), color: const Color(0xFF0446BC), size: 26),
                          const SizedBox(width: 10),
                          Text(
                            act.NorwegianTypeTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Detail Box 1: Time, Duration & Gold/XP Earned
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Tidspunkt', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(DateFormat('HH:mm').format(act.timestamp),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Varighet', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${(act.durationSeconds / 60).toStringAsFixed(0)} min',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Belønning', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('💰 +${act.coinsEarned}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mode-Specific Deep Data Output
                  const Text('Detaljert rapport', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (act.type == 'pushups' || act.type == 'squats' || act.type == 'situps') ...[
                          Text('💪 Repetisjoner: ${act.reps} stk', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('🤖 Gemini AI Analyse:\n${act.aiReport}'),
                        ] else if (act.type == 'reading') ...[
                          const Text('📖 Lesemodus Rapport', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('🤖 Gemini AI Analyse:\n${act.aiReport}'),
                        ] else if (act.type.startsWith('cardio')) ...[
                          Text('🏃 Distanse: ${act.distanceKm} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('🤖 Strava / GPS Rapport:\n${act.aiReport}'),
                        ] else if (act.type == 'food') ...[
                          const Text('🥗 Ernæringsanalyse', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('🤖 Food AI Vurdering:\n${act.aiReport}'),
                        ] else ...[
                          Text(act.aiReport.isNotEmpty ? act.aiReport : 'Aktivitet registrert.'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Coach / Admin Comments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Trener- og adminkommentarer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0446BC), size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (act.coachComments.isEmpty)
                    const Text('Ingen kommentarer ennå.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                  else
                    Column(
                      children: act.coachComments.map((c) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.coachName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0446BC))),
                              const SizedBox(height: 4),
                              Text(c.commentText),
                              if (c.userReactionEmoji != null) ...[
                                const SizedBox(height: 4),
                                Text('Reaksjon: ${c.userReactionEmoji}'),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  // Admin / Coach Comment Input Box
                  if (isAdminOrCoach) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _adminCommentController,
                      decoration: InputDecoration(
                        hintText: 'Skriv kommentar som trener/admin...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF0446BC)),
                          onPressed: () {
                            if (_adminCommentController.text.trim().isNotEmpty) {
                              _firebaseService.addCoachCommentToActivity(
                                act.id,
                                _adminCommentController.text.trim(),
                                user?.nickname ?? 'Trener',
                              );
                              _adminCommentController.clear();
                              _loadActivities();
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomActivityDialog() {
    final titleController = TextEditingController();
    final infoController = TextEditingController();
    final coinsController = TextEditingController(text: '100');
    String? uploadedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Nytt aktivitetsnotat', style: TextStyle(fontWeight: FontWeight.w500)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tema for notat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'F.eks: Tur i parken, Styrkeøkt...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Detaljert informasjon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: infoController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Beskriv aktiviteten din i detalj...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kedlegg (PDF / Bilde)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            uploadedFileName = 'dokument_${DateTime.now().millisecondsSinceEpoch ~/ 100000}.pdf';
                          });
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Last opp fil', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          uploadedFileName ?? 'Ingen fil valgt',
                          style: TextStyle(
                            fontSize: 12,
                            color: uploadedFileName != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            fontWeight: uploadedFileName != null ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Mynter (+ for å gi, - for å trekke)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: coinsController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: InputDecoration(
                      hintText: 'F.eks: 100 eller -50',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Avbryt', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isNotEmpty) {
                    final int coinAmount = int.tryParse(coinsController.text.trim()) ?? 100;
                    final now = DateTime.now();
                    final timestamp = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      now.hour,
                      now.minute,
                      now.second,
                    );

                    final act = ActivityModel(
                      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
                      timestamp: timestamp,
                      type: 'custom',
                      durationSeconds: 900,
                      coinsEarned: coinAmount,
                      moodEmoji: '📝',
                      userComment: titleController.text.trim(),
                      aiReport: infoController.text.trim().isNotEmpty
                          ? infoController.text.trim()
                          : 'Manuelt aktivitetsnotat registrert.',
                      coachComments: [],
                      detailedInfo: uploadedFileName != null ? {'fileName': uploadedFileName} : null,
                    );

                    await _firebaseService.addActivity(act);
                    _loadActivities();
                    if (context.mounted) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0446BC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lagre', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'pushups':
      case 'squats':
      case 'situps':
        return Icons.fitness_center_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'cardio_running':
      case 'cardio_cycling':
      case 'cardio':
        return Icons.directions_run_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'meditation':
      case 'wim_hof_breathing':
        return Icons.self_improvement_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Man';
      case 2:
        return 'Tir';
      case 3:
        return 'Ons';
      case 4:
        return 'Tor';
      case 5:
        return 'Fre';
      case 6:
        return 'Lør';
      case 7:
        return 'Søn';
      default:
        return 'Dag';
    }
  }

  String _formatWeekHeader(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final monthNameMon = DateFormat('MMMM', 'nb_NO').format(monday);
    final monthNameSun = DateFormat('MMMM', 'nb_NO').format(sunday);

    final capMon = monthNameMon[0].toUpperCase() + monthNameMon.substring(1);
    final capSun = monthNameSun[0].toUpperCase() + monthNameSun.substring(1);

    if (monday.month == sunday.month) {
      return '$capMon ${monday.year}';
    } else {
      return '$capMon / $capSun ${monday.year}';
    }
  }

  String _formatNorwegianDateHeader(DateTime date) {
    final dayName = DateFormat('EEEE', 'nb_NO').format(date);
    final monthName = DateFormat('MMMM', 'nb_NO').format(date);
    final capitalizedDay = dayName[0].toUpperCase() + dayName.substring(1);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);
    return '$capitalizedDay, ${date.day}. $capitalizedMonth';
  }
}
