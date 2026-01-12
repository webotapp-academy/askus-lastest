import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'enquiry_model.dart';

class EnquiryProvider extends ChangeNotifier {
  final _api = ApiClient();
  
  List<Enquiry> _enquiries = [];
  Enquiry? _currentEnquiry;
  bool _isLoading = false;
  String? _error;

  List<Enquiry> get enquiries => _enquiries;
  Enquiry? get currentEnquiry => _currentEnquiry;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEnquiries() async {
    // Avoid multiple concurrent requests
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.enquiryList);
    
    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['enquiries'] ?? [];
      _enquiries = data.map((json) => Enquiry.fromJson(json)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchEnquiryDetail(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.enquiryDetail, params: {'id': id.toString()});
    
    if (response.success && response.data != null) {
      _currentEnquiry = Enquiry.fromJson(response.data!['enquiry']);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEnquiry({
    required String type,
    required int itemId,
    required int vendorId,
    required String message,
    String? preferredDate,
    String? preferredTime,
  }) async {
    final response = await _api.post(ApiConstants.enquiryCreate, {
      'type': type,
      'item_id': itemId,
      'vendor_id': vendorId,
      'message': message,
      if (preferredDate != null) 'preferred_date': preferredDate,
      if (preferredTime != null) 'preferred_time': preferredTime,
    });

    if (response.success) {
      await fetchEnquiries();
      return true;
    }
    
    _error = response.message;
    return false;
  }

  Future<bool> respondToEnquiry(int id, String response, String status) async {
    final apiResponse = await _api.post(ApiConstants.enquiryRespond, {
      'id': id,
      'response': response,
      'status': status,
    });

    if (apiResponse.success) {
      await fetchEnquiries();
      return true;
    }
    
    _error = apiResponse.message;
    return false;
  }
}
