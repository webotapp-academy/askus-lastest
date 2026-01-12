import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PaymentProvider extends ChangeNotifier {
  final _api = ApiClient();
  
  bool _isLoading = false;
  String? _error;
  String? _razorpayOrderId;
  String? _razorpayKey;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get razorpayOrderId => _razorpayOrderId;
  String? get razorpayKey => _razorpayKey;

  Future<bool> createPaymentOrder({
    required String type,
    required int itemId,
    required double amount,
    String? couponCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(ApiConstants.paymentCreate, {
      'type': type,
      'item_id': itemId,
      'amount': amount,
      if (couponCode != null) 'coupon_code': couponCode,
    });

    if (response.success && response.data != null) {
      _razorpayOrderId = response.data!['order_id'];
      _razorpayKey = response.data!['razorpay_key'];
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = response.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.post(ApiConstants.paymentVerify, {
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    });

    _isLoading = false;
    notifyListeners();

    if (response.success) {
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<Map<String, dynamic>?> validateCoupon(String code, double amount) async {
    final response = await _api.post(ApiConstants.couponValidate, {
      'code': code,
      'amount': amount,
    });

    if (response.success && response.data != null) {
      return response.data;
    }

    _error = response.message;
    return null;
  }
}
