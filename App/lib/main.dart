import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/donor_provider.dart';
import 'providers/request_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/requests/requests_screen.dart';
import 'screens/requests/request_detail_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'models/blood_request.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!AppConfig.useMockData) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DonorProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
      ],
      child: const Drop4LifeApp(),
    ),
  );
}

class Drop4LifeApp extends StatelessWidget {
  const Drop4LifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    final GoRouter router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (AppConfig.useMockData) return null;

        final isAuthParam = state.matchedLocation == '/login' ||
                            state.matchedLocation == '/register' ||
                            state.matchedLocation == '/onboarding' ||
                            state.matchedLocation == '/';
        final isAuth = authProvider.isAuthenticated;

        if (!isAuth && !isAuthParam) {
          return '/onboarding';
        }
        
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/requests', builder: (context, state) => const RequestsScreen()),
        GoRoute(
          path: '/request/:id',
          builder: (context, state) {
            final request = state.extra as BloodRequest?;
            if (request == null) {
              return const Scaffold(body: Center(child: Text('Request not found')));
            }
            return RequestDetailScreen(request: request);
          },
        ),
        GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'Drop4life',
      theme: AppTheme.themeData,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
