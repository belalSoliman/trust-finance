import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'payment_model.g.dart'; // You'll need to run build_runner for this

@HiveType(typeId: 3) // Make sure this ID doesn't conflict with other Hive types
class PaymentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String invoiceId;

  @HiveField(2)
  final String customerId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String paymentMethod; // e.g., "Cash", "Credit Card", "Bank Transfer"

  @HiveField(6)
  final String? transactionId; // For digital payments

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  bool synced;

  @HiveField(10)
  final String userId; // User who received the payment

  // Constructor for all fields
  PaymentModel({
    String? id,
    required this.invoiceId,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.transactionId,
    this.notes,
    DateTime? createdAt,
    this.synced = false,
    required this.userId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Factory for creating from Firestore
  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      customerId: data['customerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      paymentMethod: data['paymentMethod'] ?? 'Unknown',
      transactionId: data['transactionId'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      synced: data['synced'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  // Copy with method for creating a modified copy
  PaymentModel copyWith({
    String? id,
    String? invoiceId,
    String? customerId,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    DateTime? createdAt,
    bool? synced,
    String? userId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      userId: userId ?? this.userId,
    );
  }
}
