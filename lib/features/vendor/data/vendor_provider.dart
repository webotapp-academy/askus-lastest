import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'vendor_model.dart';

class VendorProvider extends ChangeNotifier {
  final _api = ApiClient();

  Vendor? _vendor;
  VendorStats _stats = VendorStats();
  List<VendorDocument> _documents = [];
  bool _isLoading = false;
  String? _error;

  Vendor? get vendor => _vendor;
  VendorStats get stats => _stats;
  List<VendorDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVendorProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.get(ApiConstants.vendorProfile);

    if (response.success && response.data != null) {
      final vendorData =
          response.data!['vendor'] ?? response.data!['data'] ?? response.data;
      if (vendorData != null) {
        _vendor = Vendor.fromJson(vendorData);
      }
    } else {
      _error = response.message ?? 'Failed to load vendor profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVendorStats() async {
    final response = await _api.get(ApiConstants.vendorStats);

    if (response.success && response.data != null) {
      final statsData =
          response.data!['stats'] ?? response.data!['data'] ?? response.data;
      if (statsData != null) {
        _stats = VendorStats.fromJson(statsData);
        notifyListeners();
      }
    }
  }

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.vendorDashboard);

    if (response.success && response.data != null) {
      // Parse vendor data
      final vendorData = response.data!['vendor'];
      if (vendorData != null) {
        _vendor = Vendor.fromJson(vendorData);
      }

      // Parse stats data
      final statsData = response.data!['stats'];
      if (statsData != null) {
        _stats = VendorStats.fromJson(statsData);
      }
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.post(ApiConstants.vendorUpdateProfile, data);

    if (response.success && response.data != null) {
      final vendorData = response.data!['vendor'] ?? response.data!['data'];
      if (vendorData != null) {
        _vendor = Vendor.fromJson(vendorData);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = response.message ?? 'Failed to update profile';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateStoreLogo(File image) async {
    final response = await _api.postMultipart(
      ApiConstants.vendorUpdateProfile,
      {},
      [image],
      'store_logo',
    );

    if (response.success) {
      await fetchVendorProfile();
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> updateStoreBanner(File image) async {
    final response = await _api.postMultipart(
      ApiConstants.vendorUpdateProfile,
      {},
      [image],
      'store_banner',
    );

    if (response.success) {
      await fetchVendorProfile();
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> toggleStoreStatus(bool isOpen) async {
    final response = await _api.post(ApiConstants.vendorUpdateProfile, {
      'is_open': isOpen ? 1 : 0,
    });

    if (response.success) {
      if (_vendor != null) {
        _vendor = Vendor.fromJson({
          ..._vendor!.toJson(),
          'is_open': isOpen,
        });
        notifyListeners();
      }
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> submitKyc({
    String? gstNumber,
    String? panNumber,
    String? fssaiNumber,
    File? gstDocument,
    File? panDocument,
    File? fssaiDocument,
  }) async {
    final fields = <String, String>{};
    final files = <File>[];

    if (gstNumber != null) fields['gst_number'] = gstNumber;
    if (panNumber != null) fields['pan_number'] = panNumber;
    if (fssaiNumber != null) fields['fssai_number'] = fssaiNumber;

    if (gstDocument != null) files.add(gstDocument);
    if (panDocument != null) files.add(panDocument);
    if (fssaiDocument != null) files.add(fssaiDocument);

    final response = await _api.postMultipart(
      ApiConstants.vendorKyc,
      fields,
      files,
      'documents[]',
    );

    if (response.success) {
      await fetchVendorProfile();
      return true;
    }

    _error = response.message;
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Document/KYC methods
  Future<void> fetchDocuments() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.vendorDocuments);

    if (response.success && response.data != null) {
      final List<dynamic> docsData = response.data!['documents'] ?? [];
      _documents = docsData.map((d) => VendorDocument.fromJson(d)).toList();
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> uploadDocument({
    required String documentType,
    required String documentNumber,
    required File file,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.postMultipart(
      ApiConstants.vendorUploadDocument,
      {
        'document_type': documentType,
        'document_number': documentNumber,
      },
      [file],
      'document',
    );

    _isLoading = false;

    if (response.success) {
      await fetchDocuments();
      notifyListeners();
      return true;
    }

    _error = response.message ?? 'Failed to upload document';
    notifyListeners();
    return false;
  }
}
