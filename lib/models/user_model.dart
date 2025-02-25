import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { superAdmin, manager, cashier }

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
      role: UserRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => UserRole.cashier,
      ),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role.name,
        'isActive': isActive,
      };
}
