import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _api = ApiClient();
  late Razorpay _razorpay;

  // Callback functions
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<Map<String, dynamic>?> createVendorRegistrationOrder({
    required double amount,
    required String vendorId,
    required String email,
    required String phone,
    required String name,
  }) async {
    try {
      debugPrint('💳 Creating vendor registration payment order...');
      debugPrint('💰 Amount: ₹$amount');
      debugPrint('📧 Email: $email');
      debugPrint('📱 Phone: $phone');
      debugPrint('👤 Name: $name');

      // Send details to identify this as a registration payment
      final requestData = {
        'amount': amount,
        'email': email,
        'phone': phone,
        'name': name,
        'is_registration': true,
      };

      debugPrint('📤 Request data: $requestData');
      debugPrint('🌐 API endpoint: ${ApiConstants.vendorPaymentCreate}');

      final response =
          await _api.post(ApiConstants.vendorPaymentCreate, requestData);

      debugPrint('📨 Payment order response received');
      debugPrint('✅ Success: ${response.success}');
      debugPrint('💬 Message: ${response.message}');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📦 Response data: ${response.data}');

      if (response.success && response.data != null) {
        debugPrint('✅ Payment order created successfully');
        debugPrint('📋 Full Response Data: ${response.data}');

        final orderId = response.data!['order_id'];
        final razorpayKey = response.data!['razorpay_key'];
        final amountPaise = response.data!['amount'];

        debugPrint('🔍 Validating response fields:');
        debugPrint(
            '   Order ID: $orderId ${orderId != null && orderId.toString().isNotEmpty ? "✓" : "✗ MISSING"}');
        debugPrint(
            '   Razorpay Key: $razorpayKey ${razorpayKey != null && razorpayKey.toString().isNotEmpty ? "✓" : "✗ MISSING"}');
        debugPrint(
            '   Amount: $amountPaise paise ${amountPaise != null ? "✓" : "✗ MISSING"}');

        // Validate critical fields
        if (orderId == null || razorpayKey == null || amountPaise == null) {
          debugPrint('❌ CRITICAL: Server returned incomplete data!');
          debugPrint('   Missing fields will cause Razorpay checkout to fail');
          return null;
        }

        return response.data;
      } else {
        debugPrint('❌ Failed to create payment order');
        debugPrint('💬 Error message: ${response.message}');
        debugPrint('📊 Status code: ${response.statusCode}');
        debugPrint('📦 Error data: ${response.data}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in createVendorRegistrationOrder: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String vendorId,
  }) async {
    try {
      debugPrint('🔍 Verifying payment...');
      debugPrint('📋 Order ID: $razorpayOrderId');
      debugPrint('💳 Payment ID: $razorpayPaymentId');

      final response = await _api.post(ApiConstants.vendorPaymentVerify, {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      });

      debugPrint('📨 Payment verification response: ${response.success}');
      debugPrint('💬 Message: ${response.message}');

      if (response.success) {
        debugPrint('✅ Payment verified successfully');
        return true;
      } else {
        debugPrint('❌ Payment verification failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      return false;
    }
  }

  void startPayment({
    required Map<String, dynamic> options,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    debugPrint('🚀 Starting Razorpay payment...');
    debugPrint('💳 Options to be passed to Razorpay:');
    options.forEach((key, value) {
      debugPrint('   $key: $value');
    });

    // Validate options before passing to Razorpay
    if (options['key'] == null || options['key'].toString().isEmpty) {
      debugPrint('❌ FATAL: Razorpay key is null or empty!');
      final failureResponse = PaymentFailureResponse(
        0,
        'Configuration error: Missing Razorpay API key',
        null,
      );
      _onError?.call(failureResponse);
      return;
    }

    if (options['order_id'] == null || options['order_id'].toString().isEmpty) {
      debugPrint('❌ FATAL: Order ID is null or empty!');
      final failureResponse = PaymentFailureResponse(
        0,
        'Configuration error: Missing order ID',
        null,
      );
      _onError?.call(failureResponse);
      return;
    }

    try {
      debugPrint('✅ All validations passed, calling Razorpay.open()...');
      _razorpay.open(options);
      debugPrint('✅ Razorpay.open() called successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Exception when calling Razorpay.open(): $e');
      debugPrint('📍 Stack trace: $stackTrace');
      final failureResponse = PaymentFailureResponse(
        0,
        'Failed to open payment gateway: $e',
        null,
      );
      _onError?.call(failureResponse);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Payment successful!');
    debugPrint('💳 Payment ID: ${response.paymentId}');
    debugPrint('📋 Order ID: ${response.orderId}');
    debugPrint('🔐 Signature: ${response.signature}');

    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment failed!');
    debugPrint('💬 Error: ${response.message}');
    debugPrint('🔢 Code: ${response.code}');

    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('💼 External wallet selected: ${response.walletName}');
    _onExternalWallet?.call(response);
  }
}
