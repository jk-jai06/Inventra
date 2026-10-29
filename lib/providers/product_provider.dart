import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

/// Manages product catalog and inventory state.
/// Reactively listens to Firestore stream when authenticated.
class ProductProvider extends ChangeNotifier {
  ProductProvider(this._authProvider) {
    _service = ProductService();
    _setupAuthListener();
  }

  final AuthProvider _authProvider;
  late final ProductService _service;
  StreamSubscription<List<ProductModel>>? _sub;

  List<ProductModel> _products = [];
  List<ProductModel> _lowStockProducts = [];
  List<ProductModel> _outOfStockProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<ProductModel> get lowStockProducts => _lowStockProducts;
  List<ProductModel> get outOfStockProducts => _outOfStockProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setupAuthListener() {
    _authProvider.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      startListening();
    } else {
      stopListening();
      _clearData();
    }
  }

  /// Starts listening to the Firestore products stream in real-time.
  void startListening({bool force = false}) {
    if (_sub != null && !force) return;

    _sub?.cancel();
    _isLoading = _products.isEmpty;
    notifyListeners();

    try {
      _sub = _service.productsStream().listen(
        (list) {
          _products = list;
          _lowStockProducts = list.where((p) => p.isLowStock && !p.isOutOfStock).toList();
          _outOfStockProducts = list.where((p) => p.isOutOfStock).toList();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to load products: $e';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to connect product service: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  void _clearData() {
    _products = [];
    _lowStockProducts = [];
    _outOfStockProducts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      _errorMessage = null;
      await _service.addProduct(product, shopId: _authProvider.shopId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add product: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      _errorMessage = null;
      await _service.updateProduct(product);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update product: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _errorMessage = null;
      await _service.deleteProduct(productId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete product: $e';
      notifyListeners();
      return false;
    }
  }

  /// Adjusts stock atomically. Returns error message or null on success.
  Future<String?> adjustStock(
    String productId,
    int delta, {
    String movementType = 'adjustment',
    String? referenceId,
    String notes = '',
  }) async {
    try {
      final error = await _service.adjustStock(
        productId,
        delta,
        movementType: movementType,
        referenceId: referenceId,
        notes: notes,
      );
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
      }
      return error;
    } catch (e) {
      final msg = 'Failed to adjust stock: $e';
      _errorMessage = msg;
      notifyListeners();
      return msg;
    }
  }

  /// Stream of stock movements for a specific product.
  Stream<List<StockMovementModel>> productMovementsStream(String productId) {
    return _service.stockMovementsStream(productId);
  }

  /// Gets recent stock movements across products.
  Future<List<StockMovementModel>> getRecentMovements({int limit = 30}) {
    return _service.getRecentMovements(limit: limit);
  }

  Future<List<String>> getCategories() => _service.getCategories();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
