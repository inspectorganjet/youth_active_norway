import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';

class FoodLogItem {
  final String id;
  final DateTime timestamp;
  String dishName;
  int calories;
  int protein;
  int fat;
  int carbs;
  String advice;
  String healthTag;
  bool isMismatch;
  final bool isMandatoryTask;

  FoodLogItem({
    required this.id,
    required this.timestamp,
    required this.dishName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.advice,
    this.healthTag = 'SUNN OG NÆRINGSRIK 🍏',
    this.isMismatch = false,
    this.isMandatoryTask = false,
  });
}

class FoodAIScreen extends StatefulWidget {
  final bool isMandatoryCalendarTask;

  const FoodAIScreen({
    Key? key,
    this.isMandatoryCalendarTask = false,
  }) : super(key: key);

  @override
  State<FoodAIScreen> createState() => _FoodAIScreenState();
}

class _FoodAIScreenState extends State<FoodAIScreen> {
  final GeminiAIService _geminiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isAnalyzing = false;
  bool _hasPhotoSelected = false;

  final List<FoodLogItem> _localFoodHistory = [
    FoodLogItem(
      id: 'f_1',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      dishName: 'Grillet laksesalat med avokado',
      calories: 450,
      protein: 32,
      fat: 28,
      carbs: 12,
      advice: 'Utmerket kilde til sunne fettsyrer (Omega-3) og proteiner! Bidrar til god restitusjon.',
      healthTag: 'SUNN OG NÆRINGSRIK 🍏',
      isMandatoryTask: true,
    ),
    FoodLogItem(
      id: 'f_2',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      dishName: 'Havregrynsgrøt med banan og nøtter',
      calories: 380,
      protein: 14,
      fat: 10,
      carbs: 58,
      advice: 'Gode trege karbohydrater som gir langvarig energi til dagens treningsøkt.',
      healthTag: 'PERFEKT TRENINGSMAT ⚡',
      isMandatoryTask: false,
    ),
  ];

  void _selectPhotoFromCameraOrGallery(bool fromCamera) {
    setState(() {
      _hasPhotoSelected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fromCamera ? 'Bilde tatt med kamera 📷' : 'Bilde valgt fra galleri 🖼️'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _analyzeMealPhoto() async {
    setState(() {
      _isAnalyzing = true;
    });

    final result = await _geminiService.analyzeFoodPhoto(userTextDescription: 'Bilde av måltid');

    final newItem = FoodLogItem(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      dishName: result['dishName'] as String? ?? 'Kyllingbryst med avokadosalat og quinoa 🥗',
      calories: result['calories'] as int? ?? 480,
      protein: result['proteinGrams'] as int? ?? 36,
      fat: result['fatGrams'] as int? ?? 16,
      carbs: result['carbsGrams'] as int? ?? 44,
      advice: result['advice'] as String? ?? 'Meget balansert måltid! Høyt proteininnhold for muskelvekst og sunne fettsyrer.',
      healthTag: result['healthTag'] as String? ?? 'SUNN OG NÆRINGSRIK 🍏',
      isMismatch: result['isMismatch'] as bool? ?? false,
      isMandatoryTask: widget.isMandatoryCalendarTask,
    );

    _localFoodHistory.insert(0, newItem);

    final activity = ActivityModel(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: 'food',
      reps: 0,
      durationSeconds: 0,
      coinsEarned: 150,
      moodEmoji: '🥗',
      userComment: 'Bildeanalyse: ${newItem.dishName}',
      aiReport: newItem.advice,
      coachComments: [],
      detailedInfo: {
        'calories': newItem.calories,
        'protein': newItem.protein,
        'fat': newItem.fat,
        'carbs': newItem.carbs,
        'dishName': newItem.dishName,
        'healthTag': newItem.healthTag,
      },
    );
    await _firebaseService.addActivity(activity);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _hasPhotoSelected = false;
      });
      _showAnalysisResultModal(newItem);
    }
  }

