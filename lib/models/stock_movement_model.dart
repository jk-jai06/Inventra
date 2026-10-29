import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a stock movement/adjustment for a product.
///
/// Tracks inventory changes:
/// - purchase (stock in from supplier)
/// - sale (stock out from invoice)
/// - adjustment (manual correction)
/// - return (customer return)
/// - wastage / damage
class StockMovementModel {
  const StockMovementModel({
    required this.movementId,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    this.referenceId, // e.g., invoice number or adjustment note
    this.shopId,
    required this.timestamp,
    this.notes = '',
  });

  final String movementId;
  final String productId;
  final String productName;
  final String movementType; // 'purchase', 'sale', 'adjustment', 'return', 'wastage'
  final int quantityChange; // positive or negative
  final int previousQuantity;
  final int newQuantity;
  final String? referenceId;
  final String? shopId;
  final DateTime timestamp;
  final String notes;

  factory StockMovementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StockMovementModel(
      movementId: doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? 'Product',
      movementType: data['movementType'] as String? ?? 'adjustment',
      quantityChange: (data['quantityChange'] as num?)?.toInt() ?? 0,
      previousQuantity: (data['previousQuantity'] as num?)?.toInt() ?? 0,
      newQuantity: (data['newQuantity'] as num?)?.toInt() ?? 0,
      referenceId: data['referenceId'] as String?,
      shopId: data['shop_id'] as String? ?? data['shopId'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productId': productId,
        'productName': productName,
        'movementType': movementType,
        'quantityChange': quantityChange,
        'previousQuantity': previousQuantity,
        'newQuantity': newQuantity,
        'referenceId': referenceId,
        'shop_id': shopId,
        'shopId': shopId,
        'timestamp': Timestamp.fromDate(timestamp),
        'notes': notes,
      };

  StockMovementModel copyWith({
    String? movementId,
    String? productId,
    String? productName,
    String? movementType,
    int? quantityChange,
    int? previousQuantity,
    int? newQuantity,
    String? referenceId,
    String? shopId,
    DateTime? timestamp,
    String? notes,
  }) {
    return StockMovementModel(
      movementId: movementId ?? this.movementId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      movementType: movementType ?? this.movementType,
      quantityChange: quantityChange ?? this.quantityChange,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      referenceId: referenceId ?? this.referenceId,
      shopId: shopId ?? this.shopId,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}
