import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/submission_model.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/state_widgets.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadSubmissionsByAssignment(widget.assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final assignment = data.assignments.where((a) => a.id == widget.assignmentId).firstOrNull;

    if (assignment == null) {
      return Scaffold(
        appBar: const PremiumAppBar(title: 'Тапсырма', showBack: true),
        body: const EmptyStateWidget(
          icon: Icons.assignment_rounded,
          title: 'Тапсырма табылмады',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: PremiumAppBar(title: assignment.title, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Курс', value: assignment.courseName),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Түрі',
                    value: _typeLabel(assignment.type),
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Мерзімі',
                    value: DateFormat('dd.MM.yyyy HH:mm').format(assignment.deadline),
                  ),
                  if (assignment.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Сипаттама',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      assignment.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Submissions
            const SizedBox(height: 8),
            Text(
              '${AppStrings.recentSubmissions} (${data.submissions.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (data.submissions.isEmpty)
              GlassCard(
                child: Center(
                  child: Text(
                    'Жіберілімдер жоқ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...data.submissions.asMap().entries.map((entry) {
                final sub = entry.value;
                return GlassCard(
                  onTap: () => _showGradingSheet(context, sub, assignment.maxScore),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                        child: Text(
                          sub.studentName.isNotEmpty ? sub.studentName[0] : '?',
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(sub.submittedAt),
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (sub.textAnswer != null && sub.textAnswer!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  sub.textAnswer!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _StatusBadge(status: sub.status),
                          if (sub.score != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${sub.score!.toInt()}/${assignment.maxScore}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.darkBlue,
                              ),
                            ),
                          ] else if (sub.status == 'submitted') ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Баға қою',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: (entry.key * 100).ms).fadeIn();
              }),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'quiz': return AppStrings.quiz;
      case 'test': return AppStrings.test;
      case 'project': return AppStrings.project;
      default: return AppStrings.homework;
    }
  }

  void _showGradingSheet(
      BuildContext context, SubmissionModel submission, int maxScore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradingSheet(
        submission: submission,
        maxScore: maxScore,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'graded':
        color = AppColors.success;
        label = AppStrings.graded;
        break;
      case 'submitted':
        color = AppColors.accentBlue;
        label = AppStrings.submitted;
        break;
      case 'overdue':
        color = AppColors.error;
        label = AppStrings.overdue;
        break;
      default:
        color = AppColors.warning;
        label = AppStrings.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _GradingSheet extends StatefulWidget {
  final SubmissionModel submission;
  final int maxScore;

  const _GradingSheet({required this.submission, required this.maxScore});

  @override
  State<_GradingSheet> createState() => _GradingSheetState();
}

class _GradingSheetState extends State<_GradingSheet> {
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.submission.score != null) {
      _scoreController.text = widget.submission.score!.toInt().toString();
    }
    if (widget.submission.feedback != null) {
      _feedbackController.text = widget.submission.feedback!;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _saveGrade() async {
    final scoreText = _scoreController.text.trim();
    if (scoreText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Балл енгізіңіз')),
      );
      return;
    }

    final score = double.tryParse(scoreText);
    if (score == null || score < 0 || score > widget.maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('0 мен ${widget.maxScore} арасындағы балл енгізіңіз')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<DataProvider>().gradeSubmission(
            widget.submission.id,
            score,
            _feedbackController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.gradeSuccess),
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
    final sub = widget.submission;

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
      child: SingleChildScrollView(
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                  child: Text(
                    sub.studentName.isNotEmpty ? sub.studentName[0] : '?',
                    style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        AppStrings.gradeSubmission,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),

            // Student's answer
            if (sub.textAnswer != null && sub.textAnswer!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.yourAnswer,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub.textAnswer!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Score input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.score} (макс. ${widget.maxScore})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.softGray,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          controller: _scoreController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBlue,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.softGray,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '/ ${widget.maxScore}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Feedback input
            const Text(
              AppStrings.feedbackLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Студентке пікір жазыңыз...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            PremiumButton(
              text: AppStrings.gradeSubmission,
              isLoading: _isLoading,
              onPressed: _saveGrade,
              icon: Icons.check_circle_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

