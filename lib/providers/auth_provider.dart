import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Manages authentication state using Firebase Auth stream.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _repo = AuthRepository();
    _sub = _repo.authStateChanges().listen(_onAuthStateChanged);
  }

  late final AuthRepository _repo;
  final _firestore = FirebaseFirestore.instance;
  late final StreamSubscription<User?> _sub;
  StreamSubscription? _userDocSub;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _shopId;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get shopId => _shopId;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _onAuthStateChanged(User? user) {
    _userDocSub?.cancel();
    _user = user;
    _status =
        user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;

    if (user != null) {
      _shopId = null;
      _role = null;
      notifyListeners();

      // Load the users/{uid} doc to obtain shop_id and role.
      // Cancel any prior user-doc listener before starting a new one.
      _userDocSub = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snap) {
        if (snap.exists) {
          final data = snap.data()!;
          _shopId = data['shop_id'] as String?;
          _role = data['role'] as String?;
        } else {
          _shopId = null;
          _role = null;
        }
        notifyListeners();
      });
    } else {
      _shopId = null;
      _role = null;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    final error = await _repo.signIn(email: email, password: password);
    _setLoading(false);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    final error =
        await _repo.register(name: name, email: email, password: password);
    _setLoading(false);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> sendPasswordReset({required String email}) async {
    _setLoading(true);
    _clearError();
    final error = await _repo.sendPasswordReset(email: email);
    _setLoading(false);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  void clearError() => _clearError();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _sub.cancel();
    super.dispose();
  }
}
