import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

enum UserRole {
  superAdmin,
  manager,
  cashier;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.cashier,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromString(data['role'] ?? ''),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role.name,
        'isActive': isActive,
      };
  factory UserModel.fromFirebaseUser(auth.User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'User',
      role: UserRole.cashier, // Default role
      isActive: true, // Default to active
    );
  }
}
