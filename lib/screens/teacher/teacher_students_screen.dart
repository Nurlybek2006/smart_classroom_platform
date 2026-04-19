import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/state_widgets.dart';

class TeacherStudentsScreen extends StatelessWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: PremiumAppBar(
        title: AppStrings.students,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/teacher/grades'),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grade_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showCreateStudentSheet(context),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: data.students.isEmpty
          ? EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: AppStrings.noStudents,
              subtitle: AppStrings.addStudentHint,
              buttonText: AppStrings.createStudent,
              onButtonPressed: () => _showCreateStudentSheet(context),
            )
          : Column(
              children: [
                // Summary bar
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkBlue, AppColors.accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_rounded, color: AppColors.pureWhite, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Барлығы: ${data.students.length} студент',
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    itemCount: data.students.length,
                    itemBuilder: (context, index) {
                      final student = data.students[index];
                      return _StudentCard(student: student, index: index)
                          .animate(delay: (index * 60).ms)
                          .fadeIn()
                          .slideX(begin: 0.1);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: data.students.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateStudentSheet(context),
              backgroundColor: AppColors.darkBlue,
              foregroundColor: AppColors.pureWhite,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                AppStrings.createStudent,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
    );
  }

  void _showCreateStudentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateStudentSheet(),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final int index;

  const _StudentCard({required this.student, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.accentBlue,
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
                  student.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (student.group.isNotEmpty || student.faculty.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (student.group.isNotEmpty)
                        _Chip(
                          icon: Icons.group_rounded,
                          label: student.group,
                        ),
                      if (student.faculty.isNotEmpty)
                        _Chip(
                          icon: Icons.school_rounded,
                          label: student.faculty,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEdit(context),
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.accentBlue,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStudentSheet(student: student),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.deleteStudentConfirm),
        content: Text(
          '"${student.fullName}" аккаунтын жойғаннан кейін жүйеге кіре алмайды.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<DataProvider>().deleteStudent(student.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Студент жойылды'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Edit Student Sheet ──────────────────────────────────────────────────────

class _EditStudentSheet extends StatefulWidget {
  final UserModel student;
  const _EditStudentSheet({required this.student});

  @override
  State<_EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends State<_EditStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _facultyController;
  late final TextEditingController _groupController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.fullName);
    _facultyController = TextEditingController(text: widget.student.faculty);
    _groupController = TextEditingController(text: widget.student.group);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = widget.student.copyWith(
        fullName: _nameController.text.trim(),
        faculty: _facultyController.text.trim(),
        group: _groupController.text.trim(),
      );
      await context.read<DataProvider>().updateStudentInfo(updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Студент мәліметтері жаңартылды'),
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
                  const Expanded(
                    child: Text(
                      'Студентті өзгерту',
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      widget.student.email,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PremiumTextField(
                controller: _nameController,
                labelText: AppStrings.fullName,
                hintText: 'Аты-жөнін жазыңыз',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v?.isEmpty == true ? 'Аты-жөнін енгізіңіз' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PremiumTextField(
                      controller: _facultyController,
                      labelText: AppStrings.faculty,
                      hintText: 'ФИТ, ФМиЕН...',
                      prefixIcon: Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumTextField(
                      controller: _groupController,
                      labelText: AppStrings.group,
                      hintText: 'CS-21, IT-22...',
                      prefixIcon: Icons.group_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PremiumButton(
                text: AppStrings.save,
                isLoading: _isLoading,
                onPressed: _save,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateStudentSheet extends StatefulWidget {
  const _CreateStudentSheet();

  @override
  State<_CreateStudentSheet> createState() => _CreateStudentSheetState();
}

class _CreateStudentSheetState extends State<_CreateStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facultyController = TextEditingController();
  final _groupController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _facultyController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().createStudent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            faculty: _facultyController.text.trim(),
            group: _groupController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} тіркелді'),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
                      AppStrings.createStudent,
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
                labelText: AppStrings.fullName,
                hintText: 'Аты-жөнін жазыңыз',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v?.isEmpty == true ? 'Аты-жөнін енгізіңіз' : null,
              ),
              const SizedBox(height: 14),
              PremiumTextField(
                controller: _emailController,
                labelText: AppStrings.email,
                hintText: 'student@edu.kz',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return AppStrings.emailRequired;
                  if (!v.contains('@')) return AppStrings.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              PremiumTextField(
                controller: _passwordController,
                labelText: AppStrings.studentPassword,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppStrings.passwordRequired;
                  if (v.length < 6) return 'Кем дегенде 6 таңба';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PremiumTextField(
                      controller: _facultyController,
                      labelText: AppStrings.faculty,
                      hintText: 'ФИТ, ФМиЕН...',
                      prefixIcon: Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumTextField(
                      controller: _groupController,
                      labelText: AppStrings.group,
                      hintText: 'CS-21, IT-22...',
                      prefixIcon: Icons.group_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PremiumButton(
                text: AppStrings.createStudent,
                isLoading: _isLoading,
                onPressed: _createStudent,
                icon: Icons.person_add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
