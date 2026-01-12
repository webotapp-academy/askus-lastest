import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'banner_model.dart';

class BannerProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<Banner> _homeTopBanners = [];
  List<Banner> _homeMiddleBanners = [];
  List<Banner> _allBanners = [];
  bool _isLoading = false;
  String? _error;

  List<Banner> get homeTopBanners => _homeTopBanners;
  List<Banner> get homeMiddleBanners => _homeMiddleBanners;
  List<Banner> get allBanners => _allBanners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBanners() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.banners);

      if (response.success && response.data != null) {
        final List<dynamic> allData = response.data!['all_banners'] ?? [];
        _allBanners = allData.map((json) => Banner.fromJson(json)).toList();
        
        _homeTopBanners = _allBanners.where((b) => b.position == 'home_top').toList();
        _homeMiddleBanners = _allBanners.where((b) => b.position == 'home_middle').toList();
      } else {
        _error = response.message ?? 'Failed to load banners';
      }
    } catch (e) {
      _error = 'Failed to load banners: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
