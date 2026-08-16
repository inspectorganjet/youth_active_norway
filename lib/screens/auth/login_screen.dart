import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../auth/onboarding_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;

  void _handleAuthSubmit() async {
    setState(() => _isLoading = true);

    await _firebaseService.initializeMockDemoUser();

    if (mounted) {
      setState(() => _isLoading = false);

      if (_isSignUp) {
        // Navigate to Onboarding screen for unique nickname creation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        // Navigate directly to Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Title "Velkommen" (Matching Screenshot)
              const Text(
                'Velkommen',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle "Logg inn eller opprett en konto..."
              Text(
                _isSignUp
                    ? 'Opprett en konto for å starte treningen'
                    : 'Logg inn eller opprett en konto for å starte treningen',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Field 1: E-post
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'E-post',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'navn@eksempel.no',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF0F172A)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Field 2: Passord
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passord',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF0F172A)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Primary Deep Blue Button: Logg inn / Registrer (Matching Screenshot)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuthSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0446BC), // Primary Deep Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isSignUp ? 'Opprett konto' : 'Logg Inn'),
                ),
              ),
              const SizedBox(height: 24),

              // Divider line with "eller" (Matching Screenshot)
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'eller',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // Social Login Button 1: Logg inn med Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _handleAuthSubmit,
                  icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFF0F172A), size: 28),
                  label: const Text(
                    'Logg inn med Google',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Social Login Button 2: Logg inn med Apple
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _handleAuthSubmit,
                  icon: const Icon(Icons.apple, color: Color(0xFF0F172A), size: 24),
                  label: const Text(
                    'Logg inn med Apple',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Bottom Toggle Link: Har du ikke konto? Registrer deg (Matching Screenshot)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Har du allerede konto?' : 'Har du ikke konto?',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Logg inn' : 'Registrer deg',
                      style: const TextStyle(
                        color: Color(0xFF0446BC),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
