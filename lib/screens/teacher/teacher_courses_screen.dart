import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/state_widgets.dart';

class TeacherCoursesScreen extends StatelessWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: PremiumAppBar(
        title: AppStrings.courses,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showCreateCourseSheet(context),
              child: Container(
                padding: const EdgeInsets.all(9),
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
      body: data.courses.isEmpty
          ? EmptyStateWidget(
              icon: Icons.menu_book_rounded,
              title: AppStrings.noCourses,
              subtitle: 'Курс жасау үшін + басыңыз',
              buttonText: AppStrings.createCourse,
              onButtonPressed: () => _showCreateCourseSheet(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: data.courses.length,
              itemBuilder: (context, index) {
                final course = data.courses[index];
                return _CourseCard(course: course, index: index)
                    .animate(delay: (index * 80).ms)
                    .fadeIn()
                    .slideX(begin: 0.1);
              },
            ),
      floatingActionButton: data.courses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateCourseSheet(context),
              backgroundColor: AppColors.darkBlue,
              foregroundColor: AppColors.pureWhite,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                AppStrings.createCourse,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
    );
  }

  void _showCreateCourseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateCourseSheet(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final int index;

  const _CourseCard({required this.course, required this.index});

  static const List<Color> _gradients = [
    AppColors.darkBlue,
    AppColors.accentBlue,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _gradients[index % _gradients.length];

    return GlassCard(
      onTap: () => _showCourseDetails(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.pureWhite,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_rounded, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${course.studentIds.length} студент',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              course.description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _showCourseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseDetailSheet(course: course),
    );
  }
}

class _CourseDetailSheet extends StatelessWidget {
  final CourseModel course;

  const _CourseDetailSheet({required this.course});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final allStudents = data.students;
    // Use live course from provider so enrollment toggles update in real-time
    final currentCourse = data.courses.firstWhere(
      (c) => c.id == course.id,
      orElse: () => course,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              course.description,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Студенттерді тіркеу',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (allStudents.isEmpty)
            Text(
              'Студенттер жоқ. Алдымен студент тіркеңіз.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final student = allStudents[index];
                  final isEnrolled = currentCourse.studentIds.contains(student.uid);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                      child: Text(
                        student.fullName.isNotEmpty
                            ? student.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      student.group.isNotEmpty ? student.group : student.email,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: Switch(
                      value: isEnrolled,
                      activeTrackColor: AppColors.darkBlue.withValues(alpha: 0.3),
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.darkBlue
                            : null,
                      ),
                      onChanged: (value) async {
                        try {
                          if (value) {
                            await context
                                .read<DataProvider>()
                                .addStudentToCourse(course.id, student.uid);
                          } else {
                            await context
                                .read<DataProvider>()
                                .removeStudentFromCourse(course.id, student.uid);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Қате: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Курсты жою'),
        content: Text('"${course.name}" курсын жоясыз ба?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close sheet
              await context.read<DataProvider>().deleteCourse(course.id);
            },
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCourseSheet extends StatefulWidget {
  const _CreateCourseSheet();

  @override
  State<_CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<_CreateCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final data = context.read<DataProvider>();

      final course = CourseModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        teacherId: auth.user!.uid,
        teacherName: auth.user!.fullName,
        createdAt: DateTime.now(),
      );

      await data.createCourse(course);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_nameController.text.trim()}" курсы жасалды'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.createCourse,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PremiumTextField(
              controller: _nameController,
              labelText: AppStrings.courseName,
              hintText: 'Курс атауын жазыңыз',
              prefixIcon: Icons.menu_book_rounded,
              validator: (v) => v?.isEmpty == true ? 'Курс атауын енгізіңіз' : null,
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: _descController,
              labelText: AppStrings.courseDescription,
              hintText: 'Курс туралы қысқаша...',
              prefixIcon: Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            PremiumButton(
              text: AppStrings.createCourse,
              isLoading: _isLoading,
              onPressed: _createCourse,
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
