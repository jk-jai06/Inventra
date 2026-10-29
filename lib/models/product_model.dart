import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product in the inventory.
class ProductModel {
  const ProductModel({
    required this.productId,
    required this.productName,
    this.sku = '',
    required this.category,
    this.description = '',
    this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    this.gstPercentage = 0.0,
    this.stockQuantity = 0,
    this.minimumStockLevel = 5,
    this.unit = 'Units',
    this.supplierId,
    this.shopId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String productId;
  final String productName;
  final String sku;
  final String category;
  final String description;
  final String? barcode;
  final double purchasePrice;
  final double sellingPrice;
  final double gstPercentage;
  final int stockQuantity;
  final int minimumStockLevel;
  final String unit;
  final String? supplierId;
  final String? shopId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True when stock is at or below the minimum stock threshold.
  bool get isLowStock => stockQuantity <= minimumStockLevel;

  /// True when stock is completely exhausted.
  bool get isOutOfStock => stockQuantity <= 0;

  /// Estimated profit per unit sold.
  double get profitMargin => sellingPrice - purchasePrice;

  /// Total value of current inventory for this product (at purchase price).
  double get inventoryValue => purchasePrice * stockQuantity;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel(
      productId: doc.id,
      productName: data['productName'] as String? ??
          data['name'] as String? ??
          'Unnamed Product',
      sku: data['sku'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      barcode: data['barcode'] as String?,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (data['gstPercentage'] as num?)?.toDouble() ??
          (data['gstRate'] as num?)?.toDouble() ??
          0.0,
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      minimumStockLevel: (data['minimumStockLevel'] as num?)?.toInt() ?? 5,
      unit: data['unit'] as String? ?? 'Units',
      supplierId: data['supplierId'] as String?,
      shopId: data['shop_id'] as String? ?? data['shopId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productName': productName,
        'name': productName,
        'sku': sku,
        'category': category,
        'description': description,
        'barcode': barcode,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'gstPercentage': gstPercentage,
        'gstRate': gstPercentage,
        'stockQuantity': stockQuantity,
        'minimumStockLevel': minimumStockLevel,
        'unit': unit,
        'supplierId': supplierId,
        'shop_id': shopId,
        'shopId': shopId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ProductModel copyWith({
    String? productId,
    String? productName,
    String? sku,
    String? category,
    String? description,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    double? gstPercentage,
    int? stockQuantity,
    int? minimumStockLevel,
    String? unit,
    String? supplierId,
    String? shopId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      unit: unit ?? this.unit,
      supplierId: supplierId ?? this.supplierId,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
