import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import 'kyc_upload_screen.dart';
import '../../products/presentation/vendor_products_screen.dart';
import '../../services/presentation/vendor_services_screen.dart';
import '../../enquiries/presentation/enquiry_list_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final vendor = user?.vendorProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user?.name ?? 'Vendor', vendor?.storeName ?? 'Store'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStoreCard(vendor),
                  const SizedBox(height: 16),
                  _buildMenuSection(),
                  const SizedBox(height: 16),
                  _buildSettingsSection(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(auth),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String name, String storeName) {
    return SliverAppBar(
      expandedHeight: 200,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.store,
                          size: 40, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(storeName,
                    style: TextStyle(
                        color: Colors.white.withAlpha(200), fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditVendorProfileScreen())),
        ),
      ],
    );
  }

  Widget _buildStoreCard(dynamic vendor) {
    final isApproved = vendor?.status == 'approved';
    final isVerified = vendor?.isVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Rating',
                    '${vendor?.rating?.toStringAsFixed(1) ?? '0.0'}',
                    Icons.star,
                    AppColors.warning),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildStatItem('Reviews', '${vendor?.totalRatings ?? 0}',
                    Icons.rate_review, AppColors.primary),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildStatItem(
                    'Status',
                    isApproved ? 'Active' : 'Pending',
                    Icons.verified,
                    isApproved ? AppColors.success : AppColors.warning),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(isVerified ? Icons.verified : Icons.pending,
                  color: isVerified ? AppColors.success : AppColors.warning,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                isVerified ? 'Verified Vendor' : 'Verification Pending',
                style: TextStyle(
                    color: isVerified ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (!isVerified)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KycUploadScreen()),
                  ),
                  child: const Text('Complete KYC'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.inventory_2, 'My Products', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VendorProductsScreen()),
            );
          }),
          _buildMenuItem(Icons.build_circle, 'My Services', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VendorServicesScreen()),
            );
          }),
          _buildMenuItem(Icons.mail, 'Enquiries', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnquiryListScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.description, 'KYC Documents', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KycUploadScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool showBadge = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('New',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(auth),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Logout', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.error),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child:
                const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class EditVendorProfileScreen extends StatefulWidget {
  const EditVendorProfileScreen({super.key});

  @override
  State<EditVendorProfileScreen> createState() =>
      _EditVendorProfileScreenState();
}

class _EditVendorProfileScreenState extends State<EditVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _storeNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final vendor = user?.vendorProfile;

    _nameController = TextEditingController(text: user?.name ?? '');
    _storeNameController = TextEditingController(text: vendor?.storeName ?? '');
    _descriptionController =
        TextEditingController(text: vendor?.description ?? '');
    _addressController =
        TextEditingController(text: vendor?.storeAddress ?? '');
    _cityController = TextEditingController(text: vendor?.city ?? '');
    _stateController = TextEditingController(text: vendor?.state ?? '');
    _pincodeController = TextEditingController(text: vendor?.pincode ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile({
      'name': _nameController.text.trim(),
      'store_name': _storeNameController.text.trim(),
      'store_description': _descriptionController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'phone': _phoneController.text.trim(),
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error ?? 'Failed to update profile'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Personal Information', [
              _buildTextField(
                  _nameController, 'Full Name', Icons.person_outline),
              _buildTextField(_phoneController, 'Phone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
            ]),
            const SizedBox(height: 16),
            _buildSection('Store Information', [
              _buildTextField(
                  _storeNameController, 'Store Name', Icons.store_outlined),
              _buildTextField(_descriptionController, 'Description',
                  Icons.description_outlined,
                  maxLines: 3),
              _buildTextField(
                  _addressController, 'Address', Icons.location_on_outlined,
                  maxLines: 2),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(_cityController, 'City', null)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTextField(_stateController, 'State', null)),
                ],
              ),
              _buildTextField(
                  _pincodeController, 'Pincode', Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...children.map((child) =>
            Padding(padding: const EdgeInsets.only(bottom: 12), child: child)),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData? icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2)),
      ),
      validator: (value) => value?.isEmpty == true ? 'Required' : null,
    );
  }
}
