import 'dart:async';
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import 'auth_provider.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._authProvider) {
    _service = AnalyticsService();
    _setupAuthListener();
  }

  final AuthProvider _authProvider;
  late final AnalyticsService _service;
  StreamSubscription<DashboardSummary>? _sub;

  DashboardSummary _summary = const DashboardSummary();
  List<DailySalesSummary> _dailySales = [];
  List<ProductSalesSummary> _topProducts = [];

  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary get summary => _summary;
  List<DailySalesSummary> get dailySales => _dailySales;
  List<ProductSalesSummary> get topProducts => _topProducts;
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
    _isLoading = true;
    notifyListeners();

    try {
      _sub = _service.summaryStream().listen(
        (data) {
          _summary = data;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to stream analytics: $e';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to connect analytics service: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  void _clearData() {
    _summary = const DashboardSummary();
    _dailySales = [];
    _topProducts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getDailySales(),
        _service.getTopProducts(),
      ]);

      _dailySales = results[0] as List<DailySalesSummary>;
      _topProducts = results[1] as List<ProductSalesSummary>;
    } catch (e) {
      _errorMessage = 'Failed to load analytics details: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
