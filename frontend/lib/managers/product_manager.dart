import 'package:flutter/foundation.dart';
import 'package:hyphen/data/mock_products.dart';
import 'package:hyphen/services/api_client.dart';
import 'package:dio/dio.dart' as dio;

class ProductManager extends ChangeNotifier {
  // Singleton instance
  static final ProductManager _instance = ProductManager._internal();
  factory ProductManager() => _instance;

  final List<Product> _products = [];
  final List<Product> _myProducts = [];
  DateTime? _lastFetchProductsTime;
  DateTime? _lastFetchMyProductsTime;

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get myProducts => List.unmodifiable(_myProducts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProductManager._internal();

  Future<void> fetchProducts({bool force = false}) async {
    if (!force && _products.isNotEmpty && _lastFetchProductsTime != null) {
      final diff = DateTime.now().difference(_lastFetchProductsTime!);
      if (diff < const Duration(seconds: 30)) {
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get('/product/products');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        _products.clear();
        _products.addAll(data.map((json) => Product.fromJson(json)).toList());
        _lastFetchProductsTime = DateTime.now();
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (_products.isEmpty) {
        _products.addAll(mockProducts);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyProducts({bool force = false}) async {
    if (!force && _myProducts.isNotEmpty && _lastFetchMyProductsTime != null) {
      final diff = DateTime.now().difference(_lastFetchMyProductsTime!);
      if (diff < const Duration(seconds: 30)) {
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get('/product/myproducts');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        _myProducts.clear();
        _myProducts.addAll(data.map((json) => Product.fromJson(json)).toList());
        _lastFetchMyProductsTime = DateTime.now();
      }
    } catch (e) {
      print('Error fetching my products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String size,
    required String conditionLabel,
    required String imagePath,
    required String originCityId,
    required String originCityLabel,
    required String weight,
  }) async {
    try {
      // Map UI conditions to backend enum
      String backendCondition = 'good';
      if (conditionLabel == 'Sangat Baik') backendCondition = 'like_new';
      if (conditionLabel == 'Cukup Baik') backendCondition = 'fair';

      // Create MultipartFile and force a .jpg extension so the backend multer accepts the mimetype
      final file = await dio.MultipartFile.fromFile(imagePath, filename: 'upload.jpg');

      final formData = dio.FormData.fromMap({
        'name': name,
        'description': description,
        'price': price.toString(),
        'sizes': size, // e.g. "M"
        'category': category,
        'item_condition': backendCondition,
        'weight': weight,
        'originCityId': originCityId,
        'originCityLabel': originCityLabel,
        'image': file,
      });

      final response = await ApiClient().dio.post(
        '/product/create',
        data: formData,
      );

      if (response.statusCode == 201) {
        // Automatically refresh my products to show the new one
        await fetchMyProducts();
        return null; // Success
      }
      return 'Gagal upload produk';
    } on dio.DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response!.data['message']?.toString() ?? 'Gagal upload produk';
      }
      return 'Gagal terhubung ke server';
    } catch (e) {
      return 'Terjadi kesalahan: \$e';
    }
  }

  void addProduct(Product product) {
    _products.insert(0, product); // Insert new products at the top
    _myProducts.insert(0, product);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    int index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index >= 0) {
      _products[index] = updatedProduct;
    }
    int myIndex = _myProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (myIndex >= 0) {
      _myProducts[myIndex] = updatedProduct;
    }
    notifyListeners();
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _myProducts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void clearCache() {
    _products.clear();
    _myProducts.clear();
    _lastFetchProductsTime = null;
    _lastFetchMyProductsTime = null;
    notifyListeners();
  }

  Future<Product?> fetchProductDetail(String productId) async {
    try {
      final response = await ApiClient().dio.get('/product/products/$productId');
      if (response.statusCode == 200) {
        final productJson = response.data['data'];
        final updatedProduct = Product.fromJson(productJson);
        updateProduct(updatedProduct);
        return updatedProduct;
      }
    } catch (e) {
      print('Error fetching product detail: $e');
    }
    return null;
  }
}
