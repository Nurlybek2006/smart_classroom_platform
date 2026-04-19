import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class TeacherShell extends StatelessWidget {
  final Widget child;

  const TeacherShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/teacher') return 0;
    if (location.startsWith('/teacher/courses')) return 1;
    if (location.startsWith('/teacher/assignments')) return 2;
    if (location.startsWith('/teacher/students')) return 3;
    if (location.startsWith('/teacher/notifications')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Басты',
                    isSelected: index == 0,
                    onTap: () => context.go('/teacher'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Курстар',
                    isSelected: index == 1,
                    onTap: () => context.go('/teacher/courses'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.assignment_rounded,
                    label: 'Тапсырма',
                    isSelected: index == 2,
                    onTap: () => context.go('/teacher/assignments'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.people_rounded,
                    label: 'Студент',
                    isSelected: index == 3,
                    onTap: () => context.go('/teacher/students'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.notifications_rounded,
                    label: 'Хабарлама',
                    isSelected: index == 4,
                    onTap: () => context.go('/teacher/notifications'),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.darkBlue : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.darkBlue : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
