import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/state_widgets.dart';

class TeacherAssignmentsScreen extends StatelessWidget {
  const TeacherAssignmentsScreen({super.key});

  Color _typeColor(String type) {
    switch (type) {
      case 'quiz': return AppColors.accentBlue;
      case 'test': return AppColors.error;
      case 'project': return AppColors.success;
      default: return AppColors.warning;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'quiz': return AppStrings.quiz;
      case 'test': return AppStrings.test;
      case 'project': return AppStrings.project;
      default: return AppStrings.homework;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: PremiumAppBar(
        title: AppStrings.assignments,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => context.push('/teacher/assignments/create'),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: data.assignments.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.assignment_rounded,
              title: 'Тапсырмалар жоқ',
              subtitle: 'Жаңа тапсырма жасау үшін + басыңыз',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: data.assignments.length,
              itemBuilder: (context, index) {
                final assignment = data.assignments[index];
                final color = _typeColor(assignment.type);
                return GlassCard(
                  onTap: () => context.push('/teacher/assignments/${assignment.id}'),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _typeLabel(assignment.type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (assignment.isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppStrings.overdue,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        assignment.courseName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(assignment.deadline),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.1);
              },
            ),
    );
  }
}
