import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/state_widgets.dart';

class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.courses),
      body: data.courses.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.menu_book_rounded,
              title: 'Курстар жоқ',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: data.courses.length,
              itemBuilder: (context, index) {
                final course = data.courses[index];
                return GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.darkBlue, AppColors.accentBlue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.pureWhite, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              course.teacherName,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
              },
            ),
    );
  }
}
