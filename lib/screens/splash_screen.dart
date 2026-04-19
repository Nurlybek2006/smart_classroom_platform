import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      if (authProvider.isTeacher) {
        context.go('/teacher');
      } else {
        context.go('/student');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBlue,
              AppColors.deepNavy,
              AppColors.midnightBlue,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.pureWhite.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 60,
                color: AppColors.pureWhite,
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

            const SizedBox(height: 32),

            // App Name
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 10),

            // Tagline
            Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.pureWhite.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 60),

            // Loading Indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.pureWhite.withValues(alpha: 0.7),
              ),
            )
                .animate(delay: 1000.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
