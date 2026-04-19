import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grade_model.dart';
import '../../models/user_model.dart';
import '../../providers/data_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/state_widgets.dart';

class TeacherGradesScreen extends StatelessWidget {
  const TeacherGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: 'Бағалар', showBack: true),
      body: data.students.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.grade_rounded,
              title: 'Студенттер жоқ',
              subtitle: 'Алдымен студент тіркеңіз',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              itemCount: data.students.length,
              itemBuilder: (context, index) {
                final student = data.students[index];
                return _StudentGradeCard(
                  student: student,
                  index: index,
                  courses: data.courses,
                ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.1);
              },
            ),
    );
  }
}

class _StudentGradeCard extends StatelessWidget {
  final UserModel student;
  final int index;
  final List courses;

  const _StudentGradeCard({
    required this.student,
    required this.index,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GradeModel>>(
      stream: FirestoreService().getGradesByStudent(student.uid),
      builder: (context, snapshot) {
        final grades = snapshot.data ?? [];
        final avg = grades.isEmpty
            ? 0.0
            : grades.fold<double>(0, (s, g) => s + g.percentage) /
                grades.length;
        final gpa = (avg / 100) * 4.0;

        return GlassCard(
          onTap: () => _showStudentGrades(context, grades),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _gpaColor(gpa).withValues(alpha: 0.12),
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _gpaColor(gpa),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.group.isNotEmpty ? student.group : student.email,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (grades.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(
                            label: 'GPA: ${gpa.toStringAsFixed(2)}',
                            color: _gpaColor(gpa),
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: '${avg.toStringAsFixed(0)}%',
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: '${grades.length} баға',
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.darkBlue),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStudentGrades(
      BuildContext context, List<GradeModel> grades) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentGradesSheet(
        student: student,
        grades: grades,
        courses: courses,
      ),
    );
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 3.5) return AppColors.success;
    if (gpa >= 2.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Student grades detail + add grade sheet
class _StudentGradesSheet extends StatefulWidget {
  final UserModel student;
  final List<GradeModel> grades;
  final List courses;

  const _StudentGradesSheet({
    required this.student,
    required this.grades,
    required this.courses,
  });

  @override
  State<_StudentGradesSheet> createState() => _StudentGradesSheetState();
}

class _StudentGradesSheetState extends State<_StudentGradesSheet> {
  bool _showAddForm = false;
  final _titleController = TextEditingController();
  final _scoreController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  String? _selectedCourseId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _scoreController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _addGrade() async {
    final title = _titleController.text.trim();
    final score = double.tryParse(_scoreController.text.trim()) ?? 0;
    final maxScore = double.tryParse(_maxScoreController.text.trim()) ?? 100;

    if (title.isEmpty || _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Барлық өрістерді толтырыңыз'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final course = widget.courses.firstWhere(
        (c) => c.id == _selectedCourseId,
        orElse: () => null,
      );
      final grade = GradeModel(
        id: const Uuid().v4(),
        studentId: widget.student.uid,
        courseId: _selectedCourseId!,
        courseName: course?.name ?? '',
        assignmentId: '',
        assignmentTitle: title,
        score: score,
        maxScore: maxScore,
        gradedAt: DateTime.now(),
      );
      await context.read<DataProvider>().createGrade(grade);
      if (mounted) {
        setState(() {
          _showAddForm = false;
          _titleController.clear();
          _scoreController.clear();
          _maxScoreController.text = '100';
          _selectedCourseId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Баға қосылды'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Қате: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = widget.grades;
    final avg = grades.isEmpty
        ? 0.0
        : grades.fold<double>(0, (s, g) => s + g.percentage) / grades.length;
    final gpa = (avg / 100) * 4.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + header
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.student.group.isNotEmpty)
                          Text(
                            widget.student.group,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // GPA summary banner
            if (grades.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkBlue, AppColors.accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCol(
                          label: 'GPA',
                          value: gpa.toStringAsFixed(2)),
                      Container(
                          width: 1,
                          height: 32,
                          color: Colors.white24),
                      _StatCol(
                          label: 'Орташа',
                          value: '${avg.toStringAsFixed(0)}%'),
                      Container(
                          width: 1,
                          height: 32,
                          color: Colors.white24),
                      _StatCol(
                          label: 'Бағалар',
                          value: '${grades.length}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Add grade button / form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _showAddForm
                  ? _AddGradeForm(
                      courses: widget.courses,
                      titleController: _titleController,
                      scoreController: _scoreController,
                      maxScoreController: _maxScoreController,
                      selectedCourseId: _selectedCourseId,
                      isLoading: _isLoading,
                      onCourseChanged: (id) =>
                          setState(() => _selectedCourseId = id),
                      onSave: _addGrade,
                      onCancel: () => setState(() => _showAddForm = false),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showAddForm = true),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Баға қосу'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkBlue,
                          side: const BorderSide(
                              color: AppColors.darkBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Grades list
            if (grades.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Бағалар жоқ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'Бағалар тарихы',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...grades.map((grade) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: _GradeRow(grade: grade),
                  )),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddGradeForm extends StatelessWidget {
  final List courses;
  final TextEditingController titleController;
  final TextEditingController scoreController;
  final TextEditingController maxScoreController;
  final String? selectedCourseId;
  final bool isLoading;
  final ValueChanged<String?> onCourseChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _AddGradeForm({
    required this.courses,
    required this.titleController,
    required this.scoreController,
    required this.maxScoreController,
    required this.selectedCourseId,
    required this.isLoading,
    required this.onCourseChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Жаңа баға қосу',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Course selector
          DropdownButtonFormField<String>(
            value: selectedCourseId,
            decoration: InputDecoration(
              labelText: 'Курс',
              filled: true,
              fillColor: AppColors.pureWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Курсты таңдаңыз'),
            items: courses
                .map((c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name,
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onCourseChanged,
          ),
          const SizedBox(height: 10),
          PremiumTextField(
            controller: titleController,
            labelText: 'Тапсырма атауы',
            hintText: 'Бақылау жұмысы, Емтихан...',
            prefixIcon: Icons.title_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: scoreController,
                  labelText: 'Балл',
                  hintText: '85',
                  prefixIcon: Icons.grade_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumTextField(
                  controller: maxScoreController,
                  labelText: 'Макс. балл',
                  hintText: '100',
                  prefixIcon: Icons.filter_1_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Болдырмау'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  text: 'Сақтау',
                  isLoading: isLoading,
                  onPressed: onSave,
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final GradeModel grade;

  const _GradeRow({required this.grade});

  Color _color(double pct) {
    if (pct >= 90) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(grade.percentage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                grade.letterGrade,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.assignmentTitle.isNotEmpty
                      ? grade.assignmentTitle
                      : 'Баға',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (grade.courseName.isNotEmpty)
                  Text(
                    grade.courseName,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${grade.score.toStringAsFixed(0)}/${grade.maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '${grade.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;

  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.pureWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: AppColors.pureWhite.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
