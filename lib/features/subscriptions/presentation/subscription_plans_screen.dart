import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/data/auth_provider.dart';
import '../data/subscription_provider.dart';
import '../data/subscription_plan_model.dart';
import '../../vendor/presentation/vendor_dashboard_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late Razorpay _razorpay;
  int? _processingPlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorType =
          context.read<AuthProvider>().user?.vendorProfile?.vendorType ??
              'vendor';
      context.read<SubscriptionProvider>().fetchPlans(targetGroup: vendorType);
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final provider = context.read<SubscriptionProvider>();

    if (_processingPlanId == null) return;

    final success = await provider.purchasePlan(
        _processingPlanId!,
        response.paymentId ?? '',
        response.orderId ?? '',
        response.signature ?? '');

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Subscription Activated!'),
            backgroundColor: AppColors.success),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Activation failed'),
            backgroundColor: AppColors.error),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: AppColors.error),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final provider = context.read<SubscriptionProvider>();
    final orderData = await provider.createSubscriptionOrder(plan.id);

    if (orderData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.error ?? 'Failed to create order'),
              backgroundColor: AppColors.error),
        );
      }
      return;
    }

    _processingPlanId = plan.id;

    try {
      final options = {
        'key': orderData['razorpay_key'],
        'amount': orderData['amount'],
        'name': 'Ask Us Subscription',
        'order_id': orderData['order_id'],
        'description': '${plan.name} Plan',
        'prefill': orderData['prefill'],
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error initializing payment: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.plans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final vt = context
                              .read<AuthProvider>()
                              .user
                              ?.vendorProfile
                              ?.vendorType ??
                          'vendor';
                      provider.fetchPlans(targetGroup: vt);
                    },
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          if (provider.plans.isEmpty) {
            return const Center(
                child: Text('No plans available at the moment.'));
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.plans.length,
                itemBuilder: (context, index) {
                  final plan = provider.plans[index];
                  return _SubscriptionCard(
                    plan: plan,
                    onSubscribe: () => _subscribe(plan),
                  );
                },
              ),
              if (provider.isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onSubscribe;

  const _SubscriptionCard({required this.plan, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${plan.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Valid for ${plan.durationDays} days',
                style: const TextStyle(color: AppColors.textSecondary)),
            const Divider(height: 32),
            _FeatureRow(
                icon: Icons.inventory_2,
                text: 'Up to ${plan.maxListings} Listings'),
            if (plan.featuredDays > 0)
              _FeatureRow(
                  icon: Icons.star, text: '${plan.featuredDays} Featured Days'),
            if (plan.boostDays > 0)
              _FeatureRow(
                  icon: Icons.rocket_launch,
                  text: '${plan.boostDays} Boost Days'),
            if (plan.hasTrustedBadge)
              _FeatureRow(
                  icon: Icons.verified_user, text: 'Trusted Vendor Badge'),
            if (plan.hasVerifiedBadge)
              _FeatureRow(icon: Icons.check_circle, text: 'Verified Badge'),
            if (plan.hasTopPlacement)
              _FeatureRow(
                  icon: Icons.vertical_align_top,
                  text: 'Priority Search Placement'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Select ${plan.name} Plan',
                onPressed: onSubscribe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
