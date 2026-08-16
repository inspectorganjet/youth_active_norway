import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await firebase_core.Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initializeApp error: $e');
  }

  try {
    await initializeDateFormatting('nb_NO', null);
  } catch (e) {
    debugPrint('DateFormatting error: $e');
  }

  try {
    FirebaseService().configureFirestoreOfflinePersistence();
    await FirebaseService().initializeMockDemoUser();
  } catch (e) {
    debugPrint('FirebaseService init error: $e');
  }

  runApp(const UngdomsAktivitetApp());
}

class UngdomsAktivitetApp extends StatelessWidget {
  const UngdomsAktivitetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UngdomsAktivitet 🇳🇴',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
