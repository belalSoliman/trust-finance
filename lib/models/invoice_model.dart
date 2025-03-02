import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 2)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? customerId;

  @HiveField(2)
  final String customerName;

  @HiveField(3)
  final String customerNumber; // Internally stored as customerNumber for Hive

  @HiveField(4)
  final String customerAddress;

  @HiveField(5)
  final String invoiceNumber;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final List<InvoiceItemModel> items;

  @HiveField(8)
  final double totalAmount;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final bool synced;

  @HiveField(12)
  final String status;

  @HiveField(13)
  final String userId;

  @HiveField(14)
  final String paymentStatus;

  // Constructor for Hive and direct creation
  InvoiceModel({
    String? id,
    this.customerId,
    required this.customerName,
    String? customerPhone, // Optional for Hive compatibility
    required this.customerNumber, // Required for direct instantiation
    required this.customerAddress,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
    this.status = 'issued',
    required this.userId,
    this.paymentStatus = 'pending',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory for normal API usage with customerPhone
  factory InvoiceModel.create({
    String? id,
    String? customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String invoiceNumber,
    required DateTime date,
    required List<InvoiceItemModel> items,
    required double totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool synced = false,
    String status = 'issued',
    required String userId,
    String paymentStatus = 'pending',
  }) {
    return InvoiceModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerNumber: customerPhone,
      customerAddress: customerAddress,
      invoiceNumber: invoiceNumber,
      date: date,
      items: items,
      totalAmount: totalAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      synced: synced,
      status: status,
      userId: userId,
      paymentStatus: paymentStatus,
    );
  }

  // Create a copy with updated fields
  InvoiceModel copyWith({
    String? id,
    Object? customerId = const _Sentinel(),
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? invoiceNumber,
    DateTime? date,
    List<InvoiceItemModel>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
    String? status,
    String? userId,
    String? paymentStatus,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      customerId:
          customerId is _Sentinel ? this.customerId : (customerId as String?),
      customerName: customerName ?? this.customerName,
      customerNumber: customerPhone ?? this.customerNumber,
      customerAddress: customerAddress ?? this.customerAddress,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      synced: synced ?? this.synced,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone':
          customerNumber, // Save as customerPhone for API consistency
      'customerAddress': customerAddress,
      'invoiceNumber': invoiceNumber,
      'date': Timestamp.fromDate(date),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'synced': synced,
      'status': status,
      'userId': userId,
      'paymentStatus': paymentStatus,
    };
  }

  // Create from a Firestore document
  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InvoiceModel(
      id: doc.id,
      customerId: data['customerId'],
      customerName: data['customerName'] ?? '',
      customerNumber: data['customerPhone'] ?? '', // Map from customerPhone
      customerAddress: data['customerAddress'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      items: (data['items'] as List? ?? [])
          .map((item) => InvoiceItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      synced: data['synced'] ?? false,
      status: data['status'] ?? 'issued',
      userId: data['userId'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'pending',
    );
  }

  // Create from a Map (for Hive)
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] ?? const Uuid().v4(),
      customerId: map['customerId'],
      customerName: map['customerName'] ?? '',
      customerNumber: map['customerPhone'] ??
          map['customerNumber'] ??
          '', // Handle both field names
      customerAddress: map['customerAddress'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      date: _parseDateTime(map['date']),
      items: (map['items'] as List? ?? [])
          .map((item) => InvoiceItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      synced: map['synced'] ?? false,
      status: map['status'] ?? 'issued',
      userId: map['userId'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
    );
  }

  // Helper method for parsing dates
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();

    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
}

class _Sentinel {
  const _Sentinel();
}

@HiveType(typeId: 3)
class InvoiceItemModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final double price;

  InvoiceItemModel({
    required this.name,
    required this.quantity,
    required this.price,
  });

  // Create from a Map (for Hive and Firestore)
  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}
