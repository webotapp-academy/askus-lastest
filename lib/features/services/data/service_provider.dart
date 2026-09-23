import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'service_model.dart';

class ServiceProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<Service> _services = [];
  List<Service> _vendorServices = [];
  Service? _currentService;
  bool _isLoading = false;
  String? _error;

  List<Service> get services => _services;
  List<Service> get vendorServices => _vendorServices;
  Service? get currentService => _currentService;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices({int? categoryId, bool refresh = false}) async {
    // Avoid multiple concurrent requests
    if (_isLoading && !refresh) return;

    if (refresh) _services = [];

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = {
        if (categoryId != null) 'category_id': categoryId.toString(),
      };

      final response = await _api.get(ApiConstants.services, params: params);

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data!['services'] ?? response.data!['data'] ?? [];
        _services = data.map((json) => Service.fromJson(json)).toList();
        _error = null;
      } else {
        _error = response.message ?? 'Failed to fetch services';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setInitialService(Service service) {
    _currentService = service;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchServiceDetail(int id) async {
    if (_currentService == null || _currentService!.id != id) {
      final cached = _services.where((s) => s.id == id);
      if (cached.isNotEmpty) {
        _currentService = cached.first;
      }
    }

    _isLoading = _currentService == null;
    _error = null;
    notifyListeners();

    final response = await _api
        .get(ApiConstants.serviceDetail, params: {'id': id.toString()});

    if (response.success &&
        response.data != null &&
        response.data!['service'] != null) {
      _currentService = Service.fromJson(response.data!['service']);
      _error = null;
    } else {
      _error = response.message ?? 'Service not found';
      _currentService = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVendorServices() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.vendorServices);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['services'] ?? [];
      _vendorServices = data.map((json) => Service.fromJson(json)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createService({
    required String name,
    required String description,
    required int categoryId,
    required double price,
    String? duration,
    List<File>? images,
  }) async {
    final fields = {
      'name': name,
      'description': description,
      'category_id': categoryId.toString(),
      'price': price.toString(),
      if (duration != null) 'duration': duration,
    };

    final response = await _api.postMultipart(
      ApiConstants.serviceCreate,
      fields,
      images ?? [],
      'images[]',
    );

    if (response.success) {
      await fetchVendorServices();
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> deleteService(int id) async {
    final response = await _api.post(ApiConstants.serviceDelete, {'id': id});

    if (response.success) {
      _vendorServices.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    }

    _error = response.message;
    return false;
  }

  Future<bool> updateService(int id, Map<String, dynamic> data) async {
    final response =
        await _api.post('${ApiConstants.serviceUpdate}?id=$id', data);

    if (response.success) {
      await fetchVendorServices();
      return true;
    }

    _error = response.message;
    return false;
  }
}
