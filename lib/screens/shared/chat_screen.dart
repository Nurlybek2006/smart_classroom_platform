import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/premium_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _firestoreService = FirestoreService();

  late String _chatId;
  late String _myId;
  late String _myName;
  late Future<UserModel?> _otherUserFuture;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _myId = auth.user!.uid;
    _myName = auth.user!.fullName;
    _chatId = MessageModel.generateChatId(_myId, widget.otherUserId);
    _otherUserFuture = _firestoreService.getUser(widget.otherUserId);
    _firestoreService.markMessagesAsRead(_chatId, _myId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final message = MessageModel(
      id: '',
      chatId: _chatId,
      senderId: _myId,
      senderName: _myName,
      receiverId: widget.otherUserId,
      text: text,
      timestamp: DateTime.now(),
    );

    _firestoreService.sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _otherUserFuture,
      builder: (context, userSnap) {
        final otherName = userSnap.data?.fullName ?? '...';
        return Scaffold(
          backgroundColor: AppColors.softGray,
          appBar: PremiumAppBar(title: otherName, showBack: true),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _firestoreService.getMessages(_chatId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'Хабарлама жазыңыз',
                              style: TextStyle(
                                  fontSize: 16, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == _myId;
                        return _MessageBubble(
                          message: msg,
                          isMe: isMe,
                        );
                      },
                    );
                  },
                ),
              ),

              // Input bar
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Хабарлама жазыңыз...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.softGray,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: AppColors.pureWhite, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accentBlue : AppColors.pureWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? AppColors.pureWhite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? AppColors.pureWhite.withValues(alpha: 0.6)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
