import 'package:appsmarketplace/core/services/dio_client.dart';
import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  String? _error;

  // GETTERS
  ProductStatus get status => _status;
  List<ProductModel> get products => _filteredProducts;
  String? get error => _error;

  bool get isLoading => _status == ProductStatus.loading;
  bool get isLoaded => _status == ProductStatus.loaded;
  bool get hasError => _status == ProductStatus.error;

  // ================= FETCH =================
  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient.instance.get('/products');

      final List data = response.data['data'];

      _allProducts = data.map((json) => ProductModel.fromJson(json)).toList();

      _filteredProducts = List.from(_allProducts);

      _status = ProductStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = ProductStatus.error;
    }

    notifyListeners();
  }

  // ================= SEARCH =================
  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    notifyListeners();
  }

  // ================= REFRESH =================
  Future<void> refreshProducts() async {
    await fetchProducts();
  }

  // ================= CLEAR ERROR =================
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
