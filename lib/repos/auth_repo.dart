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
      // First authenticate with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'Authentication failed';
      }

      final uid = credential.user!.uid;
      debugPrint('Auth successful for UID: $uid');

      // Get user document from Firestore
      try {
        // Check if a document with this email already exists
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'superAdmin')
            .get();

        if (emailQuery.docs.isNotEmpty) {
          debugPrint('Found superAdmin document by email');

          // Get the document data
          final existingDoc = emailQuery.docs.first;
          final data = existingDoc.data();

          // If document ID doesn't match auth UID, create a new document with the auth UID
          if (existingDoc.id != uid) {
            debugPrint('Updating document ID to match auth UID');

            await _firestore.collection('users').doc(uid).set(data);

            // Don't delete old document to prevent data loss
            // Just update the document we're using
          }

          // Return the user model with superAdmin role
          return UserModel(
            uid: uid,
            email: email,
            name: data['name'] ?? 'User',
            role: UserRole.superAdmin,
            isActive: data['isActive'] ?? true,
          );
        }

        // If no superAdmin document found, check for document with matching UID
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists) {
          debugPrint('Found existing user document by UID');
          final user = UserModel.fromFirestore(userDoc);

          // Check if we need to update role to superAdmin
          if (user.role != UserRole.superAdmin) {
            // Check if there's a superAdmin doc with this email elsewhere
            final adminQuery = await _firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .where('role', isEqualTo: 'superAdmin')
                .get();

            if (adminQuery.docs.isNotEmpty) {
              // Update this document to be superAdmin
              await _firestore.collection('users').doc(uid).update({
                'role': 'superAdmin',
                'name': adminQuery.docs.first.data()['name'] ?? user.name
              });

              // Return updated user
              return UserModel(
                uid: uid,
                email: email,
                name: adminQuery.docs.first.data()['name'] ?? user.name,
                role: UserRole.superAdmin,
                isActive: true,
              );
            }
            return user;
          }
          return user;
        } else {
          // Create new user document if it doesn't exist
          debugPrint('Creating new user document');

          // Check if there's a document with this email first
          final emailQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (emailQuery.docs.isNotEmpty) {
            // Use existing data but with new UID
            final data = emailQuery.docs.first.data();

            final newUser = UserModel(
              uid: uid,
              email: email,
              name: data['name'] ?? 'User',
              role: UserRole.fromString(data['role'] ?? 'cashier'),
              isActive: data['isActive'] ?? true,
            );

            await _firestore.collection('users').doc(uid).set(newUser.toMap());
            return newUser;
          }

          // No existing document, create new
          final newUser = UserModel(
            uid: uid,
            email: email,
            name: credential.user!.displayName ?? 'User',
            role: UserRole.cashier,
            isActive: true,
          );

          await _firestore.collection('users').doc(uid).set(newUser.toMap());
          return newUser;
        }
      } catch (e) {
        debugPrint('Firestore error: $e');
        throw 'Error accessing user data: $e';
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw 'Authentication error: $e';
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
