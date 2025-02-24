import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trust_finiance/utils/user_role.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      final user = UserModel.fromFirestore(doc);

      if (!user.isActive) {
        await _auth.signOut();
        throw 'Account is disabled';
      }

      return user;
    } catch (e) {
      throw 'Failed to sign in: $e';
    }
  }

  // Create new user (only super admin can do this)
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required UserModel currentUser,
  }) async {
    if (currentUser.role != UserRole.superAdmin) {
      throw 'Insufficient permissions';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  // Sign out
  Future<void> signOut() => _auth.signOut();
}
