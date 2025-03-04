//customer repository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model/invoice_model.dart';
import 'package:trust_finiance/models/user_model.dart';
import 'package:uuid/uuid.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore;
  final Box<CustomerModel> _localBox;
  final UserModel _currentUser;

  CustomerRepository({
    required UserModel currentUser,
    FirebaseFirestore? firestore,
    Box<CustomerModel>? localBox,
  })  : _currentUser = currentUser,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _localBox = localBox ?? Hive.box<CustomerModel>('customers');

  // Create a new customer
  Future<CustomerModel> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final customerId = const Uuid().v4(); // Generate unique ID

      final customer = CustomerModel(
        id: customerId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        createdAt: now,
        updatedAt: now,
        createdBy: _currentUser.uid,
      );

      // Save locally first
      await _localBox.put(customerId, customer);

      // Try to sync with Firestore if online
      try {
        await _firestore
            .collection('customers')
            .doc(customerId)
            .set(customer.toMap());

        // Update local record to mark as synced
        final syncedCustomer = customer.copyWith(synced: true);
        await _localBox.put(customerId, syncedCustomer);
        return syncedCustomer;
      } catch (e) {
        // Network error, return the unsynced version
        debugPrint('Failed to sync customer to Firestore: $e');
        return customer;
      }
    } catch (e) {
      debugPrint('Error adding customer: $e');
      throw 'Failed to add customer: $e';
    }
  }

  // Get all customers
  Future<List<CustomerModel>> getCustomers() async {
    try {
      // First try to get from Firestore if online
      try {
        final snapshot = await _firestore.collection('customers').get();

        // Update local storage with Firestore data
        for (final doc in snapshot.docs) {
          final customer = CustomerModel.fromFirestore(doc);
          await _localBox.put(customer.id, customer);
        }

        // Return from local storage (now updated)
        return _localBox.values.toList();
      } catch (e) {
        // Network error, return local data only
        debugPrint('Failed to sync customers from Firestore: $e');
        return _localBox.values.toList();
      }
    } catch (e) {
      debugPrint('Error getting customers: $e');
      throw 'Failed to get customers: $e';
    }
  }

  // Get a specific customer by ID

  // Update an existing customer
  Future<CustomerModel> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    try {
      // Get current customer
      final currentCustomer = _localBox.get(id);

      if (currentCustomer == null) {
        throw 'Customer not found';
      }

      // Create updated customer
      final updatedCustomer = currentCustomer.copyWith(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        isActive: isActive,
        updatedAt: DateTime.now(),
        synced: false, // Mark as unsynced
      );

      // Update locally
      await _localBox.put(id, updatedCustomer);

      // Try to sync with Firestore
      try {
        await _firestore
            .collection('customers')
            .doc(id)
            .update(updatedCustomer.toMap());

        // Mark as synced
        final syncedCustomer = updatedCustomer.copyWith(synced: true);
        await _localBox.put(id, syncedCustomer);
        return syncedCustomer;
      } catch (e) {
        // Network error, return unsynced version
        debugPrint('Failed to sync updated customer to Firestore: $e');
        return updatedCustomer;
      }
    } catch (e) {
      debugPrint('Error updating customer: $e');
      throw 'Failed to update customer: $e';
    }
  }

  // Delete a customer (soft delete by setting isActive to false)
  Future<void> deleteCustomer(String id) async {
    try {
      final customer = _localBox.get(id);

      if (customer == null) {
        throw 'Customer not found';
      }

      // Soft delete by marking as inactive
      final updatedCustomer = customer.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Update locally
      await _localBox.put(id, updatedCustomer);

      // Try to sync with Firestore
      try {
        await _firestore.collection('customers').doc(id).update({
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mark as synced
        final syncedCustomer = updatedCustomer.copyWith(synced: true);
        await _localBox.put(id, syncedCustomer);
      } catch (e) {
        // Failed to sync, but local update succeeded
        debugPrint('Failed to sync deleted customer to Firestore: $e');
      }
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      throw 'Failed to delete customer: $e';
    }
  }

  // Permanently delete a customer (hard delete)
  Future<void> permanentlyDeleteCustomer(String id) async {
    try {
      // Delete locally
      await _localBox.delete(id);

      // Try to delete from Firestore
      try {
        await _firestore.collection('customers').doc(id).delete();
      } catch (e) {
        // Failed to sync deletion, but local delete succeeded
        debugPrint('Failed to delete customer from Firestore: $e');
      }
    } catch (e) {
      debugPrint('Error permanently deleting customer: $e');
      throw 'Failed to permanently delete customer: $e';
    }
  }

  // Sync all unsynced customers
  Future<void> syncUnsyncedCustomers() async {
    try {
      final unsyncedCustomers =
          _localBox.values.where((customer) => !customer.synced).toList();

      for (final customer in unsyncedCustomers) {
        try {
          await _firestore
              .collection('customers')
              .doc(customer.id)
              .set(customer.toMap());

          // Mark as synced
          final syncedCustomer = customer.copyWith(synced: true);
          await _localBox.put(customer.id, syncedCustomer);
        } catch (e) {
          // Continue to next customer if one fails
          debugPrint('Failed to sync customer ${customer.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing customers: $e');
      throw 'Failed to sync customers: $e';
    }
  }

  // Search customers by name or phone
  Future<List<CustomerModel>> searchCustomers(String query) async {
    // First try Firestore search if online
    try {
      final nameResults = await _firestore
          .collection('customers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final phoneResults = await _firestore
          .collection('customers')
          .where('phone', isGreaterThanOrEqualTo: query)
          .where('phone', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final results = <CustomerModel>[];

      // Add name matches
      for (final doc in nameResults.docs) {
        final customer = CustomerModel.fromFirestore(doc);
        results.add(customer);
        await _localBox.put(customer.id, customer);
      }

      // Add phone matches (avoiding duplicates)
      for (final doc in phoneResults.docs) {
        if (!results.any((c) => c.id == doc.id)) {
          final customer = CustomerModel.fromFirestore(doc);
          results.add(customer);
          await _localBox.put(customer.id, customer);
        }
      }

      return results;
    } catch (e) {
      // Network error, search locally
      debugPrint('Failed to search customers in Firestore: $e');

      return _localBox.values.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.phone.toLowerCase().contains(query);
      }).toList();
    }
  }

  // Update customer balance when a loan is added
  Future<CustomerModel> updateCustomerLoanAmount({
    required String customerId,
    required double amount,
  }) async {
    try {
      final customer = await getCustomer(customerId);

      if (customer == null) {
        throw 'Customer not found';
      }

      final updatedCustomer = customer.copyWith(
        totalLoanAmount: customer.totalLoanAmount + amount,
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Update locally
      await _localBox.put(customerId, updatedCustomer);

      // Try to sync with Firestore
      try {
        await _firestore.collection('customers').doc(customerId).update({
          'totalLoanAmount': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mark as synced
        final syncedCustomer = updatedCustomer.copyWith(synced: true);
        await _localBox.put(customerId, syncedCustomer);
        return syncedCustomer;
      } catch (e) {
        // Network error, return unsynced version
        debugPrint('Failed to sync customer loan amount to Firestore: $e');
        return updatedCustomer;
      }
    } catch (e) {
      debugPrint('Error updating customer loan amount: $e');
      throw 'Failed to update customer loan amount: $e';
    }
  }

  // Update customer payment amount when a payment is made
  Future<CustomerModel> updateCustomerPaymentAmount({
    required String customerId,
    required double amount,
  }) async {
    try {
      final customer = await getCustomer(customerId);

      if (customer == null) {
        throw 'Customer not found';
      }

      final updatedCustomer = customer.copyWith(
        totalPaidAmount: customer.totalPaidAmount + amount,
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Update locally
      await _localBox.put(customerId, updatedCustomer);

      // Try to sync with Firestore
      try {
        await _firestore.collection('customers').doc(customerId).update({
          'totalPaidAmount': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mark as synced
        final syncedCustomer = updatedCustomer.copyWith(synced: true);
        await _localBox.put(customerId, syncedCustomer);
        return syncedCustomer;
      } catch (e) {
        // Network error, return unsynced version
        debugPrint('Failed to sync customer payment amount to Firestore: $e');
        return updatedCustomer;
      }
    } catch (e) {
      debugPrint('Error updating customer payment amount: $e');
      throw 'Failed to update customer payment amount: $e';
    }
  }

  // get invoice of the customer
  // Add this method to your CustomerRepository class
  Future<List<InvoiceModel>> getInvoicesForCustomer(String customerId) async {
    try {
      // Get invoices from Firestore if online
      try {
        final snapshot = await _firestore
            .collection('invoices')
            .where('customerId', isEqualTo: customerId)
            .get();

        final invoices = snapshot.docs
            .map((doc) => InvoiceModel.fromFirestore(doc))
            .toList();

        // Save invoices to local storage
        final invoicesBox = await Hive.openBox<InvoiceModel>('invoices');
        for (final invoice in invoices) {
          await invoicesBox.put(invoice.id, invoice);
        }

        return invoices;
      } catch (e) {
        debugPrint('Error getting invoices from Firestore: $e');

        // Try to get from local storage
        final invoicesBox = await Hive.openBox<InvoiceModel>('invoices');
        return invoicesBox.values
            .where((invoice) => invoice.customerId == customerId)
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting invoices for customer: $e');
      return [];
    }
  }

// Override or modify the getCustomer method to include invoices
  Future<CustomerModel?> getCustomer(String id) async {
    try {
      // Check local storage first
      final localCustomer = _localBox.get(id);

      // Try to get from Firestore if online
      try {
        final doc = await _firestore.collection('customers').doc(id).get();

        if (doc.exists) {
          final customer = CustomerModel.fromFirestore(doc);

          // Fetch customer's invoices
          final invoices = await getInvoicesForCustomer(id);

          // Create customer with invoices
          final updatedCustomer = customer.copyWith(invoices: invoices);

          // Update local storage
          await _localBox.put(id, updatedCustomer);
          return updatedCustomer;
        }

        // If not in Firestore but in local storage, fetch latest invoices anyway
        if (localCustomer != null) {
          final invoices = await getInvoicesForCustomer(id);
          final updatedCustomer = localCustomer.copyWith(invoices: invoices);
          await _localBox.put(id, updatedCustomer);
          return updatedCustomer;
        }

        return localCustomer;
      } catch (e) {
        // Network error, return local version if available
        debugPrint('Failed to get customer from Firestore: $e');

        // If we have a local customer, try to add invoices
        if (localCustomer != null) {
          try {
            final invoices = await getInvoicesForCustomer(id);
            final updatedCustomer = localCustomer.copyWith(invoices: invoices);
            await _localBox.put(id, updatedCustomer);
            return updatedCustomer;
          } catch (innerErr) {
            // If we can't get invoices, return customer without them
            return localCustomer;
          }
        }

        return localCustomer;
      }
    } catch (e) {
      debugPrint('Error getting customer: $e');
      throw 'Failed to get customer: $e';
    }
  }

  // In your CustomerRepository class
  Future<List<InvoiceModel>> getCustomerInvoices(String customerId) async {
    try {
      debugPrint('Getting invoices for customer: $customerId');

      // First try to get from local storage (Hive)
      final invoicesBox = await Hive.openBox<InvoiceModel>('invoices');

      // Get all invoices from local storage
      final allLocalInvoices = invoicesBox.values.toList();
      debugPrint(
          'Found ${allLocalInvoices.length} total invoices in local storage');

      // Filter to get only this customer's invoices
      final customerInvoices = allLocalInvoices
          .where((invoice) => invoice.customerId == customerId)
          .toList();

      debugPrint(
          'Found ${customerInvoices.length} invoices for customer in local storage');

      // If we have local invoices, return them
      if (customerInvoices.isNotEmpty) {
        return customerInvoices;
      }

      // Otherwise try to get from Firestore
      try {
        final snapshot = await _firestore
            .collection('invoices')
            .where('customerId', isEqualTo: customerId)
            .get();

        final invoices = snapshot.docs.map((doc) {
          final data = doc.data();
          debugPrint('Found invoice in Firestore: ${doc.id}');

          // Convert timestamp to DateTime
          DateTime? invoiceDate;
          if (data['date'] is Timestamp) {
            invoiceDate = (data['date'] as Timestamp).toDate();
          } else {
            invoiceDate = DateTime.now();
          }

          // Convert items
          List<InvoiceItemModel> items = [];
          if (data['items'] is List) {
            items = (data['items'] as List).map((item) {
              return InvoiceItemModel(
                name: item['name'] ?? '',
                price: (item['price'] ?? 0.0).toDouble(),
                quantity: item['quantity'] ?? 1,
              );
            }).toList();
          }

          return InvoiceModel.create(
            id: doc.id,
            customerId: customerId,
            customerName: data['customerName'] ?? '',
            customerPhone: data['customerPhone'] ?? '',
            customerAddress: data['customerAddress'] ?? '',
            invoiceNumber: data['invoiceNumber'] ?? '',
            date: invoiceDate,
            items: items,
            totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
            createdAt: data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
            status: data['status'] ?? 'issued',
            userId: data['userId'] ?? '',
            paymentStatus: data['paymentStatus'] ?? 'pending',
          );
        }).toList();

        // Save these invoices to local storage for future use
        for (var invoice in invoices) {
          await invoicesBox.put(invoice.id, invoice);
        }

        debugPrint('Retrieved ${invoices.length} invoices from Firestore');
        return invoices;
      } catch (e) {
        debugPrint('Failed to get invoices from Firestore: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getCustomerInvoices: $e');
      return [];
    }
  }
}