  // Popup Modal showing detected Dish, Nutrients, Healthiness, Re-analysis Text Field & Anti-Cheat
  void _showAnalysisResultModal(FoodLogItem item) {
    final TextEditingController clarificationController = TextEditingController();

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
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
            ),
            child: SingleChildScrollView(
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

                  // Header: Dish Name & Healthiness Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item.isMismatch ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(item.isMismatch ? '⚠️' : '🥗', style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.dishName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isMismatch ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: item.isMismatch ? Colors.red : Colors.green),
                              ),
                              child: Text(
                                item.healthTag,
                                style: TextStyle(
                                  color: item.isMismatch ? Colors.red.shade800 : Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4 Macro Cards
                  Row(
                    children: [
                      Expanded(child: _buildMacroCard('Kalorier', '${item.calories} kcal', Colors.orange.shade50, Colors.orange.shade800)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMacroCard('Proteiner', '${item.protein}g', Colors.blue.shade50, Colors.blue.shade800)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMacroCard('Fett', '${item.fat}g', Colors.red.shade50, Colors.red.shade800)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMacroCard('Karbs', '${item.carbs}g', Colors.green.shade50, Colors.green.shade800)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Micronutrients & Health Assessment Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.isMismatch ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: item.isMismatch ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.isMismatch ? Icons.warning_amber_rounded : Icons.health_and_safety_rounded,
                              color: item.isMismatch ? Colors.red : const Color(0xFF0446BC),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.isMismatch ? 'Gemini AI Anti-Fusk Advarsel' : 'Næringsinnhold & Vurdering',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: item.isMismatch ? Colors.red.shade900 : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.advice, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // RE-ANALYSIS SECTION (User clarification text input)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kjente AI igjen feil mat? 📝',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Skriv din egen forklaring av retten. AI vil re-analysere basert på BÅDE bildet og teksten din (samt sjekke for fusk):',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: clarificationController,
                          decoration: InputDecoration(
                            hintText: 'f.eks. Biffsalat med fetaost og oliven',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final userText = clarificationController.text.trim();
                              if (userText.isEmpty) return;

                              final result = await _geminiService.analyzeFoodPhoto(
                                userTextDescription: 'Bilde av måltid',
                                userClarificationText: userText,
                              );

                              setModalState(() {
                                item.dishName = result['dishName'] as String? ?? userText;
                                item.calories = result['calories'] as int? ?? 460;
                                item.protein = result['proteinGrams'] as int? ?? 38;
                                item.fat = result['fatGrams'] as int? ?? 14;
                                item.carbs = result['carbsGrams'] as int? ?? 42;
                                item.advice = result['advice'] as String? ?? 'Re-analysert måltid!';
                                item.healthTag = result['healthTag'] as String? ?? 'RE-ANALYSERT 🍏';
                                item.isMismatch = result['isMismatch'] as bool? ?? false;
                              });

                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Re-analyser med tekst 🔄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0446BC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
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
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('Lukk & Lagre i historikk'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroCard(String title, String value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol)),
        ],
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
        title: const Text('Digital ernæringsanalyse', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Camera & Photo Upload Container (occupies ~60-70% of screen height)
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.63,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF0446BC), width: 2.0),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0446BC).withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
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
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0446BC), size: 46),
                        ),
                        const SizedBox(height: 14),
                        const Text('Last opp eller ta bilde av måltidet 📸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        const Text('Ta et bilde med kameraet eller velg fra galleriet for automatisk AI-analyse.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        const SizedBox(height: 20),

                        // Camera & Gallery Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectPhotoFromCameraOrGallery(true),
                                  icon: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0446BC)),
                                  label: const Text('Kamera 📷', style: TextStyle(color: Color(0xFF0446BC), fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0446BC)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectPhotoFromCameraOrGallery(false),
                                  icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF0446BC)),
                                  label: const Text('Galleri 🖼️', style: TextStyle(color: Color(0xFF0446BC), fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0446BC)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_hasPhotoSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                SizedBox(width: 6),
                                Text('Bilde klart til analyse! 🍏', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isAnalyzing ? null : _analyzeMealPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0446BC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isAnalyzing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Analyser Måltid 🥗', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Search History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Historikk (Mat-AI)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Trykk for detaljer', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localFoodHistory.length,
                itemBuilder: (context, index) {
                  final item = _localFoodHistory[index];
                  return GestureDetector(
                    onTap: () => _showAnalysisResultModal(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: item.isMismatch ? Colors.red.shade200 : const Color(0xFFE2E8F0), width: 1.0),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.isMismatch ? Colors.red.shade50 : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(item.isMismatch ? '⚠️' : '🥗', style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.dishName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('HH:mm').format(item.timestamp)} · ${item.calories} kcal (${item.protein}g P / ${item.fat}g F / ${item.carbs}g K)',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
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
}
