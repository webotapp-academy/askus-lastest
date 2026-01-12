class AppNotification {
  final int id;
  final String uuid;
  final String type;
  final String title;
  final String body;
  final String? image;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.uuid,
    required this.type,
    required this.title,
    required this.body,
    this.image,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      image: json['image'],
      actionUrl: json['action_url'],
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['read_at'] != null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      uuid: uuid,
      type: type,
      title: title,
      body: body,
      image: image,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
