import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer of the retail shop.
class CustomerModel {
  const CustomerModel({
    required this.customerId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstin,
    this.totalPurchases = 0.0,
    this.invoiceCount = 0,
    this.shopId,
    required this.createdAt,
  });

  final String customerId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin; // GST Identification Number (optional, 15 chars)
  final double totalPurchases; // Sum of all invoice grand totals
  final int invoiceCount;
  final String? shopId;
  final DateTime createdAt;

  /// Extracts the 2-digit state code from the GSTIN if valid.
  String? get gstStateCode {
    if (gstin == null) return null;
    final trimmed = gstin!.trim();
    if (trimmed.length >= 2) {
      final code = trimmed.substring(0, 2);
      if (int.tryParse(code) != null) {
        return code;
      }
    }
    return null;
  }

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CustomerModel(
      customerId: doc.id,
      name: data['name'] as String? ?? 'Unnamed Customer',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      gstin: data['gstin'] as String?,
      totalPurchases: (data['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      invoiceCount: (data['invoiceCount'] as num?)?.toInt() ?? 0,
      shopId: data['shop_id'] as String? ?? data['shopId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'totalPurchases': totalPurchases,
        'invoiceCount': invoiceCount,
        'shop_id': shopId,
        'shopId': shopId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  CustomerModel copyWith({
    String? customerId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    double? totalPurchases,
    int? invoiceCount,
    String? shopId,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
