import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../providers/api_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../widgets/design/pixel_pet.dart';
import '../models/user_status.dart';
import '../theme/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final api = ref.read(apiServiceProvider);
    final token = await api.getToken();
    final userId = await api.getUserId();

    if (!mounted) return;

    if (token != null && userId != null) {
      // Validate token with a real API call to ensure session is active
      final result = await api.getPartnerStatus();

      if (!mounted) return;

      if (result is Success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Token is invalid, expired, or server error -> Force re-login
        await api.logout();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDay, // Use theme background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Logo / Character
             const PixelPet(status: UserStatus.ONLINE, size: 120),
             const SizedBox(height: 24),
             Text(
               "ZZZ",
               style: Theme.of(context).textTheme.displayLarge?.copyWith(
                 fontSize: 48,
                 letterSpacing: 4,
               ),
             ),
             const SizedBox(height: 16),
             Text(
               "연락이 끊겨도 마음은 연결되게",
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                 color: AppColors.textSecondaryDay,
               ),
             ),
          ],
        ),
      ),
    );
  }
}
