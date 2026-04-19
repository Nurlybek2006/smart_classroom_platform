import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<DataProvider>().loadStudentData(auth.user!.uid, []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сәлем, ${auth.user?.fullName.split(' ').first ?? ''} 👋',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.studentDashboard,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _IconBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => context.push('/chat'),
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.person_outline_rounded,
                          onTap: () => context.push('/profile'),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // GPA Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  color: AppColors.darkBlue.withValues(alpha: 0.95),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 44,
                        lineWidth: 8,
                        percent: (data.gpa / 4.0).clamp(0.0, 1.0),
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.gpa.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            Text(
                              'GPA',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.pureWhite.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        progressColor: AppColors.accentBlue,
                        backgroundColor: AppColors.pureWhite.withValues(alpha: 0.15),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.gpaScore,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.pureWhite.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _MiniStat(
                              label: AppStrings.averageScore,
                              value: '${data.averageGrade.toStringAsFixed(1)}%',
                            ),
                            const SizedBox(height: 4),
                            _MiniStat(
                              label: AppStrings.attendance,
                              value: '${data.attendanceRate.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Stats Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: AppStrings.courses,
                        value: '${data.courses.length}',
                        icon: Icons.menu_book_rounded,
                        iconColor: AppColors.accentBlue,
                        iconBgColor: AppColors.infoLight,
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StatCard(
                        title: AppStrings.missedAssignments,
                        value: '${data.missedAssignmentCount}',
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.error,
                        iconBgColor: AppColors.errorLight,
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                    ),
                  ],
                ),
              ),
            ),

            // Upcoming Assignments
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 20, color: AppColors.accentBlue),
                    const SizedBox(width: 8),
                    const Text(
                      AppStrings.upcomingAssignments,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (data.upcomingAssignments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassCard(
                        child: Center(
                          child: Text(
                            AppStrings.noData,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    );
                  }
                  final assignment = data.upcomingAssignments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassCard(
                      onTap: () => context.push('/student/assignments/${assignment.id}'),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: AppColors.accentBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  assignment.courseName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (400 + index * 80).ms).fadeIn().slideX(begin: 0.1);
                },
                childCount: data.upcomingAssignments.isEmpty
                    ? 1
                    : data.upcomingAssignments.take(5).length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
          ],
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.pureWhite.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.pureWhite,
          ),
        ),
      ],
    );
  }
}
