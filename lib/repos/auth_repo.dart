import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  //create user
  // Add this method to your AuthRepository class

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required UserModel currentUser,
  }) async {
    if (currentUser.role != UserRole.superAdmin) {
      throw 'Only super admin can create users';
    }

    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final newUser = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  Future<UserModel?> checkAuthStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) return null;

      final user = UserModel.fromFirestore(doc);
      if (!user.isActive) {
        await _auth.signOut();
        return null;
      }

      debugPrint('Auto-login successful for: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Check auth status error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        debugPrint('Authentication failed: No user returned');
        throw 'Authentication failed';
      }

      debugPrint('Auth successful for UID: ${credential.user!.uid}');

      final docRef = _firestore.collection('users').doc(credential.user!.uid);
      final doc = await docRef.get();

      debugPrint('Firestore document exists: ${doc.exists}');
      if (!doc.exists) {
        debugPrint('Creating default user document');
        // Create user document if it doesn't exist
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: credential.user!.email!,
          name: credential.user!.displayName ?? 'User',
          role: UserRole.cashier, // Default role
          isActive: true,
        );

        await docRef.set(newUser.toMap());
        return newUser;
      }

      final user = UserModel.fromFirestore(doc);
      debugPrint('User role: ${user.role}');
      debugPrint('User active status: ${user.isActive}');

      if (!user.isActive) {
        await _auth.signOut();
        throw 'Account is disabled';
      }

      debugPrint('User signed in successfully: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
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
