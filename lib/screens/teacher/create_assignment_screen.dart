import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/glass_card.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'homework';
  String? _selectedCourseId;
  String _selectedCourseName = '';
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  final List<QuizQuestion> _quizQuestions = [];
  bool _isLoading = false;

  final _types = [
    {'value': 'homework', 'label': AppStrings.homework, 'icon': Icons.home_work_rounded},
    {'value': 'quiz', 'label': AppStrings.quiz, 'icon': Icons.quiz_rounded},
    {'value': 'test', 'label': AppStrings.test, 'icon': Icons.fact_check_rounded},
    {'value': 'project', 'label': AppStrings.project, 'icon': Icons.rocket_launch_rounded},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addQuizQuestion() {
    setState(() {
      _quizQuestions.add(
        const QuizQuestion(
          question: '',
          options: ['', '', '', ''],
          correctIndex: 0,
        ),
      );
    });
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Курсты таңдаңыз')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final data = context.read<DataProvider>();

      final assignment = AssignmentModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        courseId: _selectedCourseId!,
        courseName: _selectedCourseName,
        teacherId: auth.user!.uid,
        type: _selectedType,
        deadline: _deadline,
        createdAt: DateTime.now(),
        quizQuestions: _selectedType == 'quiz' ? _quizQuestions : [],
      );

      await data.createAssignment(assignment);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тапсырма сәтті жасалды'),
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
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(
        title: AppStrings.createAssignment,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assignment Type Selection
              const Text(
                AppStrings.assignmentType,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type['value'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.darkBlue : AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.darkBlue : AppColors.cardBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              size: 22,
                              color: isSelected ? AppColors.pureWhite : AppColors.textMuted,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.pureWhite : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              PremiumTextField(
                controller: _titleController,
                labelText: AppStrings.assignmentTitle,
                hintText: 'Тапсырма атауын жазыңыз',
                prefixIcon: Icons.title_rounded,
                validator: (v) => v?.isEmpty == true ? 'Атауды жазыңыз' : null,
              ),

              const SizedBox(height: 20),

              PremiumTextField(
                controller: _descController,
                labelText: AppStrings.description,
                hintText: 'Тапсырма сипаттамасы...',
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              // Course Selection
              const Text(
                AppStrings.courseSelection,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                margin: EdgeInsets.zero,
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedCourseId,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                  hint: const Text('Курсты таңдаңыз'),
                  items: data.courses.map((course) {
                    return DropdownMenuItem(
                      value: course.id,
                      child: Text(course.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                      _selectedCourseName = data.courses
                          .firstWhere((c) => c.id == value)
                          .name;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Deadline
              const Text(
                AppStrings.deadline,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              GlassCard(
                onTap: _selectDeadline,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accentBlue),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy, HH:mm').format(_deadline),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Quiz Questions
              if (_selectedType == 'quiz') ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Сұрақтар',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: _addQuizQuestion,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(AppStrings.addQuestion),
                    ),
                  ],
                ),
                ..._quizQuestions.asMap().entries.map((entry) {
                  return _QuizQuestionEditor(
                    index: entry.key,
                    question: entry.value,
                    onChanged: (q) {
                      setState(() => _quizQuestions[entry.key] = q);
                    },
                    onRemove: () {
                      setState(() => _quizQuestions.removeAt(entry.key));
                    },
                  );
                }),
              ],

              const SizedBox(height: 32),

              PremiumButton(
                text: AppStrings.createAssignment,
                isLoading: _isLoading,
                onPressed: _createAssignment,
                icon: Icons.add_task_rounded,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizQuestionEditor extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final ValueChanged<QuizQuestion> onChanged;
  final VoidCallback onRemove;

  const _QuizQuestionEditor({
    required this.index,
    required this.question,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${AppStrings.question} ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: question.question,
            decoration: const InputDecoration(hintText: 'Сұрақты жазыңыз'),
            onChanged: (v) => onChanged(QuizQuestion(
              question: v,
              options: question.options,
              correctIndex: question.correctIndex,
            )),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (i) {
            final labels = ['A', 'B', 'C', 'D'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // ignore: deprecated_member_use
                  Radio<int>(
                    value: i,
                    // ignore: deprecated_member_use
                    groupValue: question.correctIndex,
                    // ignore: deprecated_member_use
                    onChanged: (v) => onChanged(QuizQuestion(
                      question: question.question,
                      options: question.options,
                      correctIndex: v!,
                    )),
                  ),
                  Text('${labels[i]}) ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: TextFormField(
                      initialValue: i < question.options.length ? question.options[i] : '',
                      decoration: InputDecoration(hintText: '${labels[i]} нұсқасы'),
                      onChanged: (v) {
                        final opts = List<String>.from(question.options);
                        while (opts.length <= i) { opts.add(''); }
                        opts[i] = v;
                        onChanged(QuizQuestion(
                          question: question.question,
                          options: opts,
                          correctIndex: question.correctIndex,
                        ));
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
