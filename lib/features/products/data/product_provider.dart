import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'product_model.dart';

class ProductProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<Product> _products = [];
  List<Product> _vendorProducts = [];
  Product? _currentProduct;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Product> get products => _products;
  List<Product> get vendorProducts => _vendorProducts;
  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchProducts(
      {int? categoryId, String? search, bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _products = [];
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = {
      'page': _currentPage.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (search != null) 'search': search,
    };

    print(
        '🔄 ProductProvider: Fetching products page=$_currentPage, categoryId=$categoryId');
    final response = await _api.get(ApiConstants.products, params: params);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['products'] ?? [];
      print('📦 ProductProvider: Received ${data.length} products');

      if (data.isNotEmpty) {
        final first = data.first;
        print(
            '📋 ProductProvider: First product: name=${first['name']}, thumbnail=${first['thumbnail']}, images=${first['images']}');
      }

      final newProducts = data.map((json) => Product.fromJson(json)).toList();
      _products.addAll(newProducts);
      _hasMore = newProducts.length >= 20;
      _currentPage++;

      print('✅ ProductProvider: Total ${_products.length} products loaded');
    } else {
      _error = response.message ?? 'Failed to load products';
      print('❌ ProductProvider: Error - $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProductDetail(int id) async {
    _isLoading = true;
    notifyListeners();

    print('🔄 ProductProvider: Fetching product detail id=$id');
    final response = await _api
        .get(ApiConstants.productDetail, params: {'id': id.toString()});

    if (response.success && response.data != null) {
      final productData = response.data!['product'];
      print(
          '📋 ProductProvider: Product detail: thumbnail=${productData['thumbnail']}, images=${productData['images']}');
      _currentProduct = Product.fromJson(productData);
      print('✅ ProductProvider: Loaded ${_currentProduct?.name}');
    } else {
      print('❌ ProductProvider: Error - ${response.message}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVendorProducts() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.vendorProducts);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['products'] ?? [];
      _vendorProducts = data.map((json) => Product.fromJson(json)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProduct({
    required String name,
    required String description,
    required int categoryId,
    required double price,
    double? comparePrice,
    int stock = 0,
    String? sku,
    List<File>? images,
  }) async {
    final fields = {
      'name': name,
      'description': description,
      'category_id': categoryId.toString(),
      'price': price.toString(),
      if (comparePrice != null) 'compare_price': comparePrice.toString(),
      'stock': stock.toString(),
      if (sku != null) 'sku': sku,
    };

    final response = await _api.postMultipart(
      ApiConstants.productCreate,
      fields,
      images ?? [],
      'images[]',
    );

    if (response.success) {
      await fetchVendorProducts();
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    final response =
        await _api.post('${ApiConstants.productUpdate}?id=$id', data);

    if (response.success) {
      await fetchVendorProducts();
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    final response = await _api.post(ApiConstants.productDelete, {'id': id});

    if (response.success) {
      _vendorProducts.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    }

    _error = response.message;
    return false;
  }
}
