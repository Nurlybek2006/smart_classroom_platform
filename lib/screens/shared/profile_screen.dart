import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.profile, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentBlue,
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            GlassCard(
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Рөл',
                    value: user?.role == 'teacher' ? AppStrings.teacher : AppStrings.student,
                  ),
                  const Divider(height: 24),
                  _ProfileItem(
                    icon: Icons.school_rounded,
                    label: 'Факультет',
                    value: user?.faculty ?? '-',
                  ),
                  const Divider(height: 24),
                  _ProfileItem(
                    icon: Icons.group_rounded,
                    label: 'Топ',
                    value: user?.group ?? '-',
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            _ActionTile(
              icon: Icons.settings_rounded,
              label: AppStrings.settings,
              onTap: () => context.push('/settings'),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 24),

            PremiumButton(
              text: 'Шығу',
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: Icons.logout_rounded,
              isOutlined: true,
            ).animate(delay: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentBlue),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
