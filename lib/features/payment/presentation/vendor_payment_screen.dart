import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../auth/data/auth_provider.dart';
import '../data/payment_service.dart';
import '../data/payment_model.dart';
import '../../location/presentation/location_screen.dart';

class VendorPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vendorData;

  const VendorPaymentScreen({
    super.key,
    required this.vendorData,
  });

  @override
  State<VendorPaymentScreen> createState() => _VendorPaymentScreenState();
}

class _VendorPaymentScreenState extends State<VendorPaymentScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Show warning about emulator limitations in debug mode
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('⚠️ RAZORPAY EMULATOR NOTICE:');
        debugPrint(
            '   Razorpay checkout may not work properly on Android emulators');
        debugPrint('   For best results, test on a physical device');
        debugPrint(
            '   Common emulator issues: WebView crashes, "Something went wrong" errors');
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      debugPrint('🏪 Processing vendor registration payment...');

      // ✅ Use vendor data from registration form, not authenticated user
      // (user is not authenticated yet in the new flow)
      final vendorName = widget.vendorData['name'] as String?;
      final vendorEmail = widget.vendorData['email'] as String?;
      final vendorPhone = widget.vendorData['phone'] as String?;

      if (vendorName == null || vendorEmail == null || vendorPhone == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Registration data not found. Please go back and try again.');
        return;
      }

      // Generate a temporary ID for the payment (vendor ID will be assigned after creation)
      // Use a hash of email as temporary ID
      final tempVendorId = vendorEmail.hashCode.toString().replaceAll('-', '');

      // Create payment order
      debugPrint('📞 Calling payment service...');

      // Use compute or Future.delayed to prevent UI blocking
      await Future.delayed(const Duration(milliseconds: 100));

      final orderData = await _paymentService.createVendorRegistrationOrder(
        amount: VendorRegistrationFee.totalAmount,
        vendorId: tempVendorId,
        email: vendorEmail,
        phone: vendorPhone,
        name: vendorName,
      );

      debugPrint('📦 Order data received: $orderData');

      if (orderData == null) {
        debugPrint('❌ Order data is null - payment creation failed');
        debugPrint(
            '🔍 This means the API returned success=false or threw an error');
        debugPrint('📋 Check the API logs above for the exact error message');
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError(
            'Failed to create payment order. Please check your connection and try again.');
        return;
      }

      debugPrint('✅ Order data is valid, preparing Razorpay options...');

      // ⚠️ CRITICAL VALIDATION - Check all required fields
      final razorpayKey = orderData['razorpay_key'];
      final orderId = orderData['order_id'];
      final amount = orderData['amount'];

      debugPrint('🔍 Validating required fields...');
      debugPrint(
          '   Key: ${razorpayKey != null ? "✓ Present" : "✗ MISSING"} (${razorpayKey ?? "null"})');
      debugPrint(
          '   Order ID: ${orderId != null ? "✓ Present" : "✗ MISSING"} (${orderId ?? "null"})');
      debugPrint(
          '   Amount: ${amount != null ? "✓ Present" : "✗ MISSING"} (${amount ?? "null"})');

      // Validate required fields
      if (razorpayKey == null || razorpayKey.toString().isEmpty) {
        debugPrint('❌ CRITICAL: Razorpay Key is missing from server response!');
        debugPrint(
            '📋 This will cause "Something went wrong" error in Razorpay checkout');
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Payment configuration error. Please contact support.');
        return;
      }

      if (orderId == null || orderId.toString().isEmpty) {
        debugPrint('❌ CRITICAL: Order ID is missing!');
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Failed to create payment order. Please try again.');
        return;
      }

      if (amount == null) {
        debugPrint('❌ CRITICAL: Amount is missing!');
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Payment amount error. Please try again.');
        return;
      }

      // Validate key format
      final keyStr = razorpayKey.toString();
      if (!keyStr.startsWith('rzp_test_') && !keyStr.startsWith('rzp_live_')) {
        debugPrint('❌ WARNING: Invalid Razorpay key format: $keyStr');
        debugPrint('   Expected format: rzp_test_xxxxx or rzp_live_xxxxx');
      }

      // Prepare Razorpay options using vendor data
      final options = {
        'key': keyStr,
        'amount': amount is int ? amount : int.parse(amount.toString()),
        'currency': 'INR',
        'name': 'Ask Us Marketplace',
        'description': 'Vendor Registration Fee',
        'order_id': orderId.toString(),
        'prefill': {
          'contact': vendorPhone,
          'email': vendorEmail,
          'name': vendorName,
        },
        'theme': {
          'color': '#2196F3',
        },
        'notes': {
          'vendor_id': tempVendorId,
          'registration_type': 'vendor',
        },
      };

      debugPrint('🚀 Starting Razorpay payment...');
      debugPrint('💳 Final Options:');
      debugPrint('   ├─ key: ${options['key']}');
      debugPrint(
          '   ├─ amount: ${options['amount']} paise (₹${(options['amount'] as int) / 100})');
      debugPrint('   ├─ currency: ${options['currency']}');
      debugPrint('   ├─ order_id: ${options['order_id']}');
      debugPrint('   ├─ prefill: ${options['prefill']}');
      debugPrint('   └─ notes: ${options['notes']}');

      // Start payment - don't set _isProcessing to false here
      // It will be reset in the callbacks
      // Store payment_id in vendorData for later use
      widget.vendorData['payment_id'] = orderData['payment_id']?.toString() ?? '';
      
      _paymentService.startPayment(
        options: options,
        onSuccess: (PaymentSuccessResponse response) {
          if (mounted) {
            setState(() => _isProcessing = false);
            _handlePaymentSuccess(
                response, orderData['payment_id']?.toString() ?? '');
          }
        },
        onError: (PaymentFailureResponse response) {
          if (mounted) {
            setState(() => _isProcessing = false);
            _handlePaymentError(response);
          }
        },
        onExternalWallet: (ExternalWalletResponse response) {
          debugPrint('💼 External wallet: ${response.walletName}');
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Payment processing error: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Payment processing failed. Please try again.');
      }
    }
    // Note: Don't reset _isProcessing here - it will be reset in payment callbacks
  }

  Future<void> _handlePaymentSuccess(
      PaymentSuccessResponse response, String orderId) async {
    debugPrint('✅ Payment successful, verifying...');

    final authProvider = context.read<AuthProvider>();
    
    // Use vendor data from registration form instead of authenticated user
    final vendorEmail = widget.vendorData['email'] as String?;
    final tempVendorId = (vendorEmail?.hashCode ?? 0).toString().replaceAll('-', '');

    // Verify payment
    final verified = await _paymentService.verifyPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
      vendorId: tempVendorId,
    );

    if (!mounted) return;

    if (verified) {
      debugPrint('✅ Payment verified, now creating vendor in database...');
      
      // Extract payment ID from the verification response or widget data
      String paymentId = widget.vendorData['payment_id']?.toString() ?? '';
      
      if (paymentId.isEmpty) {
        _showError('Payment ID not found. Please contact support.');
        return;
      }

      // Create the vendor in database only after successful payment verification
      final registrationSuccess = await authProvider.createVendorAfterPayment(
        name: widget.vendorData['name'],
        email: widget.vendorData['email'],
        phone: widget.vendorData['phone'],
        password: widget.vendorData['password'] ?? '',
        storeName: widget.vendorData['store_name'],
        storeAddress: widget.vendorData['store_address'],
        city: widget.vendorData['city'],
        state: widget.vendorData['state'],
        pincode: widget.vendorData['pincode'],
        paymentId: paymentId,
        gstNumber: widget.vendorData['gst_number']?.isNotEmpty == true 
            ? widget.vendorData['gst_number'] 
            : null,
        panNumber: widget.vendorData['pan_number']?.isNotEmpty == true 
            ? widget.vendorData['pan_number'] 
            : null,
      );

      if (!mounted) return;

      if (registrationSuccess) {
        HapticFeedback.mediumImpact();
        _showSuccessDialog();
      } else {
        HapticFeedback.heavyImpact();
        _showError('Vendor registration failed. Please contact support: ${authProvider.error}');
      }
    } else {
      HapticFeedback.heavyImpact();
      _showError('Payment verification failed. Please contact support.');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment failed: ${response.message}');
    debugPrint('🔢 Error code: ${response.code}');
    HapticFeedback.heavyImpact();

    String errorMessage = 'Payment failed. Please try again.';

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment was cancelled.';
      debugPrint('👤 User cancelled the payment');
    } else if (response.code == Razorpay.NETWORK_ERROR) {
      errorMessage = 'Network error. Please check your internet connection.';
      debugPrint('🌐 Network error detected');
    } else if (response.code == 0) {
      // Code 0 typically means Razorpay checkout failed to load
      errorMessage = 'Failed to load payment gateway. Please try again.';
      debugPrint('⚠️ Razorpay checkout failed to initialize');
    } else {
      debugPrint('⚠️ Unknown error code: ${response.code}');
      errorMessage = response.message ?? errorMessage;
    }

    _showError(errorMessage);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your vendor registration is complete. Welcome to Ask Us Marketplace!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LocationScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue to Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildPricingCard(),
                const SizedBox(height: 24),
                _buildFeaturesList(),
                const SizedBox(height: 32),
                _buildPaymentButton(),
                const SizedBox(height: 16),
                _buildSecurityNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.payment_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Complete Your Registration',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'One-time registration fee to join our marketplace',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registration Fee',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${VendorRegistrationFee.registrationFee.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GST (18%)',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${VendorRegistrationFee.gstAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${VendorRegistrationFee.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'List unlimited products & services',
      'Direct customer enquiries',
      '24/7 customer support',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you get:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _processPayment,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pay ₹${VendorRegistrationFee.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Secure payment powered by Razorpay. Your payment information is encrypted and safe.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
