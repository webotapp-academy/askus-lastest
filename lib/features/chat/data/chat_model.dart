class ChatThread {
  final int id;
  final String uuid;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.uuid,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      otherUserId: json['other_user_id'] ?? 0,
      otherUserName: json['other_user_name'] ?? 'User',
      otherUserAvatar: json['other_user_avatar'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at']) : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final String uuid;
  final int senderId;
  final String senderName;
  final String message;
  final String? attachment;
  final String? attachmentType;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.uuid,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.attachment,
    this.attachmentType,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      message: json['message'] ?? '',
      attachment: json['attachment'],
      attachmentType: json['attachment_type'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
