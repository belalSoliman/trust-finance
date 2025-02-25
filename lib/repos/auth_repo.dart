import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Get current user stream
  Stream<UserModel?> get currentUser {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return UserModel.fromFirestore(doc);
    });
  }

  // Sign in with email and password
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        throw 'User data not found';
      }

      final user = UserModel.fromFirestore(doc);

      if (!user.isActive) {
        await _auth.signOut();
        throw 'Account is disabled';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred: $e';
    }
  }

  // Sign out
  Future<void> signOut() => _auth.signOut();

  // Helper method to handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
