import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/data/auth_provider.dart';
import 'subscription_plan_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _api = ApiClient();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = false;
  String? _error;
  final AuthProvider _authProvider;

  SubscriptionProvider(this._authProvider);

  List<SubscriptionPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPlans({String? targetGroup}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = targetGroup != null ? {'target_group': targetGroup} : null;
      final response =
          await _api.get(ApiConstants.subscriptionPlans, params: params);

      debugPrint('📦 Subscription Plans Raw Data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        if (data != null && data is List) {
          _plans = data
              .map((json) => SubscriptionPlan.fromJson(json))
              .toList();
        } else if (response.data! is List) {
          // If the entire data is a list
          _plans = (response.data! as List)
              .map((json) => SubscriptionPlan.fromJson(json))
              .toList();
        }
      }
 else {
        _error = response.message ?? 'Failed to load plans map';
      }
    } catch (e) {
      _error = 'Error loading subscription plans: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createSubscriptionOrder(int planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiConstants.subscriptionCreateOrder,
        {'plan_id': planId},
      );

      if (response.success && response.data != null) {
        _isLoading = false;
        notifyListeners();
        return response.data;
      } else {
        _error = response.message ?? 'Failed to create order';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Order Error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> purchasePlan(
      int planId, String paymentId, String orderId, String signature) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiConstants.subscriptionPurchase,
        {
          'plan_id': planId,
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        },
      );

      if (response.success) {
        _isLoading = false;
        notifyListeners();

        // Refresh auth profile to grab the new currentPlanId & limits
        await _authProvider.checkAuthStatus();

        return true;
      }
 else {
        _error = response.message ?? 'Failed to activate plan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Transaction Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
