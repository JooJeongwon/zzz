import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'providers/api_provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() {
    runApp(const ProviderScope(child: AppStarter()));
  }, (error, stack) {
    debugPrint("ZZZ: Uncaught error in main zone: $error\n$stack");
  });
}

class AppStarter extends ConsumerStatefulWidget {
  const AppStarter({super.key});

  @override
  ConsumerState<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends ConsumerState<AppStarter> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint("ZZZ: InitializeApp started");
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting();
      
      try {
        await dotenv.load(fileName: ".env");
        debugPrint("ZZZ: Dotenv loaded");
      } catch (e) {
        debugPrint("ZZZ: Dotenv load failed: $e");
      }

      try {
        // Only try to init Firebase if options are valid (hacky check for placeholder)
        if (DefaultFirebaseOptions.currentPlatform.appId != 'your-app-id') {
           await Firebase.initializeApp(
             options: DefaultFirebaseOptions.currentPlatform,
           );
           final apiService = ref.read(apiServiceProvider);
           await FcmService.initialize(navigatorKey, apiService);
           debugPrint("ZZZ: Firebase initialized");
        } else {
           debugPrint("ZZZ: Skipping Firebase init (placeholders detected)");
        }
      } catch (e) {
        debugPrint("ZZZ: Firebase init failed: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      debugPrint("ZZZ: Token retrieved: $token");

      if (mounted) {
        setState(() {
          _isLoggedIn = token != null;
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint("ZZZ: Critical init error: $e\n$stack");
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Initialization Error:\n$_error", style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("ZZZ Starting..."),
              ],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ZZZ',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}