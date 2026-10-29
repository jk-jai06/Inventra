import 'package:cloud_firestore/cloud_firestore.dart';

/// A single line item in an invoice.
class InvoiceItem {
  const InvoiceItem({
    required this.productId,
    required this.productName,
    this.sku = '',
    required this.quantity,
    required this.unitPrice,
    required this.gstPercentage,
    required this.gstAmount,
    required this.taxableAmount,
    required this.total,
  });

  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double gstPercentage;
  final double gstAmount;
  final double taxableAmount; // unitPrice × quantity
  final double total; // taxableAmount + gstAmount

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        sku: map['sku'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
        gstPercentage: (map['gstPercentage'] as num?)?.toDouble() ??
            (map['gstRate'] as num?)?.toDouble() ??
            0.0,
        gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0.0,
        taxableAmount: (map['taxableAmount'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'gstPercentage': gstPercentage,
        'gstRate': gstPercentage,
        'gstAmount': gstAmount,
        'taxableAmount': taxableAmount,
        'total': total,
      };
}

/// Payment status of an invoice.
enum PaymentStatus { paid, pending, partial }

/// A complete GST invoice document.
class InvoiceModel {
  const InvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    this.shopId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerGstin,
    required this.items,
    required this.subtotal,
    required this.totalGst,
    required this.cgst,
    required this.sgst,
    this.igst = 0.0,
    this.isInterState = false,
    required this.grandTotal,
    this.paymentMethod = 'cash',
    required this.paymentStatus,
    required this.createdAt,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String? shopId;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerGstin;
  final List<InvoiceItem> items;
  final double subtotal; // Sum of taxable amounts
  final double totalGst; // CGST + SGST or IGST
  final double cgst;
  final double sgst;
  final double igst;
  final bool isInterState;
  final double grandTotal; // subtotal + totalGst
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return InvoiceModel(
      invoiceId: data['invoiceId'] as String? ?? doc.id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      shopId: data['shop_id'] as String? ?? data['shopId'] as String?,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Walk-in Customer',
      customerPhone: data['customerPhone'] as String?,
      customerGstin: data['customerGstin'] as String?,
      items: rawItems
          .map((e) => InvoiceItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalGst: (data['totalGst'] as num?)?.toDouble() ??
          (data['gstAmount'] as num?)?.toDouble() ??
          0.0,
      cgst: (data['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (data['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (data['igst'] as num?)?.toDouble() ?? 0.0,
      isInterState: data['isInterState'] as bool? ?? false,
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'cash',
      paymentStatus: _parsePaymentStatus(data['paymentStatus'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
        'shop_id': shopId,
        'shopId': shopId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerGstin': customerGstin,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'totalGst': totalGst,
        'gstAmount': totalGst,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'isInterState': isInterState,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  InvoiceModel copyWith({
    String? invoiceId,
    String? invoiceNumber,
    String? shopId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerGstin,
    List<InvoiceItem>? items,
    double? subtotal,
    double? totalGst,
    double? cgst,
    double? sgst,
    double? igst,
    bool? isInterState,
    double? grandTotal,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerGstin: customerGstin ?? this.customerGstin,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalGst: totalGst ?? this.totalGst,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      isInterState: isInterState ?? this.isInterState,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static PaymentStatus _parsePaymentStatus(String? value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      default:
        return PaymentStatus.paid;
    }
  }
}
