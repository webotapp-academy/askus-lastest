import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final _api = ApiClient();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.notifications);
    
    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['notifications'] ?? [];
      _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    await _api.post(ApiConstants.notificationRead, {'id': id});
    
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _api.post(ApiConstants.notificationRead, {'all': true});
    
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
