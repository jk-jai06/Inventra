import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AuthRepository wraps Firebase Auth and Firestore operations related to
/// registering, signing in, signing out and password reset.
///
/// NOTE: This implementation creates a `shops/{shopId}` document from the
/// client during registration and writes the corresponding `users/{uid}`
/// document with `shop_id` and `role: 'owner'`. This client-side shop
/// creation path is allowed by the project's current Firestore rules but is
/// not as secure as creating shops with an Admin SDK Cloud Function — the
/// hardened approach is out of scope for this task.
class AuthRepository {
  AuthRepository()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return 'Sign in failed: $e';
    }
  }

  Future<String?> register(
      {required String name,
      required String email,
      required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Create a new shop document and the user profile together.
      final shopRef = _firestore.collection('shops').doc();
      final userRef = _firestore.collection('users').doc(user.uid);

      final batch = _firestore.batch();

      batch.set(shopRef, {
        'name': '${name.split(' ').first}\'s shop',
        'ownerUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(userRef, {
        'uid': user.uid,
        'name': name,
        'email': email,
        'shop_id': shopRef.id,
        'role': 'owner',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Update display name in Firebase Auth profile
      await user.updateDisplayName(name);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return 'Password reset failed: $e';
    }
  }
}
