import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../models/grade_model.dart';
import '../../models/user_model.dart';
import '../../providers/data_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/state_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────

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
                  courses: data.courses,
                  assignments: data.assignments,
                ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.1);
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StudentGradeCard extends StatelessWidget {
  final UserModel student;
  final List<CourseModel> courses;
  final List<AssignmentModel> assignments;

  const _StudentGradeCard({
    required this.student,
    required this.courses,
    required this.assignments,
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
        final color = _gpaColor(gpa);

        return GlassCard(
          onTap: () => _open(context),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                        student.group.isNotEmpty
                            ? student.group
                            : student.email,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    if (grades.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Badge(
                              label: 'GPA: ${gpa.toStringAsFixed(2)}',
                              color: color),
                          _Badge(
                              label: '${avg.toStringAsFixed(0)}%',
                              color: AppColors.accentBlue),
                          _Badge(
                              label: '${grades.length} баға',
                              color: AppColors.textMuted),
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
                child: const Icon(Icons.assignment_rounded,
                    size: 18, color: AppColors.darkBlue),
              ),
            ],
          ),
        );
      },
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentGradesSheet(
        student: student,
        courses: courses,
        assignments: assignments,
      ),
    );
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 3.5) return AppColors.success;
    if (gpa >= 2.5) return AppColors.warning;
    return AppColors.error;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StudentGradesSheet extends StatefulWidget {
  final UserModel student;
  final List<CourseModel> courses;
  final List<AssignmentModel> assignments;

  const _StudentGradesSheet({
    required this.student,
    required this.courses,
    required this.assignments,
  });

  @override
  State<_StudentGradesSheet> createState() => _StudentGradesSheetState();
}

class _StudentGradesSheetState extends State<_StudentGradesSheet> {
  bool _showForm = false;
  bool _saving = false;

