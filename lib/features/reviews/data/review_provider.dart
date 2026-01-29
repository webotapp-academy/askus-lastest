import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;

  List<Review> get reviews => _reviews;
  ReviewStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchReviews({
    required String type, // 'product', 'vendor'
    required int itemId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _reviews = [];
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(
        ApiConstants.reviewsList,
        params: {
          'type': type,
          'item_id': itemId.toString(),
          'page': _currentPage.toString(),
          'limit': '10',
        },
      );

      if (response.success && response.data != null) {
        final List<dynamic> reviewsData = response.data!['reviews'] ?? [];
        final newReviews = reviewsData.map((e) => Review.fromJson(e)).toList();

        if (refresh) {
          _reviews = newReviews;
        } else {
          _reviews.addAll(newReviews);
        }

        _hasMore = newReviews.length >= 10;
        _currentPage++;

        // Parse stats if available
        if (response.data!['stats'] != null) {
          _stats = ReviewStats.fromJson(response.data!['stats']);
        }
      } else {
        _error = response.message ?? 'Failed to load reviews';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching reviews: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitReview({
    required String type,
    required int itemId,
    required int vendorId,
    required int rating,
    String? title,
    String? comment,
    int? orderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📝 Submitting review...');
      debugPrint(
          'Type: $type, Item ID: $itemId, Vendor ID: $vendorId, Rating: $rating');

      final body = {
        'review_type': type,
        'rating': rating,
        'vendor_id': vendorId,
        if (type == 'product') 'product_id': itemId,
        if (title != null && title.isNotEmpty) 'title': title,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (orderId != null) 'order_id': orderId,
      };

      debugPrint('Request body: $body');

      final response = await _api.post(ApiConstants.reviewsCreate, body);

      debugPrint('Response: ${response.success}, ${response.message}');

      if (response.success) {
        // Add the new review to the list
        if (response.data != null && response.data!['review'] != null) {
          final newReview = Review.fromJson(response.data!['review']);
          _reviews.insert(0, newReview);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to submit review';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error submitting review: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteReview(int reviewId) async {
    try {
      final response = await _api.post(ApiConstants.reviewsDelete, {
        'review_id': reviewId,
      });

      if (response.success) {
        _reviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
    return false;
  }

  void clearReviews() {
    _reviews = [];
    _stats = null;
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }
}
