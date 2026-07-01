import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/offline_mode_screen.dart';
import 'screens/live_updates_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'screens/help_screen.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Load initial locale and theme before running app
  final initialLocale = await LocaleProvider.loadInitialLocale();
  final initialDarkMode = await ThemeProvider.loadInitialTheme();
  
  runApp(SmartTourApp(
    initialLocale: initialLocale,
    initialDarkMode: initialDarkMode,
  ));
}

class SmartTourApp extends StatelessWidget {
  final Locale initialLocale;
  final bool initialDarkMode;
  
  const SmartTourApp({
    super.key,
    required this.initialLocale,
    required this.initialDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..setInitialLocale(initialLocale),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..setInitialTheme(initialDarkMode),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) {
          return MaterialApp(
            key: ValueKey('${localeProvider.locale.languageCode}_${themeProvider.isDarkMode}'), // Force rebuild on language/theme change
            title: 'SmartTour',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // Use the locale from LocaleProvider
              return localeProvider.locale;
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1a1a3e),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[50],
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1a1a3e),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[900],
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/map': (context) => const MapScreen(),
              '/trips': (context) => const TripsScreen(),
              '/recommendations': (context) {
                final categoryId = ModalRoute.of(context)?.settings.arguments as String?;
                return RecommendationsScreen(initialCategory: categoryId);
              },
              '/profile': (context) => const ProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/offline': (context) => const OfflineModeScreen(),
              '/live_updates': (context) => const LiveUpdatesScreen(),
              '/reviews': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  return ReviewsScreen(
                    placeId: args['placeId'] as String,
                    placeName: args['placeName'] as String,
                    rating: args['rating'] as double,
                    totalReviews: args['totalReviews'] as int,
                  );
                }
                return const Scaffold(
                  body: Center(child: Text('Error: Missing arguments')),
                );
              },
              '/favorites': (context) => const FavoritesScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/privacy': (context) => const PrivacySecurityScreen(),
              '/help': (context) => const HelpScreen(),
              '/admin': (context) => const AdminDashboard(),
            },
          );
        },
      ),
    );
  }
}
