import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../models/product_model.dart';
import '../services/prediction_service.dart';

class PredictionProvider extends ChangeNotifier {
  PredictionProvider() {
    _service = PredictionService();
  }

  late final PredictionService _service;

  List<PredictionModel> _predictions = [];
  bool _isLoading = false;
  bool _serverReachable = false;
  String? _errorMessage;

  List<PredictionModel> get predictions => _predictions;
  bool get isLoading => _isLoading;
  bool get serverReachable => _serverReachable;
  String? get errorMessage => _errorMessage;

  /// Checks if the ML server is online and loads predictions for products.
  Future<void> loadPredictions(
    List<ProductModel> products,
    List<Map<String, dynamic>> salesHistory,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _serverReachable = await _service.isServerReachable();

    if (!_serverReachable) {
      _isLoading = false;
      _errorMessage =
          'The prediction server is offline.\n\nTo enable AI predictions:\n'
          '1. Start the ML server: uvicorn app.main:app --reload\n'
          '2. Make sure your device can reach the server.';
      notifyListeners();
      return;
    }

    final results = <PredictionModel>[];
    for (final product in products.take(20)) {
      final result = await _service.predictDemand(
        product: product,
        salesHistory: salesHistory,
      );
      if (result.isSuccess) {
        results.add(result.prediction!);
      }
    }

    _predictions = results;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
