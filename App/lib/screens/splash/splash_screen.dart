import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
// import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      context.go('/onboarding');
      return;
    }

  // Firebase session exists — restore role from backend
    final role = await authProvider.restoreSession();
    if (!mounted) return;

    if (role == 'donor') {
      context.go('/home');
    } else {
      // Not a donor (admin/hospital) or not registered yet
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.water_drop,
              color: AppTheme.primaryRed,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Drop4life',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Every Drop Counts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
