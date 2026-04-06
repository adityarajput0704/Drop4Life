import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
// import 'config/app_config.dart';
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
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
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
    final GoRouter router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isFirebaseAuthed = authProvider.isAuthenticated;
        final loc = state.matchedLocation;

        final publicRoutes = {'/login', '/register', '/onboarding', '/'};
        final isPublic = publicRoutes.contains(loc);

        // Not logged in → force to onboarding
        if (!isFirebaseAuthed && !isPublic) {
          return '/onboarding';
        }

        // Logged in but trying to access donor routes without donor role
        if (isFirebaseAuthed && authProvider.currentUser != null) {
          final role = authProvider.currentUser!.role;
          // Admin trying to access donor-only screens
          if (role == 'admin' && loc == '/home') {
            return null; // allow for now — admin panel in Phase 8
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
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
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
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