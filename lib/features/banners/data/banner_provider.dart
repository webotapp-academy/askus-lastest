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
      debugPrint('🚩 Fetching banners from: ${ApiConstants.banners}');
      final response = await _api.get(ApiConstants.banners);

      if (response.success && response.data != null) {
        final List<dynamic> allData = response.data!['all_banners'] ?? [];
        debugPrint('✅ Raw data received: ${allData.length} items');
        if (allData.isNotEmpty) {
          debugPrint('📝 First item raw: ${allData.first}');
        }
        
        _allBanners = allData.map((json) => Banner.fromJson(json)).toList();
        
        _homeTopBanners = _allBanners.where((b) => b.position == 'home_top').toList();
        _homeMiddleBanners = _allBanners.where((b) => b.position == 'home_middle').toList();
        
        debugPrint('📱 Parsed Home Top Banners: ${_homeTopBanners.length}');
        for (var b in _homeTopBanners) {
          debugPrint('   - ${b.title}: ${b.image}');
        }
      } else {
        _error = response.message ?? 'Failed to load banners';
        debugPrint('❌ Banner API Error: $_error');
      }
    } catch (e) {
      _error = 'Failed to load banners: $e';
      debugPrint('🚨 Banner Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
