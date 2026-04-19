import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/state_widgets.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isTeacher = auth.user?.isTeacher ?? false;

    if (isTeacher) {
      return const _TeacherChatList();
    } else {
      return const _StudentChatList();
    }
  }
}

// Teacher: shows all students
class _TeacherChatList extends StatelessWidget {
  const _TeacherChatList();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final myId = context.read<AuthProvider>().user!.uid;

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.chat, showBack: true),
      body: data.students.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Студенттер жоқ',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: data.students.length,
              itemBuilder: (context, index) {
                final user = data.students[index];
                return _ChatTile(user: user, myId: myId, index: index);
              },
            ),
    );
  }
}

// Student: shows all teachers
class _StudentChatList extends StatelessWidget {
  const _StudentChatList();

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user!.uid;

    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.chat, showBack: true),
      body: StreamBuilder<List<UserModel>>(
        stream: FirestoreService().getUsersByRole('teacher'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teachers = snapshot.data!;
          if (teachers.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Мұғалімдер жоқ',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final user = teachers[index];
              return _ChatTile(user: user, myId: myId, index: index);
            },
          );
        },
      ),
    );
  }
}

// Shared Chat Tile with last message preview
class _ChatTile extends StatelessWidget {
  final UserModel user;
  final String myId;
  final int index;

  const _ChatTile({
    required this.user,
    required this.myId,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final chatId = MessageModel.generateChatId(myId, user.uid);

    return StreamBuilder<List<MessageModel>>(
      stream: FirestoreService().getMessages(chatId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        final lastMsg = messages.isNotEmpty ? messages.last : null;
        final hasUnread =
            messages.where((m) => m.receiverId == myId && !m.isRead).isNotEmpty;

        return GlassCard(
          onTap: () => context.push('/chat/${user.uid}'),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppColors.accentBlue.withValues(alpha: 0.1),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.pureWhite, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMsg != null)
                          Text(
                            timeago.format(lastMsg.timestamp,
                                locale: 'en_short'),
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppColors.accentBlue
                                  : AppColors.textMuted,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastMsg != null
                          ? (lastMsg.senderId == myId
                              ? 'Сен: ${lastMsg.text}'
                              : lastMsg.text)
                          : (user.isTeacher
                              ? AppStrings.teacher
                              : AppStrings.student),
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: hasUnread
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.1);
      },
    );
  }
}
