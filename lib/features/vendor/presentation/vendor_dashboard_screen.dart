import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../auth/data/auth_provider.dart';
import '../../products/data/product_provider.dart';
import '../../services/data/service_provider.dart';
import '../../enquiries/data/enquiry_provider.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../products/presentation/create_product_screen.dart';
import '../../services/presentation/create_service_screen.dart';
import '../../subscriptions/presentation/subscription_plans_screen.dart';
import 'kyc_upload_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  bool _kycPopupShown = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchVendorProducts();
        context.read<ServiceProvider>().fetchVendorServices();
        context.read<EnquiryProvider>().fetchEnquiries();

        // Check KYC status after a short delay
        _checkKycStatus();
      }
    });
  }

  void _checkKycStatus() {
    if (_kycPopupShown) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final user = context.read<AuthProvider>().user;
      final isApproved = user?.vendorProfile?.status == 'approved';
      final isVerified = user?.vendorProfile?.isVerified ?? false;

      // Show popup if vendor is not approved and not verified
      if (!isApproved && !isVerified) {
        _kycPopupShown = true;
        _showKycPromptDialog();
      }
    });
  }

  void _showKycPromptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Complete Your KYC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'To start selling on Ask Us, please complete your KYC verification by uploading required documents.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  _KycRequirementItem(
                      icon: Icons.credit_card, text: 'PAN Card'),
                  SizedBox(height: 8),
                  _KycRequirementItem(icon: Icons.badge, text: 'Aadhar Card'),
                  SizedBox(height: 8),
                  _KycRequirementItem(
                      icon: Icons.description,
                      text: 'GST Certificate (Optional)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycUploadScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Upload KYC',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final services = context.watch<ServiceProvider>();
    final enquiries = context.watch<EnquiryProvider>();

    final user = auth.user;
    final vendorProfile = user?.vendorProfile;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            auth.checkAuthStatus(),
            products.fetchVendorProducts(),
            services.fetchVendorServices(),
            enquiries.fetchEnquiries(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user?.name ?? 'Vendor',
                vendorProfile?.storeName ?? 'Your Store'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(vendorProfile),
                    const SizedBox(height: 16),
                    // ✅ Show subscription card if vendor has a plan (current_plan_id is set)
                    if (vendorProfile?.currentPlanId != null) ...[
                      _buildSubscriptionCard(
                          vendorProfile,
                          products.vendorProducts.length +
                              services.vendorServices.length),
                      const SizedBox(height: 16),
                    ],
                    _buildStatsGrid(
                      products.vendorProducts.length,
                      services.vendorServices.length,
                      enquiries.enquiries
                          .where((e) => e.status == 'pending')
                          .length,
                      vendorProfile?.rating ?? 0.0,
                    ),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentEnquiries(enquiries),
                    const SizedBox(height: 24),
                    _buildRecentProducts(products),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String name, String storeName) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.storefront,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        storeName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(dynamic vendorProfile) {
    final status = vendorProfile?.status ?? 'pending';
    final isApproved = status == 'approved';
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApproved
            ? AppColors.success.withAlpha(25)
            : isPending
                ? AppColors.warning.withAlpha(25)
                : AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved
              ? AppColors.success.withAlpha(75)
              : isPending
                  ? AppColors.warning.withAlpha(75)
                  : AppColors.error.withAlpha(75),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isApproved
                  ? AppColors.success.withAlpha(50)
                  : isPending
                      ? AppColors.warning.withAlpha(50)
                      : AppColors.error.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isApproved
                  ? Icons.verified_rounded
                  : isPending
                      ? Icons.hourglass_empty_rounded
                      : Icons.error_outline_rounded,
              color: isApproved
                  ? AppColors.success
                  : isPending
                      ? AppColors.warning
                      : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApproved
                      ? 'Store Verified'
                      : isPending
                          ? 'Verification Pending'
                          : 'Verification Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isApproved
                        ? AppColors.success
                        : isPending
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isApproved
                      ? 'Your store is live and accepting orders'
                      : isPending
                          ? 'Your application is under review'
                          : 'Please complete your KYC verification',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(dynamic vendorProfile, int totalListings) {
    if (vendorProfile == null) return const SizedBox.shrink();

    final hasPlan = vendorProfile.currentPlanId != null;
    final maxListings = vendorProfile.maxListings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subscription & Limits',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (hasPlan)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Active',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('No Plan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Listings: $totalListings / ${hasPlan ? maxListings : 0}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (hasPlan && maxListings > 0 && totalListings >= maxListings)
                const Text(
                  'LIMIT REACHED',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasPlan && maxListings > 0 ? totalListings / maxListings : 0,
              backgroundColor: AppColors.primary.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasPlan && maxListings > 0 && totalListings >= maxListings
                    ? AppColors.error
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Featured Days left: ${vendorProfile.availableFeaturedDays}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            'Boost Days left: ${vendorProfile.availableBoostDays}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionPlansScreen()));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Upgrade Plan / Buy Add-ons',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
      int products, int services, int pendingEnquiries, double rating) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.inventory_2_rounded,
          label: 'Products',
          value: products.toString(),
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.build_circle_rounded,
          label: 'Services',
          value: services.toString(),
          color: AppColors.secondary,
        ),
        _StatCard(
          icon: Icons.mail_rounded,
          label: 'Pending Enquiries',
          value: pendingEnquiries.toString(),
          color: AppColors.warning,
        ),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'Rating',
          value: rating.toStringAsFixed(1),
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final auth = context.read<AuthProvider>();
    final products = context.read<ProductProvider>();
    final services = context.read<ServiceProvider>();

    final user = auth.user;
    final vendorProfile = user?.vendorProfile;
    final isApproved = vendorProfile?.status == 'approved';
    final vendorType = vendorProfile?.vendorType ?? 'vendor';
    final hasPlan = vendorProfile?.currentPlanId != null;
    final maxListings = vendorProfile?.maxListings ?? 0;
    final currentListings =
        products.vendorProducts.length + services.vendorServices.length;

    void checkLimitAndNavigate(Widget screen) {
      if (!isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your vendor account is pending approval. Please wait for admin verification.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (!hasPlan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No active subscription plan found. Please subscribe to list items.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
        );
        return;
      }

      if (currentListings >= maxListings) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Listing limit reached for your current plan. Please upgrade to add more.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (vendorType == 'vendor' || vendorType == 'both')
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_box_rounded,
                  label: 'Add Product',
                  color: AppColors.primary,
                  onTap: () =>
                      checkLimitAndNavigate(const CreateProductScreen()),
                ),
              ),
            if (vendorType == 'worker' || vendorType == 'both') ...[
              if (vendorType == 'both') const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle_rounded,
                  label: 'Add Service',
                  color: AppColors.secondary,
                  onTap: () =>
                      checkLimitAndNavigate(const CreateServiceScreen()),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRecentEnquiries(EnquiryProvider enquiries) {
    final recentEnquiries = enquiries.enquiries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Enquiries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        if (recentEnquiries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No enquiries yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...recentEnquiries.map((enquiry) => _EnquiryCard(enquiry: enquiry)),
      ],
    );
  }

  Widget _buildRecentProducts(ProductProvider products) {
    final recentProducts = products.vendorProducts.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        if (recentProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No products yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...recentProducts.map((product) => _ProductCard(product: product)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(75)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  final dynamic enquiry;

  const _EnquiryCard({required this.enquiry});

  @override
  Widget build(BuildContext context) {
    final isPending = enquiry.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPending
                  ? AppColors.warning.withAlpha(25)
                  : AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.mail_outline,
              color: isPending ? AppColors.warning : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry.userName ?? 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  enquiry.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPending
                  ? AppColors.warning.withAlpha(25)
                  : AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              enquiry.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPending ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  )
                : const Icon(Icons.image, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Stock: ${product.stock}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KycRequirementItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _KycRequirementItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
