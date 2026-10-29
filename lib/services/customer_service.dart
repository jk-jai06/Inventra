import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';

/// Handles all Firestore operations for customers under users/{uid}/customers.
class CustomerService {
  CustomerService({FirebaseAuth? auth, FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>> get _customers =>
      _userDoc.collection('customers');

  /// Real-time stream of all customers.
  Stream<List<CustomerModel>> customersStream() {
    return _customers.snapshots().map((snap) {
      final list = snap.docs.map(CustomerModel.fromFirestore).toList();
      list.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Fetches a single customer by ID.
  Future<CustomerModel?> getCustomer(String customerId) async {
    final doc = await _customers.doc(customerId).get();
    if (!doc.exists) return null;
    return CustomerModel.fromFirestore(doc);
  }

  /// Adds a new customer. Returns the generated document ID.
  Future<String> addCustomer(CustomerModel customer, {String? shopId}) async {
    String? effectiveShopId = customer.shopId ?? shopId;
    if (effectiveShopId == null || effectiveShopId.isEmpty) {
      final userSnap = await _userDoc.get();
      effectiveShopId = userSnap.data()?['shop_id'] as String?;
    }

    final data = customer
        .copyWith(
          customerId: '',
          shopId: effectiveShopId,
          createdAt: DateTime.now(),
        )
        .toFirestore();

    final ref = await _customers.add(data);
    return ref.id;
  }

  /// Updates an existing customer.
  Future<void> updateCustomer(CustomerModel customer) async {
    await _customers.doc(customer.customerId).update(customer.toFirestore());
  }

  /// Deletes a customer by ID.
  Future<void> deleteCustomer(String customerId) async {
    await _customers.doc(customerId).delete();
  }
}
