import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';

class CartProvider extends ChangeNotifier {
  List items = [];
  double totalPrice = 0;
  bool isLoading = false;

  Future<void> fetchCart() async {
    isLoading = true;
    notifyListeners();

    final res = await DioClient.instance.get('/cart');

    items = res.data['data']['items'] ?? [];
    totalPrice = (res.data['data']['total_price'] as num?)?.toDouble() ?? 0;

    isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(int productId, {String? size}) async {
    await DioClient.instance.post(
      '/cart',
      data: {"product_id": productId, "quantity": 1, "size": size ?? "M"},
    );

    await fetchCart(); // 🔥 refresh
  }

  Future<void> updateQty(int id, int qty) async {
    if (qty <= 0) return;

    await DioClient.instance.put('/cart/$id', data: {"quantity": qty});

    await fetchCart();
  }

  Future<void> removeItem(int id) async {
    await DioClient.instance.delete('/cart/$id');
    await fetchCart();
  }

  Future<void> updateItem(int id, int qty, String? size) async {
    await DioClient.instance.put(
      '/cart/$id',
      data: {"quantity": qty, "size": size},
    );

    await fetchCart();
  }

  Future<void> checkout() async {
    await DioClient.instance.post(
      '/orders/checkout',
      data: {"shipping_address": "Jl. Default", "notes": "-"},
    );

    items = [];
    totalPrice = 0;

    notifyListeners();
  }

  Future<Map<String, dynamic>> processCheckout({
    required String shippingAddress,
    required String notes,
    required String paymentMethod,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await DioClient.instance.post(
        '/orders/checkout',
        data: {
          "shipping_address": shippingAddress,
          "notes": notes,
          "payment_method": paymentMethod,
        },
      );

      items = [];
      totalPrice = 0;
      isLoading = false;
      notifyListeners();

      return res.data['data'] as Map<String, dynamic>;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
