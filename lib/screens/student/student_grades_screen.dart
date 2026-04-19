import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/state_widgets.dart';

class StudentGradesScreen extends StatelessWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.grades),
      body: data.grades.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.grade_rounded,
              title: 'Бағалар жоқ',
            )
          : Column(
              children: [
                // Average Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: GlassCard(
                    color: AppColors.darkBlue.withValues(alpha: 0.95),
                    margin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _GradeSummary(
                          label: AppStrings.averageScore,
                          value: '${data.averageGrade.toStringAsFixed(1)}%',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.pureWhite.withValues(alpha: 0.2),
                        ),
                        _GradeSummary(
                          label: 'GPA',
                          value: data.gpa.toStringAsFixed(2),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.pureWhite.withValues(alpha: 0.2),
                        ),
                        _GradeSummary(
                          label: AppStrings.completionRate,
                          value: '${data.grades.length}',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),

                // Grades List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: data.grades.length,
                    itemBuilder: (context, index) {
                      final grade = data.grades[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _gradeColor(grade.percentage).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  grade.letterGrade,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _gradeColor(grade.percentage),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    grade.assignmentTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    grade.courseName,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${grade.score.toInt()}/${grade.maxScore.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${grade.percentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _gradeColor(grade.percentage),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.05);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Color _gradeColor(double pct) {
    if (pct >= 80) return AppColors.success;
    if (pct >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _GradeSummary extends StatelessWidget {
  final String label;
  final String value;

  const _GradeSummary({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.pureWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.pureWhite.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