  Future<void> _onSave(
    List<GradeModel> grades,
    String courseId,
    String assignmentId,
    double score,
    double maxScore,
  ) async {
    // Extra guard: no duplicate
    if (grades.any((g) => g.assignmentId == assignmentId)) {
      _snack('Бұл тапсырмаға баға қойылып қойған', AppColors.warning);
      return;
    }
    final course = widget.courses.firstWhere((c) => c.id == courseId,
        orElse: () =>
            CourseModel(id: '', name: '', teacherId: '', createdAt: DateTime.now()));
    final assignment = widget.assignments.firstWhere((a) => a.id == assignmentId,
        orElse: () => AssignmentModel(
              id: '',
              title: '',
              courseId: '',
              teacherId: '',
              type: 'homework',
              deadline: DateTime.now(),
              createdAt: DateTime.now(),
            ));

    setState(() => _saving = true);
    try {
      final grade = GradeModel(
        id: const Uuid().v4(),
        studentId: widget.student.uid,
        courseId: courseId,
        courseName: course.name,
        assignmentId: assignmentId,
        assignmentTitle: assignment.title,
        score: score,
        maxScore: maxScore,
        gradedAt: DateTime.now(),
      );
      await context.read<DataProvider>().createGrade(grade);
      if (mounted) {
        setState(() => _showForm = false);
        _snack('Баға қойылды', AppColors.success);
      }
    } catch (e) {
      if (mounted) _snack('Қате: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GradeModel>>(
      stream: FirestoreService().getGradesByStudent(widget.student.uid),
      builder: (context, snapshot) {
        final grades = snapshot.data ?? [];
        final avg = grades.isEmpty
            ? 0.0
            : grades.fold<double>(0, (s, g) => s + g.percentage) /
                grades.length;
        final gpa = (avg / 100) * 4.0;
        final gradedIds = grades
            .where((g) => g.assignmentId.isNotEmpty)
            .map((g) => g.assignmentId)
            .toSet();

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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

              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.student.fullName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          if (widget.student.group.isNotEmpty)
                            Text(widget.student.group,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
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

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GPA banner
                      if (grades.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              AppColors.darkBlue,
                              AppColors.accentBlue,
                            ]),
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
                      const SizedBox(height: 16),

                      // Form toggle
                      if (!_showForm)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _showForm = true),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Баға қою'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.darkBlue,
                              side: const BorderSide(
                                  color: AppColors.darkBlue, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        )
                      else
                        _AddGradeForm(
                          courses: widget.courses,
                          assignments: widget.assignments,
                          gradedIds: gradedIds,
                          isSaving: _saving,
                          onSave: (cId, aId, score, max) =>
                              _onSave(grades, cId, aId, score, max),
                          onCancel: () =>
                              setState(() => _showForm = false),
                        ),

                      const SizedBox(height: 20),

                      // Grades table
                      if (grades.isEmpty)
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: const [
                                Icon(Icons.grade_outlined,
                                    size: 40, color: AppColors.textMuted),
                                SizedBox(height: 8),
                                Text('Бағалар жоқ',
                                    style: TextStyle(
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        const Text('Бағалар кестесі',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        _GradesTable(grades: grades),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Grade Form — StatefulWidget (manages its own selection state)
// ─────────────────────────────────────────────────────────────────────────────

class _AddGradeForm extends StatefulWidget {
  final List<CourseModel> courses;
  final List<AssignmentModel> assignments;
  final Set<String> gradedIds;
  final bool isSaving;
  final Function(String courseId, String assignmentId, double score,
      double maxScore) onSave;
  final VoidCallback onCancel;

  const _AddGradeForm({
    required this.courses,
    required this.assignments,
    required this.gradedIds,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_AddGradeForm> createState() => _AddGradeFormState();
}

class _AddGradeFormState extends State<_AddGradeForm> {
  String? _courseId;
  String? _assignmentId;
  double _maxScore = 100;
  final _scoreCtrl = TextEditingController();
  String? _scoreError;

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  List<AssignmentModel> get _available => widget.assignments
      .where((a) =>
          a.courseId == _courseId && !widget.gradedIds.contains(a.id))
      .toList();

  void _onCourse(String? id) {
    setState(() {
      _courseId = id;
      _assignmentId = null;
      _maxScore = 100;
      _scoreCtrl.clear();
      _scoreError = null;
    });
  }

  void _onAssignment(String? id) {
    if (id == null) return;
    final list = _available;
    final idx = list.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    setState(() {
      _assignmentId = id;
      _maxScore = list[idx].maxScore.toDouble();
      _scoreCtrl.clear();
      _scoreError = null;
    });
  }

  void _validate() {
    final score = double.tryParse(_scoreCtrl.text.trim());
    if (score == null) {
      setState(() => _scoreError = 'Сан енгізіңіз');
    } else if (score < 0 || score > _maxScore) {
      setState(() =>
          _scoreError = '0 – ${_maxScore.toStringAsFixed(0)} аралығында');
    } else {
      setState(() => _scoreError = null);
      widget.onSave(_courseId!, _assignmentId!, score, _maxScore);
    }
  }

  InputDecoration _dec(String label, {String? hint, String? errorText}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final available = _available;
    final canSave = _courseId != null &&
        _assignmentId != null &&
        _scoreCtrl.text.trim().isNotEmpty &&
        _scoreError == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Баға қою',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // ── Step 1: Course ──────────────────────────────────────────
          DropdownButtonFormField<String>(
            value: _courseId,
            decoration: _dec('Курс'),
            hint: const Text('Курсты таңдаңыз'),
            isExpanded: true,
            items: widget.courses
                .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: _onCourse,
          ),

          // ── Step 2: Assignment ──────────────────────────────────────
          if (_courseId != null) ...[
            const SizedBox(height: 10),
            if (available.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Барлық тапсырмаларға баға қойылған',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _assignmentId,
                decoration: _dec('Тапсырма'),
                hint: const Text('Тапсырманы таңдаңыз'),
                isExpanded: true,
                items: available
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            children: [
                              Icon(
                                a.isQuiz
                                    ? Icons.quiz_rounded
                                    : Icons.assignment_rounded,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(a.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Text(
                                '  /${a.maxScore}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: _onAssignment,
              ),
          ],

          // ── Step 3: Score ───────────────────────────────────────────
          if (_assignmentId != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreCtrl,
                    decoration: _dec(
                      'Балл',
                      hint: '0 – ${_maxScore.toStringAsFixed(0)}',
                      errorText: _scoreError,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() => _scoreError = null),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    'Макс: ${_maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // ── Buttons ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Болдырмау'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (canSave && !widget.isSaving) ? _validate : null,
                  icon: widget.isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Сақтау'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.darkBlue.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grades Table
// ─────────────────────────────────────────────────────────────────────────────

class _GradesTable extends StatelessWidget {
  final List<GradeModel> grades;
  const _GradesTable({required this.grades});

  Color _col(double pct) {
    if (pct >= 90) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yy');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 60,
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
              AppColors.darkBlue.withValues(alpha: 0.05)),
          columns: const [
            DataColumn(
                label: Text('№',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(
                label: Text('Курс',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(
                label: Text('Тапсырма',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(
                label: Text('Күні',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(
                numeric: true,
                label: Text('Балл',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(
                label: Text('Баға',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12))),
          ],
          rows: grades.asMap().entries.map((e) {
            final g = e.value;
            final c = _col(g.percentage);
            return DataRow(cells: [
              DataCell(Text('${e.key + 1}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted))),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(g.courseName.isNotEmpty ? g.courseName : '—',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              )),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                    g.assignmentTitle.isNotEmpty
                        ? g.assignmentTitle
                        : '—',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              )),
              DataCell(Text(fmt.format(g.gradedAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
              DataCell(Text(
                  '${g.score.toStringAsFixed(0)}/${g.maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: c))),
              DataCell(Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(g.letterGrade,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: c)),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

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
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}