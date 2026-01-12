import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../categories/data/category_provider.dart';
import '../../categories/data/category_model.dart';
import '../data/product_provider.dart';
import '../data/product_model.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const ProductListScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scrollController = ScrollController();
  final _api = ApiClient();

  // Local state for filtered category view
  List<Product> _filteredProducts = [];
  bool _isLoadingFiltered = false;
  bool _hasMoreFiltered = true;
  int _currentPageFiltered = 1;

  bool get _isFilteredByCategory => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_isFilteredByCategory) {
          // Load filtered products locally
          _fetchFilteredProducts(refresh: true);
        } else {
          // Load all products via provider
          context.read<CategoryProvider>().fetchCategories();
          context.read<ProductProvider>().fetchProducts(refresh: true);
        }
      }
    });
  }

  Future<void> _fetchFilteredProducts({bool refresh = false}) async {
    if (_isLoadingFiltered && !refresh) return;

    if (refresh) {
      _currentPageFiltered = 1;
      _hasMoreFiltered = true;
      _filteredProducts = [];
    }

    if (!_hasMoreFiltered) return;

    setState(() => _isLoadingFiltered = true);

    final params = {
      'page': _currentPageFiltered.toString(),
      'category_id': widget.categoryId.toString(),
    };

    final response = await _api.get(ApiConstants.products, params: params);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['products'] ?? [];
      final newProducts = data.map((json) => Product.fromJson(json)).toList();

      setState(() {
        _filteredProducts.addAll(newProducts);
        _hasMoreFiltered = newProducts.length >= 20;
        _currentPageFiltered++;
        _isLoadingFiltered = false;
      });
    } else {
      setState(() => _isLoadingFiltered = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_isFilteredByCategory) {
        if (!_isLoadingFiltered && _hasMoreFiltered) {
          _fetchFilteredProducts();
        }
      } else {
        final provider = context.read<ProductProvider>();
        if (!provider.isLoading && provider.hasMore) {
          provider.fetchProducts();
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Group products by category
  Map<int, List<Product>> _groupProductsByCategory(List<Product> products) {
    final Map<int, List<Product>> grouped = {};
    for (final product in products) {
      if (!grouped.containsKey(product.categoryId)) {
        grouped[product.categoryId] = [];
      }
      grouped[product.categoryId]!.add(product);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Products'),
        elevation: 0,
      ),
      body: _isFilteredByCategory
          ? _buildFilteredView()
          : _buildCategoryWiseView(),
    );
  }

  Widget _buildFilteredView() {
    if (_isLoadingFiltered && _filteredProducts.isEmpty) {
      return const LoadingWidget();
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_outlined,
                size: 60, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No products found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchFilteredProducts(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredProducts.length + (_hasMoreFiltered ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredProducts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = _filteredProducts[index];
          return _ProductGridCard(product: product);
        },
      ),
    );
  }

  Widget _buildCategoryWiseView() {
    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, categoryProvider, _) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const LoadingWidget();
        }

        if (productProvider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.inventory_2_outlined,
                    size: 60, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text(
                  'No products found',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final groupedProducts =
            _groupProductsByCategory(productProvider.products);
        final categories = categoryProvider.categories;

        return RefreshIndicator(
          onRefresh: () async {
            await categoryProvider.fetchCategories();
            await productProvider.fetchProducts(refresh: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 20),
            itemCount:
                groupedProducts.keys.length + (productProvider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= groupedProducts.keys.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final categoryId = groupedProducts.keys.elementAt(index);
              final products = groupedProducts[categoryId]!;

              final category = categories.firstWhere(
                (c) => c.id == categoryId,
                orElse: () => Category(
                  id: categoryId,
                  name: products.first.categoryName ?? 'Other',
                  slug: '',
                  sortOrder: 0,
                  status: 'active',
                ),
              );

              return _CategorySection(
                category: category,
                products: products,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      categoryId: categoryId,
                      categoryName: category.name,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Category category;
  final List<Product> products;
  final VoidCallback onViewAll;

  const _CategorySection({
    required this.category,
    required this.products,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _ProductCard(product: products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    color: AppColors.background,
                    child: product.thumbnail != null &&
                            product.thumbnail!.isNotEmpty
                        ? Image.network(
                            product.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 30,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 30,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '₹${product.comparePrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;

  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.background,
                      child: product.thumbnail != null &&
                              product.thumbnail!.isNotEmpty
                          ? Image.network(
                              product.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_outlined,
                                    size: 30, color: AppColors.textSecondary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 30, color: AppColors.textSecondary),
                            ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '₹${product.comparePrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
