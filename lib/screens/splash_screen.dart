import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkOnboardingAndAuth();
  }

  Future<void> _checkOnboardingAndAuth() async {
    // Wait for splash screen animation (3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if onboarding was completed
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Check if user is logged in
      final isLoggedIn = _authService.currentUser != null;

      // Navigate based on state
      if (!onboardingCompleted) {
        // First time - show onboarding
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else if (isLoggedIn) {
        // User is logged in - go to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Onboarding completed but not logged in - show login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // On error, default to onboarding
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';
        
        return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a3e), // Dark blue-purple
              const Color(0xFF2d1b4e), // Darker purple
              const Color(0xFF1a1a3e), // Dark blue-purple
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location Pin Icon with circular background
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // SmartTour Text
              const Text(
                'SmartTour',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Slogan
              Text(
                loc?.translate('app_tagline') ?? 'دليلك السياحي الذكي',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
              const SizedBox(height: 48),
              
              // Loading Spinner
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}

