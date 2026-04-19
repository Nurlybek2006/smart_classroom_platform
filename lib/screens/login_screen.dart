import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.isTeacher) {
        context.go('/teacher');
      } else {
        context.go('/student');
      }
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBlue,
              AppColors.deepNavy,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.pureWhite.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 44,
                    color: AppColors.pureWhite,
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 24),

                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                    letterSpacing: 1,
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  AppStrings.loginSubtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.pureWhite.withValues(alpha: 0.6),
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 48),

                // Login Form Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.login,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        PremiumTextField(
                          controller: _emailController,
                          labelText: AppStrings.email,
                          hintText: 'example@edu.kz',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.emailRequired;
                            }
                            if (!value.contains('@')) {
                              return AppStrings.invalidEmail;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        PremiumTextField(
                          controller: _passwordController,
                          labelText: AppStrings.password,
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.passwordRequired;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Error message
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.error != null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          auth.error!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 8),

                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return PremiumButton(
                              text: AppStrings.loginButton,
                              isLoading: auth.isLoading,
                              onPressed: _handleLogin,
                              icon: Icons.login_rounded,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 40),

                // Footer
                Text(
                  '© 2026 Smart Classroom Platform',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.pureWhite.withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
