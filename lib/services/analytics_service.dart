import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice_model.dart';

/// Aggregates sales analytics and dashboard statistics from Firestore data.
class AnalyticsService {
  AnalyticsService({FirebaseAuth? auth, FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _userDoc.collection('invoices');

  CollectionReference<Map<String, dynamic>> get _products =>
      _userDoc.collection('products');

  CollectionReference<Map<String, dynamic>> get _customers =>
      _userDoc.collection('customers');

  /// Real-time stream of dashboard KPI summary data.
  Stream<DashboardSummary> summaryStream() {
    return _invoices.snapshots().asyncMap((invoiceSnap) async {
      final invoices =
          invoiceSnap.docs.map(InvoiceModel.fromFirestore).toList();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      double todayRevenue = 0.0;
      int todayInvoices = 0;

      double monthRevenue = 0.0;
      int monthInvoices = 0;

      double totalRevenue = 0.0;
      double totalGst = 0.0;

      for (final inv in invoices) {
        totalRevenue += inv.grandTotal;
        totalGst += inv.totalGst;

        if (inv.createdAt.isAfter(todayStart) ||
            inv.createdAt.isAtSameMomentAs(todayStart)) {
          todayRevenue += inv.grandTotal;
          todayInvoices++;
        }

        if (inv.createdAt.isAfter(monthStart) ||
            inv.createdAt.isAtSameMomentAs(monthStart)) {
          monthRevenue += inv.grandTotal;
          monthInvoices++;
        }
      }

      int totalProducts = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      double inventoryValue = 0.0;

      try {
        final prodSnap = await _products.get();
        totalProducts = prodSnap.docs.length;
        for (final doc in prodSnap.docs) {
          final data = doc.data();
          final stock = (data['stockQuantity'] as num?)?.toInt() ?? 0;
          final minStock = (data['minimumStockLevel'] as num?)?.toInt() ?? 5;
          final purchasePrice =
              (data['purchasePrice'] as num?)?.toDouble() ?? 0.0;

          inventoryValue += stock * purchasePrice;
          if (stock <= 0) {
            outOfStockCount++;
          } else if (stock <= minStock) {
            lowStockCount++;
          }
        }
      } catch (_) {}

      int totalCustomers = 0;
      try {
        final custSnap = await _customers.count().get();
        totalCustomers = custSnap.count ?? 0;
      } catch (_) {}

      return DashboardSummary(
        todayRevenue: todayRevenue,
        todayInvoices: todayInvoices,
        monthRevenue: monthRevenue,
        monthInvoices: monthInvoices,
        totalRevenue: totalRevenue,
        totalInvoices: invoices.length,
        totalGstCollected: totalGst,
        totalProducts: totalProducts,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        totalCustomers: totalCustomers,
        inventoryValue: inventoryValue,
      );
    });
  }

  /// Fetches daily sales totals for the last [days] days.
  Future<List<DailySalesSummary>> getDailySales({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _invoices
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt')
        .get();

    final invoices = snap.docs.map(InvoiceModel.fromFirestore).toList();

    final Map<String, DailySalesSummary> grouped = {};
    for (final inv in invoices) {
      final key = _dateKey(inv.createdAt);
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = DailySalesSummary(
          date: DateTime(
              inv.createdAt.year, inv.createdAt.month, inv.createdAt.day),
          revenue: inv.grandTotal,
          invoiceCount: 1,
          gstCollected: inv.totalGst,
        );
      } else {
        grouped[key] = DailySalesSummary(
          date: existing.date,
          revenue: existing.revenue + inv.grandTotal,
          invoiceCount: existing.invoiceCount + 1,
          gstCollected: existing.gstCollected + inv.totalGst,
        );
      }
    }

    return grouped.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Aggregates top-selling products by total quantity sold.
  Future<List<ProductSalesSummary>> getTopProducts({int limit = 10}) async {
    final snap = await _invoices.get();
    final invoices = snap.docs.map(InvoiceModel.fromFirestore).toList();

    final Map<String, ProductSalesSummary> totals = {};
    for (final inv in invoices) {
      for (final item in inv.items) {
        final existing = totals[item.productId];
        if (existing == null) {
          totals[item.productId] = ProductSalesSummary(
            productId: item.productId,
            productName: item.productName,
            totalQuantity: item.quantity,
            totalRevenue: item.total,
          );
        } else {
          totals[item.productId] = ProductSalesSummary(
            productId: item.productId,
            productName: existing.productName,
            totalQuantity: existing.totalQuantity + item.quantity,
            totalRevenue: existing.totalRevenue + item.total,
          );
        }
      }
    }

    final sorted = totals.values.toList()
      ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    return sorted.take(limit).toList();
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

/// Consolidated KPI summary for dashboard.
class DashboardSummary {
  const DashboardSummary({
    this.todayRevenue = 0.0,
    this.todayInvoices = 0,
    this.monthRevenue = 0.0,
    this.monthInvoices = 0,
    this.totalRevenue = 0.0,
    this.totalInvoices = 0,
    this.totalGstCollected = 0.0,
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalCustomers = 0,
    this.inventoryValue = 0.0,
  });

  final double todayRevenue;
  final int todayInvoices;
  final double monthRevenue;
  final int monthInvoices;
  final double totalRevenue;
  final int totalInvoices;
  final double totalGstCollected;
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalCustomers;
  final double inventoryValue;
}

class DailySalesSummary {
  const DailySalesSummary({
    required this.date,
    required this.revenue,
    required this.invoiceCount,
    required this.gstCollected,
  });
  final DateTime date;
  final double revenue;
  final int invoiceCount;
  final double gstCollected;
}

class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;
}
