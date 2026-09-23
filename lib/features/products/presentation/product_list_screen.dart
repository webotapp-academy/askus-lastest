import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
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
  final int? subcategoryId;
  final String? subcategoryName;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scrollController = ScrollController();
  final _api = ApiClient();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentLocaleId;
  Timer? _silenceTimer;

  // Local state for filtered category view using grouped API response
  bool _isLoadingFiltered = false;
  // Grouped results returned by the API: list of {subcategory_id, subcategory_name, products: List<Product>}
  List<Map<String, dynamic>> _filteredGroups = [];

  bool get _isFilteredByCategory => widget.categoryId != null;
  bool get _isFilteredBySubcategory => widget.subcategoryId != null;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech init error: $error');
          setState(() => _isListening = false);
        },
      );
      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
      });
      if (available) {
        final sysLocale = await _speech.systemLocale();
        if (!mounted) return;
        setState(() {
          _currentLocaleId = sysLocale?.localeId;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      setState(() {
        _speechAvailable = false;
      });
    }
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
        // Fetch all subcategories for all categories
        final categories = context.read<CategoryProvider>().categories;
        for (final category in categories) {
          context.read<CategoryProvider>().fetchSubcategories(category.id);
        }
      }
    });
  }

  Future<void> _fetchFilteredProducts({bool refresh = false}) async {
    // If filtering by subcategory, fetch products for that specific subcategory
    if (_isFilteredBySubcategory) {
      await _fetchSubcategoryProducts(refresh: refresh);
      return;
    }
    // For category-filtered view we now use grouped-by-subcategory endpoint
    if (_isLoadingFiltered && !refresh) return;

    if (refresh) {
      _filteredGroups = [];
    }
    setState(() => _isLoadingFiltered = true);

    final params = {
      'category_id': widget.categoryId.toString(),
      'per_subcategory_limit': '50',
    };

    try {
      final response = await _api
          .get(ApiConstants.productsByCategorySubcategories, params: params);
      if (response.success && response.data != null) {
        final List<dynamic> groups = response.data!['subcategories'] ?? [];
        final parsed = <Map<String, dynamic>>[];
        for (final g in groups) {
          final subId = g['subcategory_id'];
          final subName = g['subcategory_name'];
          final prods = <Product>[];
          final rawProds = (g['products'] as List<dynamic>?) ?? [];
          for (final p in rawProds) {
            prods.add(Product.fromJson(p));
          }
          parsed.add({
            'subcategory_id': subId,
            'subcategory_name': subName,
            'products': prods,
            'count': g['count'] ?? prods.length,
          });
        }

        if (mounted) {
          setState(() {
            _filteredGroups = parsed;
            _isLoadingFiltered = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFiltered = false);
      }
    } catch (e) {
      debugPrint('Error fetching grouped filtered products: $e');
      if (mounted) setState(() => _isLoadingFiltered = false);
    }
  }

  Future<void> _fetchSubcategoryProducts({bool refresh = false}) async {
    // Fetch products for a specific subcategory using the standard products endpoint
    if (_isLoadingFiltered && !refresh) return;

    if (refresh) {
      _filteredGroups = [];
    }
    setState(() => _isLoadingFiltered = true);

    final params = <String, String>{};
    if (widget.categoryId != null) {
      params['category_id'] = widget.categoryId.toString();
    }
    if (widget.subcategoryId != null) {
      params['subcategory_id'] = widget.subcategoryId.toString();
    }
    params['limit'] = '100';

    try {
      final response = await _api.get(ApiConstants.products, params: params);
      if (response.success && response.data != null) {
        final List<dynamic> productsData = response.data!['products'] ?? [];
        final products = productsData.map((p) => Product.fromJson(p)).toList();

        // Group all products under one "group" for consistent UI
        final parsed = <Map<String, dynamic>>[
          {
            'subcategory_id': widget.subcategoryId ?? 0,
            'subcategory_name': widget.subcategoryName ?? 'Products',
            'products': products,
            'count': products.length,
          }
        ];

        if (mounted) {
          setState(() {
            _filteredGroups = parsed;
            _isLoadingFiltered = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFiltered = false);
      }
    } catch (e) {
      debugPrint('Error fetching subcategory products: $e');
      if (mounted) setState(() => _isLoadingFiltered = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_isFilteredByCategory) {
        // Grouped API returns all results at once, no pagination needed
        // No infinite scroll for category-filtered view
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
    _silenceTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Check microphone permission first
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (!mounted) return;
        _showPermissionDialog();
        return;
      }
    } else if (micPermission.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermissionDialog();
      return;
    }

    // Initialize speech if not available
    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isListening = true);

    _startSilenceTimer();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          _resetSilenceTimer();

          setState(() {
            _searchController.text = result.recognizedWords;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
            _searchQuery = result.recognizedWords;
          });

          if (result.finalResult) {
            _stopListening();
          }
        },
        localeId: _currentLocaleId,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start voice recognition: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    try {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      if (!mounted) return;
      setState(() => _isListening = false);
    }
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (_isListening) {
        debugPrint('Auto-stopping listening after 5 seconds of silence');
        _stopListening();
      }
    });
  }

  void _resetSilenceTimer() {
    if (_isListening) {
      _startSilenceTimer();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to convert your voice to text for searching. '
          'Please enable microphone permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((product) {
      final searchLower = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(searchLower) ||
          product.description.toLowerCase().contains(searchLower) ||
          (product.categoryName?.toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text(widget.subcategoryName ?? widget.categoryName ?? 'Products'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: _isListening
                              ? AppColors.error
                              : AppColors.primary,
                          size: 22,
                        ),
                        onPressed:
                            _isListening ? _stopListening : _startListening,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Listening indicator banner
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.red.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Listening... Speak now',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.red.shade600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isFilteredByCategory
                ? _buildFilteredView()
                : _buildCategoryWiseView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredView() {
    // Check if we're loading and have no groups yet
    if (_isLoadingFiltered && _filteredGroups.isEmpty) {
      return const LoadingWidget();
    }

    // If we have no groups at all, show empty state
    if (_filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No products found'
                  : 'No products match your search',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Filter groups based on search query
    List<Map<String, dynamic>> displayGroups = _filteredGroups;
    if (_searchQuery.isNotEmpty) {
      displayGroups = _filteredGroups
          .map((group) {
            final products = group['products'] as List<Product>;
            final filteredProducts = products.where((product) {
              final searchLower = _searchQuery.toLowerCase();
              return product.name.toLowerCase().contains(searchLower) ||
                  (product.description?.toLowerCase().contains(searchLower) ??
                      false) ||
                  (product.subcategoryName
                          ?.toLowerCase()
                          .contains(searchLower) ??
                      false);
            }).toList();

            return {
              'subcategory_id': group['subcategory_id'],
              'subcategory_name': group['subcategory_name'],
              'products': filteredProducts,
              'count': filteredProducts.length,
            };
          })
          .where((group) => (group['products'] as List).isNotEmpty)
          .toList();
    }

    // If search filtered out everything
    if (displayGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No products match your search',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchFilteredProducts(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: displayGroups.length,
        itemBuilder: (context, index) {
          final group = displayGroups[index];
          final subcategoryId = group['subcategory_id'] ?? 0;
          final subcategoryName = group['subcategory_name'] ?? 'Uncategorized';
          final products = group['products'] as List<Product>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SubcategoryProductSection(
              subcategoryId: subcategoryId,
              subcategoryName: subcategoryName,
              products: products,
            ),
          );
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

        final filteredProducts = _getFilteredProducts(productProvider.products);

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 60, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'No products found'
                      : 'No products match your search',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final groupedProducts = _groupProductsByCategory(filteredProducts);
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
          const SizedBox(height: 8),
          // Subcategories section
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, _) {
              final subcategories =
                  categoryProvider.getSubcategoriesByCategory(category.id);

              if (subcategories.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      final subcat = subcategories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              subcat.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
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
          builder: (_) => ProductDetailScreen(
            productId: product.id,
            initialProduct: product,
          ),
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

class _SubcategoryProductSection extends StatelessWidget {
  final int subcategoryId;
  final String subcategoryName;
  final List<Product> products;

  const _SubcategoryProductSection({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            subcategoryName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _ProductGridCard(product: products[index]);
          },
        ),
      ],
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
          builder: (_) => ProductDetailScreen(
            productId: product.id,
            initialProduct: product,
          ),
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
