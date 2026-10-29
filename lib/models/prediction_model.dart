/// Prediction result returned by the ML API for a single product.
class PredictionModel {
  const PredictionModel({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.predictedDemand,
    required this.forecastDays,
    required this.reorderQty,
    required this.recommendation,
    required this.confidence,
    required this.generatedAt,
  });

  final String productId;
  final String productName;
  final int currentStock;
  final double predictedDemand; // Units expected to sell in forecastDays
  final int forecastDays;
  final int reorderQty; // Suggested reorder quantity
  final String recommendation;
  final double confidence; // 0.0 – 1.0
  final DateTime generatedAt;

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      predictedDemand: (json['predicted_demand'] as num?)?.toDouble() ?? 0.0,
      forecastDays: (json['forecast_days'] as num?)?.toInt() ?? 7,
      reorderQty: (json['reorder_qty'] as num?)?.toInt() ?? 0,
      recommendation: json['recommendation'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'current_stock': currentStock,
        'predicted_demand': predictedDemand,
        'forecast_days': forecastDays,
        'reorder_qty': reorderQty,
        'recommendation': recommendation,
        'confidence': confidence,
        'generated_at': generatedAt.toIso8601String(),
      };

  bool get needsReorder => currentStock < predictedDemand;
}
