import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/helpers.dart';
import '../data/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationProvider>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const LoadingWidget();
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No notifications', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'You will receive notifications here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Container(
                  color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification.type).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        color: _getTypeColor(notification.type),
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.timeAgo(notification.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      if (!notification.isRead) {
                        provider.markAsRead(notification.id);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'enquiry':
        return Colors.orange;
      case 'chat':
        return Colors.green;
      case 'promo':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'enquiry':
        return Icons.mail;
      case 'chat':
        return Icons.chat;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}
