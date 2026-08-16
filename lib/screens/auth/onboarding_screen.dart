import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nickController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isChecking = false;
  bool? _isAvailable;
  UserRole _selectedRole = UserRole.user;

  void _checkNickname(String value) async {
    if (value.trim().length < 3) {
      setState(() {
        _isAvailable = null;
        _isChecking = false;
      });
      return;
    }

    setState(() => _isChecking = true);
    final available = await _firebaseService.isNicknameAvailable(value.trim());
    setState(() {
      _isAvailable = available;
      _isChecking = false;
    });
  }

  void _completeOnboarding() async {
    final nick = _nickController.text.trim();
    if (nick.isEmpty || _isAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vennligst velg et gyldig og unikt kallenavn!')),
      );
      return;
    }

    final newUser = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      nickname: nick,
      role: _selectedRole,
      clubId: 'oslo_ungdomsklubb',
      levelXp: 120,
      coins: 100,
      activeAvatarLottie: 'custom_avatar_digital_boxer',
      createdAt: DateTime.now(),
    );

    await _firebaseService.saveUserProfile(newUser);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velg ditt Kallenavn'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Opprett din profil ✨',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kallenavnet ditt må være unikt i appen og brukes på tavler og i dagboken.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              // Nickname Field
              TextField(
                controller: _nickController,
                onChanged: _checkNickname,
                decoration: InputDecoration(
                  labelText: 'Unikt Kallenavn',
                  hintText: 'F.eks. SuperAktiv2026',
                  prefixIcon: const Icon(Icons.person_rounded),
                  suffixIcon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isAvailable == true
                          ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                          : _isAvailable == false
                              ? const Icon(Icons.cancel_rounded, color: Colors.red)
                              : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 8),

              if (_isAvailable == true)
                const Text('🎉 Kallenavnet er ledig!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
              else if (_isAvailable == false)
                const Text('❌ Kallenavnet er opptatt, prøv et annet.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

              const SizedBox(height: 24),

              // Role Selector for Demo
              const Text(
                'Velg din Rolle (for demo):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: UserRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role.toNorwegianName()),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedRole = role);
                    },
                  );
                }).toList(),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Start Eventyret!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
