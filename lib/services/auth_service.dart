import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps Firebase Authentication operations.
/// Returns descriptive error messages instead of raw Firebase codes.
class AuthService {
  AuthService()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Stream of auth state changes. Emits a [User] when signed in, null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Signs in with email and password.
  /// Returns null on success or an error message string.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Registers a new user with email, password, and display name.
  /// Returns null on success or an error message string.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      // Update display name
      await user.updateDisplayName(name);

      // Create user profile document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (_) {
      return 'Registration failed. Please try again.';
    }
  }

  /// Sends a password reset email.
  Future<String?> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (_) {
      return 'Could not send reset email. Please try again.';
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Maps Firebase error codes to human-readable messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}
