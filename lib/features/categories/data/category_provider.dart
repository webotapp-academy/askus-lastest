import 'package:flutter/foundation.dart' as flutter;
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'category_model.dart';

class CategoryProvider extends flutter.ChangeNotifier {
  final _api = ApiClient();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  List<Category> get parentCategories {
    final parents = _categories
        .where((c) => c.parentId == null || c.parentId == 0)
        .toList();
    if (parents.isEmpty && _categories.isNotEmpty) {
      return _categories;
    }
    return parents;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Category> getSubcategories(int parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  Future<void> fetchCategories() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 CategoryProvider: Fetching categories...');
      final response = await _api.get(ApiConstants.categories);

      print('📥 CategoryProvider: Response success=${response.success}');

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data!['categories'] ?? [];
        print('📦 CategoryProvider: Received ${data.length} categories');

        if (data.isNotEmpty) {
          print('📋 CategoryProvider: First item: ${data.first}');
        }

        _categories = data.map((json) => Category.fromJson(json)).toList();
        print('✅ CategoryProvider: Parsed ${_categories.length} categories');

        final parents = parentCategories;
        print('👪 CategoryProvider: ${parents.length} parent categories');
      } else {
        _error = response.message ?? 'Failed to load categories';
        print('❌ CategoryProvider: Error - $_error');
      }
    } catch (e) {
      _error = 'Failed to load categories: $e';
      print('❌ CategoryProvider: Exception - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
