import 'dart:async';
import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../services/invoice_service.dart';
import '../core/utils/gst_calculator.dart';
import 'auth_provider.dart';

/// A billing cart item — a product that has been added to the current invoice.
class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
  });

  final ProductModel product;
  int quantity;

  double get taxableAmount =>
      GstCalculator.lineItemTaxable(product.sellingPrice, quantity);

  double get gstAmount =>
      GstCalculator.gstAmount(taxableAmount, product.gstPercentage);

  double get total => taxableAmount + gstAmount;

  InvoiceLineInput toLineInput() => InvoiceLineInput(
        unitPrice: product.sellingPrice,
        quantity: quantity,
        gstPercent: product.gstPercentage,
      );
}

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider(this._authProvider) {
    _service = InvoiceService();
    _setupAuthListener();
  }

  final AuthProvider _authProvider;
  late final InvoiceService _service;
  StreamSubscription<List<InvoiceModel>>? _sub;

  InvoiceService get service => _service;

  // ── Invoice history ───────────────────────────────────────────────────────
  List<InvoiceModel> _invoices = [];
  bool _historyLoading = false;
  String? _historyError;
  InvoiceModel? _lastInvoice;

  // ── Current billing cart ──────────────────────────────────────────────────
  CustomerModel? _selectedCustomer;
  final List<CartItem> _cart = [];
  bool _isCreatingInvoice = false;
  String? _createError;
  String _paymentMethod = 'cash';

  // ── Getters: history ──────────────────────────────────────────────────────
  List<InvoiceModel> get invoices => _invoices;
  bool get historyLoading => _historyLoading;
  String? get historyError => _historyError;
  InvoiceModel? get lastInvoice => _lastInvoice;

  // ── Getters: cart ─────────────────────────────────────────────────────────
  CustomerModel? get selectedCustomer => _selectedCustomer;
  List<CartItem> get cart => _cart;
  bool get isCreatingInvoice => _isCreatingInvoice;
  String? get createError => _createError;
  String get paymentMethod => _paymentMethod;
  bool get canCheckout => _cart.isNotEmpty && !_isCreatingInvoice;

  InvoiceTotals get cartTotals => GstCalculator.calculateInvoiceTotals(
        _cart.map((c) => c.toLineInput()).toList(),
        customerGstin: _selectedCustomer?.gstin,
      );

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

  String? validateQuantity(ProductModel product, int requestedQuantity) {
    if (requestedQuantity <= 0) {
      return 'Quantity must be greater than zero.';
    }
    if (requestedQuantity > product.stockQuantity) {
      return 'Only ${product.stockQuantity} item(s) available in stock.';
    }
    return null;
  }

  // ─── Invoice history ──────────────────────────────────────────────────────

  void startListening({bool force = false}) {
    if (_sub != null && !force) return;

    _sub?.cancel();
    _historyLoading = _invoices.isEmpty;
    notifyListeners();

    try {
      _sub = _service.invoicesStream().listen(
        (list) {
          _invoices = list;
          _historyLoading = false;
          _historyError = null;
          notifyListeners();
        },
        onError: (e) {
          _historyError = 'Failed to load invoices: $e';
          _historyLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _historyError = 'Failed to connect invoice service: $e';
      _historyLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  void _clearData() {
    _invoices = [];
    _cart.clear();
    _selectedCustomer = null;
    _historyLoading = false;
    _historyError = null;
    _createError = null;
    _lastInvoice = null;
    notifyListeners();
  }

  // ─── Cart management ─────────────────────────────────────────────────────

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    final validation = validateQuantity(product, 1);
    if (validation != null) {
      _createError = validation;
      notifyListeners();
      return;
    }

    final existing =
        _cart.indexWhere((c) => c.product.productId == product.productId);
    if (existing >= 0) {
      final nextQty = _cart[existing].quantity + 1;
      final nextValidation = validateQuantity(product, nextQty);
      if (nextValidation != null) {
        _createError = nextValidation;
        notifyListeners();
        return;
      }
      _cart[existing].quantity = nextQty;
    } else {
      _cart.add(CartItem(product: product, quantity: 1));
    }
    _createError = null;
    notifyListeners();
  }

  void setQuantity(String productId, int qty) {
    final idx = _cart.indexWhere((c) => c.product.productId == productId);
    if (idx < 0) return;

    final product = _cart[idx].product;
    if (qty <= 0) {
      _cart.removeAt(idx);
      _createError = null;
      notifyListeners();
      return;
    }

    final validation = validateQuantity(product, qty);
    if (validation != null) {
      _createError = validation;
      notifyListeners();
      return;
    }

    _cart[idx].quantity = qty;
    _createError = null;
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((c) => c.product.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomer = null;
    _createError = null;
    notifyListeners();
  }

  void clearHistoryError() {
    _historyError = null;
    notifyListeners();
  }

  // ─── Invoice creation (Phase 2 core transaction loop) ──────────────────────

  Future<bool> createInvoice() async {
    if (_isCreatingInvoice) return false;
    if (_cart.isEmpty) {
      _createError = 'Your cart is empty.';
      notifyListeners();
      return false;
    }

    for (final item in _cart) {
      final validation = validateQuantity(item.product, item.quantity);
      if (validation != null) {
        _createError = validation;
        notifyListeners();
        return false;
      }
    }

    _isCreatingInvoice = true;
    _createError = null;
    notifyListeners();

    final totals = cartTotals;

    final items = _cart.map((c) {
      final taxable =
          GstCalculator.lineItemTaxable(c.product.sellingPrice, c.quantity);
      final gst = GstCalculator.gstAmount(taxable, c.product.gstPercentage);
      return InvoiceItem(
        productId: c.product.productId,
        productName: c.product.productName,
        sku: c.product.sku,
        quantity: c.quantity,
        unitPrice: c.product.sellingPrice,
        gstPercentage: c.product.gstPercentage,
        gstAmount: gst,
        taxableAmount: taxable,
        total: taxable + gst,
      );
    }).toList();

    final invoice = InvoiceModel(
      invoiceId: '',
      invoiceNumber: '', // will be atomically generated sequentially in transaction
      shopId: _authProvider.shopId,
      customerId: _selectedCustomer?.customerId ?? '',
      customerName: _selectedCustomer?.name ?? 'Walk-in Customer',
      customerPhone: _selectedCustomer?.phone,
      customerGstin: _selectedCustomer?.gstin,
      items: items,
      subtotal: totals.subtotal,
      totalGst: totals.totalGst,
      cgst: totals.cgst,
      sgst: totals.sgst,
      igst: totals.igst,
      isInterState: totals.isInterState,
      grandTotal: totals.grandTotal,
      paymentMethod: _paymentMethod,
      paymentStatus: PaymentStatus.paid,
      createdAt: DateTime.now(),
    );

    final result = await _service.createInvoice(invoice);

    _isCreatingInvoice = false;
    if (!result.isSuccess || result.invoice == null) {
      _createError = result.errorMessage ?? 'Failed to complete sale.';
      notifyListeners();
      return false;
    }

    _lastInvoice = result.invoice;
    clearCart();
    notifyListeners();
    return true;
  }

  void clearCreateError() {
    _createError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
