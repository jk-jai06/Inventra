import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';
import '../models/product_model.dart';

/// Centralized ML API configuration.
/// Change [activeEnvironment] to switch between dev/emulator/physical/production.
class ApiConfig {
  ApiConfig._();

  static const _androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const _physicalDeviceUrl = 'http://192.168.1.100:8000'; // update for your LAN IP
  static const _productionUrl = 'https://inventra-ml.example.com'; // update for hosted API

  /// Change this to switch environment.
  static const _activeEnv = _Env.androidEmulator;

  static String get baseUrl {
    switch (_activeEnv) {
      case _Env.androidEmulator:
        return _androidEmulatorUrl;
      case _Env.physicalDevice:
        return _physicalDeviceUrl;
      case _Env.production:
        return _productionUrl;
    }
  }

  static Duration get timeout => const Duration(seconds: 15);
}

enum _Env { androidEmulator, physicalDevice, production }

/// Calls the FastAPI ML engine for demand predictions.
/// Handles graceful offline/error fallback — never throws to the UI.
class PredictionService {
  PredictionService() : _client = http.Client();
  final http.Client _client;

  /// Requests a demand prediction for a single product.
  ///
  /// Returns [PredictionModel] on success, null if server is unreachable.
  /// Sets [errorMessage] with a human-readable explanation on failure.
  Future<PredictionResult> predictDemand({
    required ProductModel product,
    required List<Map<String, dynamic>> salesHistory,
    int forecastDays = 7,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/predict/inventory');
    final body = jsonEncode({
      'product_id': product.productId,
      'product_name': product.productName,
      'current_stock': product.stockQuantity,
      'selling_price': product.sellingPrice,
      'category': product.category,
      'sales_history': salesHistory,
      'forecast_days': forecastDays,
    });

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PredictionResult.success(PredictionModel.fromJson(json));
      } else {
        return PredictionResult.error(
          'Server returned ${response.statusCode}. Please try again.',
        );
      }
    } on http.ClientException {
      return PredictionResult.error(
        'Cannot reach prediction server. Make sure the ML server is running.',
      );
    } catch (_) {
      return PredictionResult.error(
        'Prediction service is currently unavailable.',
      );
    }
  }

  /// Checks whether the ML API server is reachable.
  Future<bool> isServerReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}

/// Result wrapper for prediction calls.
class PredictionResult {
  PredictionResult.success(this.prediction) : error = null;
  PredictionResult.error(this.error) : prediction = null;

  final PredictionModel? prediction;
  final String? error;

  bool get isSuccess => prediction != null;
}
