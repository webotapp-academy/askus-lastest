import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/data/auth_provider.dart';
import '../data/service_provider.dart';
import '../data/service_model.dart';
import 'create_service_screen.dart';
import 'edit_service_screen.dart';

class VendorServicesScreen extends StatefulWidget {
  const VendorServicesScreen({super.key});

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServiceProvider>().fetchVendorServices();
      }
    });
  }

  bool _isVendorApproved(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    return user?.vendorProfile?.status == 'approved';
  }

  void _showPendingApprovalMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Your vendor account is pending approval. Please wait for admin verification.'),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 3),
      ),
    );
  }

  List<Service> _getFilteredServices(List<Service> services) {
    var filtered = services;
    if (_filterStatus != 'all') {
      filtered = filtered.where((s) => s.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Services'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              if (!_isVendorApproved(context)) {
                _showPendingApprovalMessage();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateServiceScreen()),
              ).then(
                  (_) => context.read<ServiceProvider>().fetchVendorServices());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<ServiceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.vendorServices.isEmpty) {
                  return const LoadingWidget();
                }
                final filteredServices =
                    _getFilteredServices(provider.vendorServices);
                if (filteredServices.isEmpty) {
                  return _buildEmptyState(provider.vendorServices.isEmpty);
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchVendorServices(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return _ServiceCard(
                        service: service,
                        onEdit: () => _editService(service),
                        onDelete: () => _deleteService(provider, service),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!_isVendorApproved(context)) {
            _showPendingApprovalMessage();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateServiceScreen()),
          ).then((_) => context.read<ServiceProvider>().fetchVendorServices());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Inactive', 'inactive'),
                _buildFilterChip('Pending', 'pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterStatus = value),
        selectedColor: AppColors.secondary.withAlpha(50),
        checkmarkColor: AppColors.secondary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noServices) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(noServices ? Icons.build_outlined : Icons.search_off,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(noServices ? 'No services yet' : 'No services found',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
              noServices
                  ? 'Create your first service listing'
                  : 'Try adjusting your filters',
              style: const TextStyle(color: AppColors.textSecondary)),
          if (noServices) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (!_isVendorApproved(context)) {
                  _showPendingApprovalMessage();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateServiceScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  void _editService(Service service) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditServiceScreen(service: service)))
        .then((_) => context.read<ServiceProvider>().fetchVendorServices());
  }

  Future<void> _deleteService(ServiceProvider provider, Service service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await provider.deleteService(service.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success ? 'Service deleted' : 'Failed to delete'),
              backgroundColor: success ? AppColors.success : AppColors.error),
        );
      }
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard(
      {required this.service, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = service.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10)),
              child: service.thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(service.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.build,
                              color: AppColors.textSecondary)),
                    )
                  : const Icon(Icons.build, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('₹${service.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withAlpha(25)
                                : AppColors.warning.withAlpha(25),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(service.status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.warning)),
                      ),
                      if (service.rating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(service.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit')
                    ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error))
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
