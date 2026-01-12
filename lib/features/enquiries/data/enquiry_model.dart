class Enquiry {
  final int id;
  final String uuid;
  final String type;
  final int itemId;
  final String? itemName;
  final int userId;
  final String? userName;
  final String? userPhone;
  final int vendorId;
  final String? vendorName;
  final String message;
  final String? vendorResponse;
  final String status;
  final String? preferredDate;
  final String? preferredTime;
  final DateTime createdAt;
  final DateTime? respondedAt;

  Enquiry({
    required this.id,
    required this.uuid,
    required this.type,
    required this.itemId,
    this.itemName,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.vendorId,
    this.vendorName,
    required this.message,
    this.vendorResponse,
    required this.status,
    this.preferredDate,
    this.preferredTime,
    required this.createdAt,
    this.respondedAt,
  });

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      type: json['type'] ?? 'product',
      itemId: json['item_id'] ?? 0,
      itemName:
          json['item_name'] ?? json['product_name'] ?? json['service_name'],
      userId: json['user_id'] ?? 0,
      userName: json['user_name'],
      userPhone: json['user_phone'],
      vendorId: json['vendor_id'] ?? 0,
      vendorName: json['vendor_name'] ?? json['store_name'],
      message: json['message'] ?? '',
      vendorResponse: json['response'] ?? json['vendor_response'],
      status: json['status'] ?? 'pending',
      preferredDate: json['preferred_date'],
      preferredTime: json['preferred_time'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isResponded => status == 'responded';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
}
