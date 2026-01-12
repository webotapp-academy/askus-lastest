import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/helpers.dart';
import '../data/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().fetchChatList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.threads.isEmpty) {
            return const LoadingWidget();
          }

          if (provider.threads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No conversations yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation by sending an enquiry',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchChatList(),
            child: ListView.builder(
              itemCount: provider.threads.length,
              itemBuilder: (context, index) {
                final thread = provider.threads[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: thread.otherUserAvatar != null
                        ? NetworkImage(thread.otherUserAvatar!)
                        : null,
                    child: thread.otherUserAvatar == null
                        ? Text(thread.otherUserName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary))
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(thread.otherUserName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (thread.lastMessageAt != null)
                        Text(
                          Helpers.timeAgo(thread.lastMessageAt!),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage ?? 'No messages',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: thread.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: thread.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (thread.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            thread.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: thread.id,
                        otherUserId: thread.otherUserId,
                        otherUserName: thread.otherUserName,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
