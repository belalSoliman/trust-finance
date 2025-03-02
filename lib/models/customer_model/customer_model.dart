//customer model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'customer_model.g.dart'; // For Hive type generation

@HiveType(typeId: 1)
class CustomerModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final String? address;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  @HiveField(8)
  final double totalLoanAmount;

  @HiveField(9)
  final double totalPaidAmount;

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final String createdBy; // User ID who created this customer

  @HiveField(12)
  final bool synced; // Whether this record is synced with Firestore

  // Constructor
  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.totalLoanAmount = 0.0,
    this.totalPaidAmount = 0.0,
    this.isActive = true,
    required this.createdBy,
    this.synced = false,
  });

  // Create a copy of this CustomerModel with optional field updates
  CustomerModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    DateTime? updatedAt,
    double? totalLoanAmount,
    double? totalPaidAmount,
    bool? isActive,
    bool? synced,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalLoanAmount: totalLoanAmount ?? this.totalLoanAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      synced: synced ?? this.synced,
    );
  }

  // Calculate outstanding balance
  double get outstandingBalance => totalLoanAmount - totalPaidAmount;

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'totalLoanAmount': totalLoanAmount,
      'totalPaidAmount': totalPaidAmount,
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }

  // Create from Firestore document
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      totalLoanAmount: data['totalLoanAmount']?.toDouble() ?? 0.0,
      totalPaidAmount: data['totalPaidAmount']?.toDouble() ?? 0.0,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      synced: true,
    );
  }

  // For debugging
  @override
  String toString() {
    return 'CustomerModel{id: $id, name: $name, phone: $phone}';
  }
}
