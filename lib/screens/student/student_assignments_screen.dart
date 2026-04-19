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

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.assignments),
      body: data.assignments.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.assignment_rounded,
              title: 'Тапсырмалар жоқ',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: data.assignments.length,
              itemBuilder: (context, index) {
                final a = data.assignments[index];
                final hasSubmitted = data.submissions.any((s) => s.assignmentId == a.id);
                return GlassCard(
                  onTap: () => context.push('/student/assignments/${a.id}'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (a.isOverdue ? AppColors.error : AppColors.accentBlue)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          a.isQuiz ? Icons.quiz_rounded : Icons.assignment_rounded,
                          color: a.isOverdue ? AppColors.error : AppColors.accentBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.courseName} • ${DateFormat('dd.MM').format(a.deadline)}',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasSubmitted
                              ? AppColors.successLight
                              : a.isOverdue
                                  ? AppColors.errorLight
                                  : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasSubmitted
                              ? AppStrings.submitted
                              : a.isOverdue
                                  ? AppStrings.overdue
                                  : AppStrings.pending,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasSubmitted
                                ? AppColors.success
                                : a.isOverdue
                                    ? AppColors.error
                                    : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.05);
              },
            ),
    );
  }
}
