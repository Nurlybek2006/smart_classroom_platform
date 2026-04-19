import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/state_widgets.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const StudentAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  final _answerController = TextEditingController();
  final Map<int, int> _quizAnswers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAssignment() async {
    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final data = context.read<DataProvider>();
      final assignment = data.assignments.firstWhere((a) => a.id == widget.assignmentId);

      double? quizScore;
      if (assignment.isQuiz && assignment.quizQuestions.isNotEmpty) {
        int correct = 0;
        for (int i = 0; i < assignment.quizQuestions.length; i++) {
          if (_quizAnswers[i] == assignment.quizQuestions[i].correctIndex) {
            correct++;
          }
        }
        quizScore = (correct / assignment.quizQuestions.length) * assignment.maxScore;
      }

      final submission = SubmissionModel(
        id: const Uuid().v4(),
        assignmentId: widget.assignmentId,
        studentId: auth.user!.uid,
        studentName: auth.user!.fullName,
        courseId: assignment.courseId,
        status: assignment.isQuiz ? 'graded' : 'submitted',
        textAnswer: _answerController.text.trim(),
        quizAnswers: (_quizAnswers.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
          .map((e) => e.value).toList(),
        score: quizScore,
        submittedAt: DateTime.now(),
        gradedAt: quizScore != null ? DateTime.now() : null,
      );

      await data.submitAssignment(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizScore != null
                ? 'Нәтиже: ${quizScore.toInt()}/${assignment.maxScore}'
                : 'Тапсырма сәтті жіберілді'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final assignment = data.assignments.where((a) => a.id == widget.assignmentId).firstOrNull;

    if (assignment == null) {
      return Scaffold(
        appBar: const PremiumAppBar(title: 'Тапсырма', showBack: true),
        body: const EmptyStateWidget(icon: Icons.assignment_rounded, title: 'Тапсырма табылмады'),
      );
    }

    final alreadySubmitted = data.submissions.any((s) => s.assignmentId == widget.assignmentId);

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: PremiumAppBar(title: assignment.title, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Курс', value: assignment.courseName),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Мерзімі',
                    value: DateFormat('dd.MM.yyyy HH:mm').format(assignment.deadline),
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'Ұпай', value: '${assignment.maxScore}'),
                  if (assignment.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(assignment.description, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),

            if (alreadySubmitted) ...[
              GlassCard(
                color: AppColors.successLight,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success),
                    const SizedBox(width: 12),
                    const Text(
                      'Тапсырма жіберілді',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),

              if (assignment.isQuiz && assignment.quizQuestions.isNotEmpty) ...[
                const Text(
                  'Тест сұрақтары',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...assignment.quizQuestions.asMap().entries.map((entry) {
                  final q = entry.value;
                  return GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ${q.question}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ...q.options.asMap().entries.map((opt) {
                          final labels = ['A', 'B', 'C', 'D'];
                          // ignore: deprecated_member_use
                          return RadioListTile<int>(
                            value: opt.key,
                            // ignore: deprecated_member_use
                            groupValue: _quizAnswers[entry.key],
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => _quizAnswers[entry.key] = v!),
                            title: Text('${labels[opt.key]}) ${opt.value}'),
                            toggleable: true,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const Text(
                  'Жауабыңыз',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(4),
                  margin: EdgeInsets.zero,
                  child: TextField(
                    controller: _answerController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Жауабыңызды жазыңыз...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              PremiumButton(
                text: assignment.isQuiz ? AppStrings.startQuiz : AppStrings.submit,
                isLoading: _isSubmitting,
                onPressed: _submitAssignment,
                icon: Icons.send_rounded,
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
