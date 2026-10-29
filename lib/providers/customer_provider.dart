import 'dart:async';
import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import 'auth_provider.dart';

/// Manages customer master data and listens to real-time updates from Firestore.
class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._authProvider) {
    _service = CustomerService();
    _setupAuthListener();
  }

  final AuthProvider _authProvider;
  late final CustomerService _service;
  StreamSubscription<List<CustomerModel>>? _sub;

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get customers => _customers;
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

  void startListening({bool force = false}) {
    if (_sub != null && !force) return;

    _sub?.cancel();
    _isLoading = _customers.isEmpty;
    notifyListeners();

    try {
      _sub = _service.customersStream().listen(
        (list) {
          _customers = list;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to load customers: $e';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to connect customer service: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  void _clearData() {
    _customers = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    try {
      _errorMessage = null;
      await _service.addCustomer(customer, shopId: _authProvider.shopId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    try {
      _errorMessage = null;
      await _service.updateCustomer(customer);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      _errorMessage = null;
      await _service.deleteCustomer(customerId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete customer: $e';
      notifyListeners();
      return false;
    }
  }

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
