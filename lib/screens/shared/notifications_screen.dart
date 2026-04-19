import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/state_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final unreadCount = data.notifications.where((n) => !n.isRead).length;
    final isTeacher = auth.user?.isTeacher ?? false;

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: PremiumAppBar(
        title: AppStrings.notifications,
        actions: unreadCount > 0
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () async {
                      for (final n in data.notifications.where((n) => !n.isRead)) {
                        await data.markNotificationAsRead(n.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.darkBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Барлығын оқыдым',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: data.notifications.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'Хабарламалар жоқ',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              itemCount: data.notifications.length,
              itemBuilder: (context, index) {
                final n = data.notifications[index];
                return GlassCard(
                  onTap: n.isRead
                      ? null
                      : () => data.markNotificationAsRead(n.id),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (!n.isRead ? AppColors.accentBlue : AppColors.textMuted)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _notifIcon(n.type),
                          color: !n.isRead ? AppColors.accentBlue : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: !n.isRead ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeago.format(n.createdAt, locale: 'en_short'),
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ).animate(delay: (index * 60).ms).fadeIn().slideX(begin: 0.05);
              },
            ),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _CreateAnnouncementSheet(
                  students: data.students,
                ),
              ),
              backgroundColor: AppColors.darkBlue,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'deadline_reminder':
        return Icons.schedule_rounded;
      case 'assignment_created':
        return Icons.assignment_rounded;
      case 'grade_posted':
        return Icons.grade_rounded;
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

// ── Create Announcement Sheet ───────────────────────────────────────────────

class _CreateAnnouncementSheet extends StatefulWidget {
  final List<UserModel> students;
  const _CreateAnnouncementSheet({required this.students});

  @override
  State<_CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<_CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = context.read<DataProvider>();
      final now = DateTime.now();
      for (final student in widget.students) {
        final notif = NotificationModel(
          id: '',
          userId: student.uid,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: 'announcement',
          createdAt: now,
        );
        await data.createNotification(notif);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.students.length} студентке хабарлама жіберілді',
            ),
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
                      'Хабарлама жіберу',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 16, color: AppColors.accentBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Барлық студенттерге: ${widget.students.length} адам',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PremiumTextField(
                controller: _titleController,
                labelText: 'Тақырып',
                hintText: 'Хабарлама тақырыбы...',
                prefixIcon: Icons.title_rounded,
                validator: (v) => v?.isEmpty == true ? 'Тақырыпты енгізіңіз' : null,
              ),
              const SizedBox(height: 14),
              PremiumTextField(
                controller: _bodyController,
                labelText: 'Мәтін',
                hintText: 'Хабарлама мазмұны...',
                prefixIcon: Icons.message_outlined,
                maxLines: 4,
                validator: (v) => v?.isEmpty == true ? 'Мәтінді енгізіңіз' : null,
              ),
              const SizedBox(height: 24),
              PremiumButton(
                text: 'Жіберу',
                isLoading: _isLoading,
                onPressed: widget.students.isEmpty ? null : _send,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
