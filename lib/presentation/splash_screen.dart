import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../data/services/auth_service.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

import 'admin/admin_main_navigation.dart';
import '../data/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final authService = AuthService();
    UserModel? currentUser;

    if (authService.currentUser != null) {
      try {
        currentUser = await authService.userStateChanges.first.timeout(const Duration(seconds: 4));
      } catch (e) {
        // Fallback locale in caso di assenza di rete o timeout
        currentUser = authService.currentUser;
      }
    }

    Widget nextScreen = const LoginScreen();
    if (currentUser != null) {
      if (currentUser.role == 'admin') {
        nextScreen = const AdminMainNavigation();
      } else {
        nextScreen = const MainNavigation();
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark,
              AppTheme.backgroundDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Wrapper
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo is missing or load fails
                      return const Icon(
                        Icons.local_bar,
                        size: 100,
                        color: AppTheme.accentGold,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'MONET BAR',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.textCream,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FIDELITY & INFO APP',
                  style: GoogleFonts.outfit(
                    color: AppTheme.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
