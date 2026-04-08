import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _routeByRole(String? role, String? error) {
    switch (role) {
     case 'donor':
       context.go('/home');
       break;
     case 'admin':
       // Admin dashboard — placeholder until Phase 8
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Login from Web portal for admin access.')),
       );
       break;
     case 'hospital':
       // Hospital dashboard — placeholder
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Login from Web portal for hospital access.')),
       );
       break;
     case null:
       // null = /users/me returned 404 — new user, not registered in DB yet
       // OR login itself failed
       final error = context.read<AuthProvider>().error;
       if (error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error)),
         );
       } else {
         // Firebase auth succeeded but no DB record
         context.go('/register');
       }
       break;
   }
  }


  void _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final role = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
      _routeByRole(role, authProvider.error);
    }

  void _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final role = await authProvider.loginWithGoogle();
    if (!mounted) return;
    _routeByRole(role, authProvider.error);
  }


  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.water_drop, color: AppTheme.primaryRed, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Drop4life',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'LIFE SAVING NETWORK ACCESS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.primaryRed, width: 2)),
                      ),
                      child: const Text(
                        'Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.border, width: 2)),
                        ),
                        child: const Text(
                          'Register',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(hintText: 'name@drop4life.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PASSWORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryRed, fontSize: 12)),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In →'),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: AppTheme.border)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 32, color: AppTheme.textPrimary),
                  label: const Text('Continue with Google', style: TextStyle(color: AppTheme.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account yet? ", style: TextStyle(color: AppTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('Create your donor profile', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
