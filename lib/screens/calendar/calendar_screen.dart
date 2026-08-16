import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/task_model.dart';
import '../nutrition/food_ai_screen.dart';
import '../workout/pose_workout_screen.dart';
import '../../services/pose_detector_service.dart';
import '../reading/reading_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  late DateTime _focusedWeekStart;
  DateTime _selectedDate = DateTime.now();

  List<TaskModel> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _focusedWeekStart = _getMonday(DateTime.now());
    _selectedDate = DateTime.now();
    _loadTasks();
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
      _filterTasksByDate();
    });
  }

  Future<void> _selectDateFromPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('nb', 'NO'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0446BC),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && !_isSameDay(picked, _selectedDate)) {
      setState(() {
        _selectedDate = picked;
        _focusedWeekStart = _getMonday(picked);
        _filterTasksByDate();
      });
    }
  }

  void _loadTasks() {
    setState(() {
      _filterTasksByDate();
    });
  }

  void _filterTasksByDate() {
    // Strict date filtering — no fallback, empty days show empty state message
    _filteredTasks = _firebaseService.getTasksForDate(_selectedDate);
  }

  void _openTaskExecution(TaskModel task) {
    if (task.completed) return;

    if (task.taskType == 'food') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FoodAIScreen(isMandatoryCalendarTask: true),
        ),
      ).then((_) {
        _firebaseService.markTaskComplete(task.id, '🥗', 'Fullførte obligatorisk måltid via Food AI');
        _loadTasks();
      });
    } else if (task.taskType == 'pushups') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PoseWorkoutScreen(workoutType: WorkoutType.pushups),
        ),
      ).then((_) {
        _firebaseService.markTaskComplete(task.id, '💪', 'Fullførte obligatorisk treningsøkt');
        _loadTasks();
      });
    } else if (task.taskType == 'reading') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ReadingScreen(),
        ),
      ).then((_) {
        _firebaseService.markTaskComplete(task.id, '📖', 'Fullførte obligatorisk lesing');
        _loadTasks();
      });
    } else {
      _showCompleteDialog(task);
    }
  }

  void _showCompleteDialog(TaskModel task) {
    String selectedEmoji = '😊';
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Fullfør: ${task.title} 🎉'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Hvordan føltes arrangementet/oppgaven?'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['🔥', '💪', '😊', '🥳', '😴'].map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = emoji),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Skriv en kort kommentar...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
                ElevatedButton(
                  onPressed: () {
                    _firebaseService.markTaskComplete(
                      task.id,
                      selectedEmoji,
                      commentController.text.trim(),
                    );
                    _loadTasks();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0446BC)),
                  child: const Text('Lagre & Fullfør (+200 Mynter)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasActiveTasksForDate(DateTime date) {
    return _firebaseService.getTasksForDate(date).any((task) => !task.completed);
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
          'Arrangementer & Kalender',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 19),
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
                          _filterTasksByDate();
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
                                    ? const Color(0xFF10B981) // Green
                                    : (isSelected ? Colors.white70 : const Color(0xFF94A3B8)), // Gray
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

            // 2. Date Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatNorwegianDateHeader(_selectedDate),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    onPressed: _selectDateFromPicker,
                    tooltip: 'Velg dato',
                    icon: const Icon(Icons.event_note_rounded, color: Color(0xFF0446BC), size: 24),
                  ),
                ],
              ),
            ),

            // 3. Tasks List / Empty State for Selected Day
            Expanded(
              child: _filteredTasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_busy_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ingen oppgaver funnet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Det er ingen oppgaver eller arrangementer registrert for denne dagen.',
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
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];

                        return GestureDetector(
                          onTap: () => _showTaskDetailsModal(task),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: task.completed ? const Color(0xFFF8FAFC) : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: task.completed ? const Color(0xFFCBD5E1) : const Color(0xFF10B981),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: task.completed ? const Color(0xFFE2E8F0) : Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        task.completed ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                                        color: task.completed ? const Color(0xFF64748B) : const Color(0xFF10B981),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: task.completed ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tildelt av: ${_getRoleLabel(task.createdByRole)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: task.completed ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!task.completed)
                                      ElevatedButton(
                                        onPressed: () => _openTaskExecution(task),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0446BC),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Start'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  task.description,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.goldReward > 0 ? '+${task.goldReward} Gull' : 'Ingen gull',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: const [
                                        Text(
                                          'Se detaljer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0446BC),
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0446BC)),
                                      ],
                                    ),
                                  ],
                                ),
                                // Show completion note if completed
                                if (task.completed && task.completionComment != null && task.completionComment!.isNotEmpty) ...
                                  [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          task.completionMoodEmoji ?? '✅',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            task.completionComment!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF10B981),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'parent':
      case 'forelder':
        return 'Forelder 👨‍👩‍👧';
      case 'nav':
        return 'NAV 🏛️';
      case 'coach':
      case 'trener':
        return 'Trener 🏋️';
      case 'admin':
      case 'support':
        return 'Administrator ⚙️';
      default:
        return role;
    }
  }

  bool _isWorkoutTask(TaskModel task) {
    const workoutTypes = ['pushups', 'squats', 'situps', 'cardio_running', 'meditation', 'workout'];
    return workoutTypes.contains(task.taskType.toLowerCase()) || task.workoutMode != null;
  }

  void _showTaskDetailsModal(TaskModel task) {
    final isWorkout = _isWorkoutTask(task);
    final scheduledTimeStr = DateFormat('HH:mm').format(task.scheduledTime);
    final scheduledDateStr = DateFormat('dd.MM.yyyy').format(task.scheduledTime);
    final createdTimeStr = task.createdAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(task.createdAt!)
        : 'Tidligere i dag';
    final roleLabel = _getRoleLabel(task.createdByRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Type badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isWorkout
                                ? const Color(0xFF0446BC).withValues(alpha: 0.1)
                                : const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isWorkout ? '🏋️ Treningsøkt' : '📋 Aktivitet / Oppgave',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isWorkout ? const Color(0xFF0446BC) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              if (isWorkout) ...[
                // --- WORKOUT DETAILED SPECIFICATION ---
                // 1. Time to complete
                _buildModalDetailRow(
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFF0446BC),
                  title: 'Tidspunkt',
                  value: '$scheduledDateStr kl. $scheduledTimeStr',
                ),
                const SizedBox(height: 14),

                // 2. Mode and Count
                _buildModalDetailRow(
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Modus og repetisjoner',
                  value: '${task.workoutMode ?? "Automatisk sporing"} — ${task.targetGoal > 0 ? "${task.targetGoal} repetisjoner / min" : "Målnivå"}',
                ),
                const SizedBox(height: 14),

                // 3. Extra Info
                _buildModalDetailRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Tilleggsinformasjon',
                  value: task.description.isNotEmpty ? task.description : 'Ingen instruksjoner',
                ),
                const SizedBox(height: 14),

                // 4. Time added & Author
                _buildModalDetailRow(
                  icon: Icons.person_pin_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Opprettet av og tidspunkt',
                  value: '$createdTimeStr ($roleLabel)',
                ),
                const SizedBox(height: 14),

                // 5. Gold reward status
                _buildModalGoldRow(task.goldReward),
              ] else ...[
                // --- REGULAR EVENT / TASK SPECIFICATION ---
                // 1. Scheduled Time & Title
                _buildModalDetailRow(
                  icon: Icons.access_time_filled_rounded,
                  iconColor: const Color(0xFF0446BC),
                  title: 'Tidspunkt for gjennomføring',
                  value: '$scheduledDateStr kl. $scheduledTimeStr',
                ),
                const SizedBox(height: 14),

                _buildModalDetailRow(
                  icon: Icons.label_important_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Hva som skal gjøres',
                  value: task.title,
                ),
                const SizedBox(height: 14),

                // 2. Extra info
                _buildModalDetailRow(
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Tilleggsinformasjon',
                  value: task.description.isNotEmpty ? task.description : 'Ingen tilleggsinformasjon oppgitt',
                ),
                const SizedBox(height: 14),

                // 3. Time added & Creator (Parent, NAV, Coach)
                _buildModalDetailRow(
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Opprettelsestid og forfatter',
                  value: '$createdTimeStr ($roleLabel)',
                ),
                const SizedBox(height: 14),

                // 4. Gold reward status
                _buildModalGoldRow(task.goldReward),
              ],

              // Completion comment note if completed
              if (task.completed && task.completionComment != null && task.completionComment!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Text(task.completionMoodEmoji ?? '✅', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status: Fullført!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              task.completionComment!,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!task.completed) {
                      _openTaskExecution(task);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.completed ? const Color(0xFF64748B) : const Color(0xFF0446BC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    task.completed ? 'Lukk (Oppgaven er fullført)' : 'Start oppgaven (+${task.goldReward} Gull)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModalGoldRow(int goldReward) {
    final willEarn = goldReward > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: willEarn ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: willEarn ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: willEarn ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: willEarn ? const Color(0xFFD97706) : Colors.grey.shade600,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gullbelønning',
                  style: TextStyle(
                    fontSize: 12,
                    color: willEarn ? const Color(0xFF92400E) : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  willEarn
                      ? 'Ja! Fullført oppgave gir +$goldReward Gull 💰'
                      : 'Nei, ingen gullbelønning for denne oppgaven',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: willEarn ? const Color(0xFFB45309) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
