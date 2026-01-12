class PaymentOrder {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final String status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final DateTime createdAt;

  PaymentOrder({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    required this.createdAt,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'].toString(),
      orderId: json['order_id'] ?? json['razorpay_order_id'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'pending',
      razorpayOrderId: json['razorpay_order_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      razorpaySignature: json['razorpay_signature'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class VendorRegistrationFee {
  static const double registrationFee = 1.0; // ₹1 registration fee (TEST MODE)
  static const double gstRate = 0.0; // 0% GST (TEST MODE)

  static double get totalAmount =>
      registrationFee + (registrationFee * gstRate);
  static double get gstAmount => registrationFee * gstRate;
}
