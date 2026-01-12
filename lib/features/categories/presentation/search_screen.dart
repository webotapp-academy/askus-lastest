import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../products/data/product_model.dart';
import '../../services/data/service_model.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../services/presentation/service_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _api = ApiClient();
  
  List<Product> _products = [];
  List<Service> _services = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _searchType = 'all';
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _search(_searchController.text);
      }
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _hasSearched = false;
        _products = [];
        _services = [];
        _errorMessage = null;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await _api.get(ApiConstants.search, params: {
        'q': query.trim(),
        'type': _searchType,
      });
      
      if (response.success && response.data != null) {
        final productsData = response.data!['products'] as List? ?? [];
        final servicesData = response.data!['services'] as List? ?? [];
        
        debugPrint('🔍 Search Response - Products count: ${productsData.length}');
        debugPrint('🔍 Search Response - Services count: ${servicesData.length}');
        
        // Debug first product if available
        if (productsData.isNotEmpty) {
          debugPrint('🔍 First product data: ${productsData.first}');
        }
        
        // Debug first service if available
        if (servicesData.isNotEmpty) {
          debugPrint('🔍 First service data: ${servicesData.first}');
        }
        
        setState(() {
          _products = productsData.map((json) {
            try {
              return Product.fromJson(json);
            } catch (e) {
              debugPrint('❌ Error parsing product: $e');
              debugPrint('❌ Product JSON: $json');
              rethrow;
            }
          }).toList();
          _services = servicesData.map((json) {
            try {
              return Service.fromJson(json);
            } catch (e) {
              debugPrint('❌ Error parsing service: $e');
              debugPrint('❌ Service JSON: $json');
              rethrow;
            }
          }).toList();
          _hasSearched = true;
          _isLoading = false;
        });
        
        // Debug parsed products
        if (_products.isNotEmpty) {
          debugPrint('✅ First parsed product: name=${_products.first.name}, price=${_products.first.price}, thumbnail=${_products.first.thumbnail}');
        }
        
        // Debug parsed services
        if (_services.isNotEmpty) {
          debugPrint('✅ First parsed service: name=${_services.first.name}, price=${_services.first.price}, thumbnail=${_services.first.thumbnail}, images=${_services.first.images}');
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Search failed';
          _hasSearched = true;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _hasSearched = true;
        _isLoading = false;
      });
      debugPrint('Search error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _onFilterChanged(String newType) {
    setState(() => _searchType = newType);
    if (_searchController.text.isNotEmpty) {
      _search(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search products & services...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _searchType == 'all',
                  onTap: () => _onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Products',
                  isSelected: _searchType == 'products',
                  onTap: () => _onFilterChanged('products'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Services',
                  isSelected: _searchType == 'services',
                  onTap: () => _onFilterChanged('services'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _search(_searchController.text),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : !_hasSearched
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 64, color: AppColors.textSecondary),
                                SizedBox(height: 16),
                                Text(
                                  'Search for products and services',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _products.isEmpty && _services.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                                    SizedBox(height: 16),
                                    Text(
                                      'No results found',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Try different keywords',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_products.isNotEmpty) ...[
                            const Text(
                              'Products',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...(_products.map((p) => _SearchResultCard(
                              title: p.name,
                              subtitle: p.vendorName ?? '',
                              price: p.price,
                              image: p.thumbnail ?? (p.images.isNotEmpty ? p.images.first : null),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: p.id),
                                ),
                              ),
                            ))),
                            const SizedBox(height: 24),
                          ],
                          if (_services.isNotEmpty) ...[
                            const Text(
                              'Services',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...(_services.map((s) => _SearchResultCard(
                              title: s.name,
                              subtitle: s.vendorName ?? '',
                              price: s.price,
                              image: s.thumbnail ?? (s.images.isNotEmpty ? s.images.first : null),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceDetailScreen(serviceId: s.id),
                                ),
                              ),
                            ))),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double price;
  final String? image;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.title,
    required this.subtitle,
    required this.price,
    this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: image != null && image!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    image!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                )
              : const Icon(
                  Icons.image_outlined,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          '₹${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
