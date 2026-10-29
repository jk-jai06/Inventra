import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';

/// Handles all Firestore operations for products under users/{uid}/products.
class ProductService {
  ProductService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _products =>
      _userDoc.collection('products');

  /// Real-time stream of all products.
  Stream<List<ProductModel>> productsStream() {
    return _products.snapshots().map((snap) {
      final list = snap.docs.map(ProductModel.fromFirestore).toList();
      list.sort((a, b) =>
          a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
      return list;
    });
  }

  /// Real-time stream of products at or below minimum stock level.
  Stream<List<ProductModel>> lowStockStream() {
    return productsStream().map(
      (list) => list.where((p) => p.isLowStock).toList(),
    );
  }

  /// Fetches a single product by ID (one-time read).
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  /// Adds a new product. Returns the generated document ID.
  Future<String> addProduct(ProductModel product, {String? shopId}) async {
    String? effectiveShopId = product.shopId ?? shopId;
    if (effectiveShopId == null || effectiveShopId.isEmpty) {
      final userSnap = await _userDoc.get();
      effectiveShopId = userSnap.data()?['shop_id'] as String?;
    }

    final now = DateTime.now();
    final data = product
        .copyWith(
          productId: '',
          shopId: effectiveShopId,
          createdAt: now,
          updatedAt: now,
        )
        .toFirestore();

    final ref = await _products.add(data);
    return ref.id;
  }

  /// Updates an existing product.
  Future<void> updateProduct(ProductModel product) async {
    final data = product.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(product.productId).update(data);
  }

  /// Deletes a product by ID.
  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  /// Adjusts stock quantity for a product atomically in a Firestore transaction.
  /// (positive = stock in/purchase, negative = stock out/wastage/adjustment).
  /// Returns an error string if stock goes negative, null on success.
  Future<String?> adjustStock(
    String productId,
    int delta, {
    String movementType = 'adjustment',
    String? referenceId,
    String notes = '',
  }) async {
    return _firestore.runTransaction<String?>((txn) async {
      final ref = _products.doc(productId);
      final snap = await txn.get(ref);
      if (!snap.exists) return 'Product not found.';

      final data = snap.data()!;
      final currentQty = (data['stockQuantity'] as num?)?.toInt() ?? 0;
      final newQty = currentQty + delta;

      if (newQty < 0) {
        return 'Insufficient stock. Available: $currentQty units.';
      }

      final shopId = data['shop_id'] as String? ?? data['shopId'] as String?;

      // Update the product stock
      txn.update(ref, {
        'stockQuantity': newQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record the stock movement
      final movementRef = ref.collection('stockMovements').doc();
      final movement = StockMovementModel(
        movementId: movementRef.id,
        productId: productId,
        productName: data['productName'] as String? ??
            data['name'] as String? ??
            'Product',
        movementType: movementType,
        quantityChange: delta,
        previousQuantity: currentQty,
        newQuantity: newQty,
        referenceId: referenceId,
        shopId: shopId,
        timestamp: DateTime.now(),
        notes: notes,
      );

      txn.set(movementRef, movement.toFirestore());
      return null;
    });
  }

  /// Stream of stock movements for a specific product.
  Stream<List<StockMovementModel>> stockMovementsStream(String productId) {
    return _products
        .doc(productId)
        .collection('stockMovements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(StockMovementModel.fromFirestore).toList(),
        );
  }

  /// Fetches recent stock movements across all products.
  Future<List<StockMovementModel>> getRecentMovements({int limit = 30}) async {
    final productsSnap = await _products.get();
    final movements = <StockMovementModel>[];

    for (final doc in productsSnap.docs) {
      final moveSnap = await doc.reference
          .collection('stockMovements')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      movements.addAll(moveSnap.docs.map(StockMovementModel.fromFirestore));
    }

    movements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return movements.take(limit).toList();
  }

  /// Fetches all distinct product categories.
  Future<List<String>> getCategories() async {
    final snap = await _products.get();
    final categories = snap.docs
        .map((d) => (d.data()['category'] as String?)?.trim() ?? 'General')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }
}
