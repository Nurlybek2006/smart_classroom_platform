import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<DataProvider>().loadTeacherData(auth.user!.uid);
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
        child: RefreshIndicator(
          onRefresh: () async {
            if (auth.user != null) {
              data.loadTeacherData(auth.user!.uid);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.teacherDashboard,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            onTap: () => context.push('/chat'),
                            badge: data.unreadNotifications,
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
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

              // Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.2,
                    children: [
                      StatCard(
                        title: AppStrings.totalStudents,
                        value: '${data.students.length}',
                        icon: Icons.people_rounded,
                        iconColor: AppColors.accentBlue,
                        iconBgColor: AppColors.infoLight,
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                      StatCard(
                        title: AppStrings.totalCourses,
                        value: '${data.courses.length}',
                        icon: Icons.menu_book_rounded,
                        iconColor: AppColors.success,
                        iconBgColor: AppColors.successLight,
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                      StatCard(
                        title: AppStrings.activeAssignments,
                        value: '${data.assignments.where((a) => !a.isOverdue).length}',
                        icon: Icons.assignment_rounded,
                        iconColor: AppColors.warning,
                        iconBgColor: AppColors.warningLight,
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                      StatCard(
                        title: AppStrings.recentSubmissions,
                        value: '${data.submissions.length}',
                        icon: Icons.upload_file_rounded,
                        iconColor: AppColors.error,
                        iconBgColor: AppColors.errorLight,
                      ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),
                    ],
                  ),
                ),
              ),

              // Risk Students Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _SectionHeader(
                    title: AppStrings.riskStudents,
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.warning,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: data.students.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.noData,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: data.students.take(5).length,
                          itemBuilder: (context, index) {
                            final student = data.students[index];
                            return _RiskStudentCard(
                              name: student.fullName,
                              group: student.group,
                              risk: index % 3 == 0
                                  ? AppStrings.highRisk
                                  : index % 3 == 1
                                      ? AppStrings.mediumRisk
                                      : AppStrings.lowRisk,
                              riskColor: index % 3 == 0
                                  ? AppColors.riskHigh
                                  : index % 3 == 1
                                      ? AppColors.riskMedium
                                      : AppColors.riskLow,
                            );
                          },
                        ),
                ).animate(delay: 500.ms).fadeIn(),
              ),

              // Upcoming Deadlines
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _SectionHeader(
                    title: AppStrings.upcomingDeadlines,
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.accentBlue,
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
                      child: _AssignmentDeadlineCard(
                        title: assignment.title,
                        courseName: assignment.courseName,
                        deadline: assignment.deadline,
                        type: assignment.type,
                      ),
                    ).animate(delay: (600 + index * 100).ms).fadeIn().slideX(begin: 0.1);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teacher/assignments/create'),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  const _HeaderIconButton({required this.icon, required this.onTap, this.badge});

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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            if (badge != null && badge! > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskStudentCard extends StatelessWidget {
  final String name;
  final String group;
  final String risk;
  final Color riskColor;

  const _RiskStudentCard({
    required this.name,
    required this.group,
    required this.risk,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              risk,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: riskColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            group,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentDeadlineCard extends StatelessWidget {
  final String title;
  final String courseName;
  final DateTime deadline;
  final String type;

  const _AssignmentDeadlineCard({
    required this.title,
    required this.courseName,
    required this.deadline,
    required this.type,
  });

  String _formatDeadline() {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.inDays == 0) return 'Бүгін';
    if (diff.inDays == 1) return 'Ертең';
    return '${diff.inDays} күн қалды';
  }

  Color _typeColor() {
    switch (type) {
      case 'quiz':
        return AppColors.accentBlue;
      case 'test':
        return AppColors.error;
      case 'project':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _typeColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatDeadline(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
