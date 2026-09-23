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

      // ✅ Use vendor data from registration form
      final vendorName = widget.vendorData['name'] as String?;
      final vendorEmail = widget.vendorData['email'] as String?;
      final vendorPhone = widget.vendorData['phone'] as String?;
      final amount = widget.vendorData['plan_amount'] as double?;

      if (vendorName == null || vendorEmail == null || vendorPhone == null || amount == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Registration data not found. Please go back and try again.');
        return;
      }

      // Generate a temporary ID for the payment
      final tempVendorId = vendorEmail.hashCode.toString().replaceAll('-', '');

      // Create payment order
      debugPrint('📞 Calling payment service...');

      await Future.delayed(const Duration(milliseconds: 100));

      final orderData = await _paymentService.createVendorRegistrationOrder(
        amount: amount,
        vendorId: tempVendorId,
        email: vendorEmail,
        phone: vendorPhone,
        name: vendorName,
      );

      debugPrint('📦 Order data received: $orderData');

      if (orderData == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Failed to create payment order. Please try again.');
        return;
      }

      final razorpayKey = orderData['razorpay_key'];
      final orderId = orderData['order_id'];
      final amountPaise = orderData['amount'];

      if (razorpayKey == null || orderId == null || amountPaise == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showError('Payment configuration error. Please contact support.');
        return;
      }

      final options = {
        'key': razorpayKey.toString(),
        'amount': amountPaise is int ? amountPaise : int.parse(amountPaise.toString()),
        'currency': 'INR',
        'name': 'Ask Us Marketplace',
        'description': 'Vendor Registration - ${widget.vendorData['vendor_type']}',
        'order_id': orderId.toString(),
        'prefill': {
          'contact': vendorPhone,
          'email': vendorEmail,
          'name': vendorName,
        },
        'theme': {'color': '#2196F3'},
        'notes': {
          'vendor_id': tempVendorId,
          'registration_type': widget.vendorData['vendor_type'] ?? 'vendor',
          'plan_id': widget.vendorData['plan_id']?.toString() ?? '',
        },
      };

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
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Payment processing failed. Please try again.');
      }
    }
  }

  Future<void> _handlePaymentSuccess(
      PaymentSuccessResponse response, String orderId) async {
    final authProvider = context.read<AuthProvider>();
    final vendorEmail = widget.vendorData['email'] as String?;
    final tempVendorId = (vendorEmail?.hashCode ?? 0).toString().replaceAll('-', '');

    final verified = await _paymentService.verifyPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
      vendorId: tempVendorId,
    );

    if (!mounted) return;

    if (verified) {
      String paymentId = widget.vendorData['payment_id']?.toString() ?? '';
      
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
        vendorType: widget.vendorData['vendor_type'] ?? 'vendor',
        categoryId: widget.vendorData['category_id'] is int 
            ? widget.vendorData['category_id'] as int 
            : (widget.vendorData['category_id'] != null 
                ? int.tryParse(widget.vendorData['category_id'].toString()) 
                : null),
        planId: widget.vendorData['plan_id']?.toString(),
        gstNumber: widget.vendorData['gst_number']?.isNotEmpty == true 
            ? widget.vendorData['gst_number'] 
            : null,
        panNumber: widget.vendorData['pan_number']?.isNotEmpty == true 
            ? widget.vendorData['pan_number'] 
            : null,
      );

      if (!mounted) return;

      if (registrationSuccess) {
        _showSuccessDialog();
      } else {
        _showError('Registration failed: ${authProvider.error}');
      }
    } else {
      _showError('Payment verification failed.');
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
    final amount = widget.vendorData['plan_amount'] as double? ?? 0.0;
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
                'Subscription Plan',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
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
                '₹${amount.toStringAsFixed(0)}',
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
    final isWorker = widget.vendorData['vendor_type'] == 'worker';
    final features = isWorker 
      ? [
          'List services in your area',
          'Get direct customer calls',
          'Verified worker badge',
        ]
      : [
          'List products on marketplace',
          'Manage inventory & orders',
          'Trusted vendor status',
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
            'Plan Benefits:',
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
    final amount = widget.vendorData['plan_amount'] as double? ?? 0.0;
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
                        'Pay ₹${amount.toStringAsFixed(0)}',
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
