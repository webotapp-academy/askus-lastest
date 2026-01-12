import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/data/auth_provider.dart';
import '../data/product_provider.dart';
import '../data/product_model.dart';
import 'create_product_screen.dart';
import 'edit_product_screen.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchVendorProducts();
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

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    if (_filterStatus != 'all') {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Products'),
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
                MaterialPageRoute(builder: (_) => const CreateProductScreen()),
              ).then(
                  (_) => context.read<ProductProvider>().fetchVendorProducts());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.vendorProducts.isEmpty) {
                  return const LoadingWidget();
                }

                final filteredProducts =
                    _getFilteredProducts(provider.vendorProducts);

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState(provider.vendorProducts.isEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchVendorProducts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _ProductCard(
                        product: product,
                        onEdit: () => _editProduct(product),
                        onDelete: () => _deleteProduct(provider, product),
                        onToggleStatus: () => _toggleStatus(provider, product),
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
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          ).then((_) => context.read<ProductProvider>().fetchVendorProducts());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primary,
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
              hintText: 'Search products...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                _buildFilterChip('Draft', 'draft'),
                _buildFilterChip('Out of Stock', 'out_of_stock'),
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
        selectedColor: AppColors.primary.withAlpha(50),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noProducts) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noProducts ? Icons.inventory_2_outlined : Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            noProducts ? 'No products yet' : 'No products found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            noProducts
                ? 'Create your first product listing'
                : 'Try adjusting your filters',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (noProducts) ...[
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
                      builder: (_) => const CreateProductScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
    ).then((_) => context.read<ProductProvider>().fetchVendorProducts());
  }

  Future<void> _deleteProduct(ProductProvider provider, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Product deleted' : 'Failed to delete product'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(ProductProvider provider, Product product) async {
    final newStatus = product.status == 'active' ? 'inactive' : 'active';
    final success =
        await provider.updateProduct(product.id, {'status': newStatus});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status updated' : 'Failed to update status'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = product.status == 'active';
    final isOutOfStock = product.stock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: product.thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            product.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image,
                                color: AppColors.textSecondary),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (product.comparePrice != null &&
                              product.comparePrice! > product.price) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${product.comparePrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildStatusBadge(isActive, isOutOfStock),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: isOutOfStock
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOutOfStock
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleStatus();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit')
                        ])),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(isActive ? Icons.visibility_off : Icons.visibility,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error))
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool isOutOfStock) {
    String label;
    Color color;

    if (isOutOfStock) {
      label = 'OUT OF STOCK';
      color = AppColors.error;
    } else if (isActive) {
      label = 'ACTIVE';
      color = AppColors.success;
    } else {
      label = product.status.toUpperCase();
      color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
