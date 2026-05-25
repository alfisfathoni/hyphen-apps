import 'package:flutter/foundation.dart';
import 'package:hyphen/services/api_client.dart';
import 'package:dio/dio.dart' as dio;

class CheckoutResult {
  final bool success;
  final String? message;
  final String? snapUrl;
  final String? snapToken;

  CheckoutResult({required this.success, this.message, this.snapUrl, this.snapToken});
}

class CheckoutManager extends ChangeNotifier {
  static final CheckoutManager _instance = CheckoutManager._internal();
  factory CheckoutManager() => _instance;
  CheckoutManager._internal();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Creates an order and proceeds to checkout to get the Midtrans snap URL
  Future<CheckoutResult> processSingleItemCheckout({
    required String productId,
    required String addressId,
    required String courierCode,
    required String service,
  }) async {
    _isLoading = true;
    notifyListeners();

    String? createdOrderId;

    try {
      // 1. Create the order
      final orderResponse = await ApiClient().dio.post('/order/create', data: {
        'productId': productId,
      });

      if (orderResponse.statusCode != 201) {
        return CheckoutResult(success: false, message: 'Failed to create order');
      }

      createdOrderId = orderResponse.data['data']['orderId'];

      // 2. Checkout to get Snap Token
      final checkoutResponse = await ApiClient().dio.post('/checkout/checkout', data: {
        'orderId': createdOrderId,
        'addressId': addressId,
        'courierCode': courierCode,
        'service': service,
      });

      if (checkoutResponse.statusCode == 201) {
        return CheckoutResult(
          success: true,
          snapUrl: checkoutResponse.data['snapUrl'],
          snapToken: checkoutResponse.data['snapToken'],
        );
      }

      // If we reach here, checkout failed. Revert/cancel order.
      if (createdOrderId != null) {
        try {
          await ApiClient().dio.post('/order/cancel/$createdOrderId');
        } catch (cancelError) {
          debugPrint('Error cancelling order after failed checkout: $cancelError');
        }
      }

      return CheckoutResult(
        success: false, 
        message: checkoutResponse.data['message'] ?? 'Checkout failed'
      );
    } on dio.DioException catch (e) {
      if (createdOrderId != null) {
        try {
          await ApiClient().dio.post('/order/cancel/$createdOrderId');
        } catch (cancelError) {
          debugPrint('Error cancelling order after exception: $cancelError');
        }
      }
      return CheckoutResult(
        success: false,
        message: e.response?.data['message'] ?? e.message,
      );
    } catch (e) {
      if (createdOrderId != null) {
        try {
          await ApiClient().dio.post('/order/cancel/$createdOrderId');
        } catch (cancelError) {
          debugPrint('Error cancelling order after exception: $cancelError');
        }
      }
      return CheckoutResult(success: false, message: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
