import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../core/constants/app_constants.dart';

/// Result wrapper for invoice transaction.
class InvoiceTransactionResult {
  const InvoiceTransactionResult({
    required this.isSuccess,
    this.errorMessage,
    this.invoice,
  });

  final bool isSuccess;
  final String? errorMessage;
  final InvoiceModel? invoice;
}

/// Handles POS invoice creation, sales recording, inventory deduction,
/// and analytics aggregation as a single atomic Firestore transaction.
class InvoiceService {
  InvoiceService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _userDoc.collection(AppConstants.invoicesCollection);

  CollectionReference<Map<String, dynamic>> get _sales =>
      _userDoc.collection('sales');

  CollectionReference<Map<String, dynamic>> get _products =>
      _userDoc.collection(AppConstants.productsCollection);

  CollectionReference<Map<String, dynamic>> get _customers =>
      _userDoc.collection(AppConstants.customersCollection);

  DocumentReference<Map<String, dynamic>> get _businessSettingsDoc =>
      _userDoc.collection('settings').doc('business');

  DocumentReference<Map<String, dynamic>> get _analyticsSummaryDoc =>
      _userDoc.collection('analytics').doc('summary');

  /// Creates an invoice and completes the sale atomically in a single Firestore transaction:
  ///   1. Validates stock for every line item.
  ///   2. Deducts stock from each product atomically.
  ///   3. Records stock movement entry for each product.
  ///   4. Generates a collision-free sequential invoice number per shop.
  ///   5. Saves the invoice document (`users/{uid}/invoices/{invoiceId}`).
  ///   6. Records the sale transaction (`users/{uid}/sales/{saleId}`) and line items.
  ///   7. Updates customer total purchases and invoice count.
  ///   8. Updates aggregate analytics counters.
  Future<InvoiceTransactionResult> createInvoice(InvoiceModel invoice) async {
    try {
      final createdInvoice = await _firestore
          .runTransaction<InvoiceModel>((txn) async {
        if (invoice.items.isEmpty) {
          throw Exception('Cart is empty.');
        }

        // ── Step 1: Read all required documents first (Firestore transaction rule) ──
        final userSnap = await txn.get(_userDoc);
        final shopId = userSnap.data()?['shop_id'] as String? ??
            userSnap.data()?['shopId'] as String? ??
            '';

        // Read settings/business for sequential invoice counter
        final settingsSnap = await txn.get(_businessSettingsDoc);
        int currentCounter =
            (settingsSnap.data()?['invoiceCounter'] as num?)?.toInt() ?? 0;
        final nextCounter = currentCounter + 1;
        final generatedInvoiceNumber =
            '${AppConstants.invoicePrefix}-${nextCounter.toString().padLeft(4, '0')}';

        // Read product docs
        final productRefs = invoice.items
            .map((item) => _products.doc(item.productId))
            .toList();

        final productSnaps = await Future.wait(
          productRefs.map((ref) => txn.get(ref)),
        );

        // Read customer doc if present
        DocumentSnapshot<Map<String, dynamic>>? customerSnap;
        DocumentReference<Map<String, dynamic>>? customerRef;
        if (invoice.customerId.isNotEmpty) {
          customerRef = _customers.doc(invoice.customerId);
          customerSnap = await txn.get(customerRef);
        }

        // Read analytics summary doc
        final analyticsSnap = await txn.get(_analyticsSummaryDoc);

        // ── Step 2: Validate stock for every item ──
        final stockMap = <String, int>{};
        for (int i = 0; i < invoice.items.length; i++) {
          final item = invoice.items[i];
          final snap = productSnaps[i];

          if (!snap.exists) {
            throw Exception(
                'Product "${item.productName}" was not found in inventory.');
          }

          final currentStock =
              (snap.data()?['stockQuantity'] as num?)?.toInt() ?? 0;

          if (currentStock < item.quantity) {
            throw Exception(
                'Insufficient stock for "${item.productName}". Available: $currentStock, Requested: ${item.quantity}.');
          }

          stockMap[item.productId] = currentStock;
        }

        // ── Step 3: Perform all writes atomically ──
        final now = DateTime.now();
        final nowTimestamp = Timestamp.fromDate(now);

        // 3a. Update product stock & write stock movements
        for (int i = 0; i < invoice.items.length; i++) {
          final item = invoice.items[i];
          final prevStock = stockMap[item.productId]!;
          final newStock = prevStock - item.quantity;

          txn.update(productRefs[i], {
            'stockQuantity': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          final movementRef =
              _products.doc(item.productId).collection('stockMovements').doc();
          txn.set(movementRef, {
            'productId': item.productId,
            'productName': item.productName,
            'movementType': 'sale',
            'quantityChange': -item.quantity,
            'previousQuantity': prevStock,
            'newQuantity': newStock,
            'referenceId': generatedInvoiceNumber,
            'shop_id': shopId,
            'shopId': shopId,
            'timestamp': nowTimestamp,
            'notes': 'POS Sale $generatedInvoiceNumber',
          });
        }

        // 3b. Save sequential counter
        txn.set(
          _businessSettingsDoc,
          {
            'invoiceCounter': nextCounter,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 3c. Save Invoice
        final invoiceRef = _invoices.doc(_uuid.v4());
        final finalInvoice = invoice.copyWith(
          invoiceId: invoiceRef.id,
          invoiceNumber: generatedInvoiceNumber,
          shopId: shopId,
          createdAt: now,
        );
        txn.set(invoiceRef, finalInvoice.toFirestore());

        // 3d. Save Sale Record
        final saleRef = _sales.doc(invoiceRef.id);
        txn.set(saleRef, {
          'id': saleRef.id,
          'invoiceId': invoiceRef.id,
          'invoiceNumber': generatedInvoiceNumber,
          'customerId': invoice.customerId,
          'customerName': invoice.customerName,
          'subtotal': invoice.subtotal,
          'gstAmount': invoice.totalGst,
          'cgst': invoice.cgst,
          'sgst': invoice.sgst,
          'igst': invoice.igst,
          'isInterState': invoice.isInterState,
          'discount': 0.0,
          'grandTotal': invoice.grandTotal,
          'paymentMethod': invoice.paymentMethod,
          'shop_id': shopId,
          'shopId': shopId,
          'itemCount': invoice.items.length,
          'items': invoice.items.map((i) => i.toMap()).toList(),
          'createdAt': nowTimestamp,
        });

        // 3e. Save individual items in sale subcollection
        for (final item in invoice.items) {
          final itemRef = saleRef.collection('items').doc();
          txn.set(itemRef, {
            'productId': item.productId,
            'productName': item.productName,
            'sku': item.sku,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'gstPercentage': item.gstPercentage,
            'gstAmount': item.gstAmount,
            'taxableAmount': item.taxableAmount,
            'total': item.total,
          });
        }

        // 3f. Update customer stats if selected
        if (customerRef != null && customerSnap != null && customerSnap.exists) {
          txn.update(customerRef, {
            'totalPurchases': FieldValue.increment(invoice.grandTotal),
            'invoiceCount': FieldValue.increment(1),
            'lastPurchaseAt': nowTimestamp,
          });
        }

        // 3g. Update analytics summary
        final double prevSales =
            (analyticsSnap.data()?['totalSales'] as num?)?.toDouble() ?? 0.0;
        final int prevInvoices =
            (analyticsSnap.data()?['totalInvoices'] as num?)?.toInt() ?? 0;

        txn.set(
          _analyticsSummaryDoc,
          {
            'totalSales': prevSales + invoice.grandTotal,
            'totalInvoices': prevInvoices + 1,
            'lastSaleAt': nowTimestamp,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return finalInvoice;
      });

      return InvoiceTransactionResult(
        isSuccess: true,
        invoice: createdInvoice,
      );
    } catch (e) {
      return InvoiceTransactionResult(
        isSuccess: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Real-time stream of invoices, most recent first.
  Stream<List<InvoiceModel>> invoicesStream({int limit = 50}) {
    return _invoices
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(InvoiceModel.fromFirestore).toList());
  }

  /// Fetches invoices for a specific customer.
  Stream<List<InvoiceModel>> customerInvoicesStream(String customerId) {
    return _invoices
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(InvoiceModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Gets next invoice preview number without advancing counter.
  Future<String> previewNextInvoiceNumber() async {
    try {
      final snap = await _businessSettingsDoc.get();
      final current = (snap.data()?['invoiceCounter'] as num?)?.toInt();
      if (current != null) {
        return '${AppConstants.invoicePrefix}-${(current + 1).toString().padLeft(4, '0')}';
      }
      final countSnap = await _invoices.count().get();
      final count = (countSnap.count ?? 0) + 1;
      return '${AppConstants.invoicePrefix}-${count.toString().padLeft(4, '0')}';
    } catch (_) {
      return '${AppConstants.invoicePrefix}-0001';
    }
  }
}
