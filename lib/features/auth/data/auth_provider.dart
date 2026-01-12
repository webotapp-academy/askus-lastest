import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _api = ApiClient();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isVendor => _user?.role == 'vendor';
  bool get isUser => _user?.role == 'user';

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final token = await _api.token;
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final response = await _api.get(ApiConstants.profile);
    if (response.success && response.data != null) {
      _user = User.fromJson(response.data!['user']);
      _status = AuthStatus.authenticated;
    } else {
      await _api.clearToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    debugPrint('🔐 Starting login process...');
    debugPrint('🆔 Identifier: $identifier');

    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    // Determine if identifier is email or phone
    bool isEmail = identifier.contains('@');
    
    final response = await _api.post(ApiConstants.login, {
      if (isEmail) 'email': identifier else 'phone': identifier,
      'password': password,
    });

    debugPrint('📨 Login API Response received');
    debugPrint('✅ Success: ${response.success}');
    debugPrint('💬 Message: ${response.message}');
    debugPrint('📊 Status Code: ${response.statusCode}');

    if (response.success && response.data != null) {
      try {
        debugPrint('🎯 Processing successful login response...');

        // Handle different token field names
        String? token = response.data!['token']?.toString() ??
            response.data!['access_token']?.toString() ??
            response.data!['auth_token']?.toString();

        debugPrint('🔑 Token found: ${token != null ? 'Yes' : 'No'}');
        if (token != null) {
          debugPrint('💾 Saving token to secure storage...');
          await _api.setToken(token);
        }

        // Handle different user data structures
        Map<String, dynamic> userData =
            response.data!['user'] as Map<String, dynamic>? ??
                response.data!['data'] as Map<String, dynamic>? ??
                response.data!;

        debugPrint('👤 User data found: $userData');
        _user = User.fromJson(userData);
        debugPrint('✅ User object created: ${_user?.name} (${_user?.email})');

        _status = AuthStatus.authenticated;
        notifyListeners();
        debugPrint('🎉 Login successful!');
        return true;
      } catch (e) {
        debugPrint('❌ Error processing login response: $e');
        _error = 'Failed to process login response: $e';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } else {
      debugPrint('❌ Login failed - API returned error');
      _error = response.message ?? 'Login failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    debugPrint('📝 Starting registration process...');
    debugPrint('👤 Name: $name');
    debugPrint('📧 Email: $email');
    debugPrint('📱 Phone: $phone');
    debugPrint('🎭 Role: $role');

    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final response = await _api.post(ApiConstants.register, {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });

    debugPrint('📨 Registration API Response received');
    debugPrint('✅ Success: ${response.success}');
    debugPrint('💬 Message: ${response.message}');
    debugPrint('📊 Status Code: ${response.statusCode}');

    if (response.success && response.data != null) {
      try {
        debugPrint('🎯 Processing successful registration response...');

        // Handle different token field names
        String? token = response.data!['token']?.toString() ??
            response.data!['access_token']?.toString() ??
            response.data!['auth_token']?.toString();

        debugPrint('🔑 Token found: ${token != null ? 'Yes' : 'No'}');
        if (token != null) {
          debugPrint('💾 Saving token to secure storage...');
          await _api.setToken(token);
        }

        // Handle different user data structures
        Map<String, dynamic> userData =
            response.data!['user'] as Map<String, dynamic>? ??
                response.data!['data'] as Map<String, dynamic>? ??
                response.data!;

        debugPrint('👤 User data found: $userData');
        _user = User.fromJson(userData);
        debugPrint('✅ User object created: ${_user?.name} (${_user?.email})');

        _status = AuthStatus.authenticated;
        notifyListeners();
        debugPrint('🎉 Registration successful!');
        return true;
      } catch (e) {
        debugPrint('❌ Error processing registration response: $e');
        _error = 'Failed to process registration response: $e';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } else {
      debugPrint('❌ Registration failed - API returned error');
      _error = response.message ?? 'Registration failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerVendor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String storeName,
    required String storeAddress,
    required String city,
    required String state,
    required String pincode,
    String? gstNumber,
    String? panNumber,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    debugPrint('🏪 Starting vendor registration validation...');
    debugPrint('👤 Owner: $name, Store: $storeName');
    debugPrint('📧 Email: $email, Phone: $phone');

    final response = await _api.post(ApiConstants.vendorRegister, {
      'owner_name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'store_name': storeName,
      'address': storeAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      if (gstNumber != null && gstNumber.isNotEmpty) 'gst_number': gstNumber,
      if (panNumber != null && panNumber.isNotEmpty) 'pan_number': panNumber,
    });

    debugPrint(
        '📨 Vendor Reg Response - Success: ${response.success}, Code: ${response.statusCode}');
    debugPrint('💬 Message: ${response.message}');
    if (response.data != null) debugPrint('📦 Data: ${response.data}');

    if (response.success) {
      debugPrint('✅ Vendor registration data validated successfully');
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Vendor registration validation failed';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Creates vendor in database AFTER successful payment verification
  Future<bool> createVendorAfterPayment({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String storeName,
    required String storeAddress,
    required String city,
    required String state,
    required String pincode,
    required String paymentId,
    String? gstNumber,
    String? panNumber,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    debugPrint('🏪 Creating vendor in database after payment verification...');
    debugPrint('💳 Payment ID: $paymentId');
    debugPrint('👤 Owner: $name, Store: $storeName');

    final response = await _api.post('/auth/create-vendor-after-payment.php', {
      'owner_name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'store_name': storeName,
      'address': storeAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'payment_id': paymentId,
      if (gstNumber != null && gstNumber.isNotEmpty) 'gst_number': gstNumber,
      if (panNumber != null && panNumber.isNotEmpty) 'pan_number': panNumber,
    });

    debugPrint(
        '📨 Create Vendor Response - Success: ${response.success}, Code: ${response.statusCode}');
    debugPrint('💬 Message: ${response.message}');

    if (response.success && response.data != null) {
      try {
        // Handle different token field names
        String? token = response.data!['token']?.toString() ??
            response.data!['access_token']?.toString() ??
            response.data!['auth_token']?.toString();

        if (token != null) {
          await _api.setToken(token);
        }

        // Handle different user data structures
        Map<String, dynamic> userData =
            response.data!['user'] as Map<String, dynamic>? ??
                response.data!['data'] as Map<String, dynamic>? ??
                response.data!;

        _user = User.fromJson(userData);

        _status = AuthStatus.authenticated;
        notifyListeners();
        debugPrint('✅ Vendor created successfully after payment!');
        return true;
      } catch (e) {
        _error = 'Failed to process vendor creation response: $e';
        _status = AuthStatus.error;
        notifyListeners();
        debugPrint('❌ Error processing response: $e');
        return false;
      }
    } else {
      _error = response.message ?? 'Failed to create vendor';
      _status = AuthStatus.error;
      notifyListeners();
      debugPrint('❌ Vendor creation failed: ${response.message}');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.updateProfile, data);
    if (response.success && response.data != null) {
      _user = User.fromJson(response.data!['user']);
      notifyListeners();
      return true;
    }
    _error = response.message;
    return false;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
