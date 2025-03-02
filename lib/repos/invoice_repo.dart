import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:trust_finiance/models/invoice_model.dart';
import 'package:trust_finiance/models/user_model.dart';
import 'package:uuid/uuid.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<InvoiceModel> _localBox;
  final UserModel _currentUser;

  InvoiceRepository({
    required UserModel currentUser,
    Box<InvoiceModel>? localBox,
  })  : _currentUser = currentUser,
        _localBox = localBox ?? Hive.box<InvoiceModel>('invoices');

  // Get all invoices
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      // First check local storage
      final localInvoices = _localBox.values.toList();

      // Then check Firestore
      try {
        final querySnapshot = await _getInvoicesCollection().get();

        for (final doc in querySnapshot.docs) {
          final firestoreInvoice = InvoiceModel.fromFirestore(doc);

          // Check if we already have this invoice locally
          final localIndex = localInvoices
              .indexWhere((local) => local.id == firestoreInvoice.id);

          if (localIndex >= 0) {
            // Update local copy if needed
            final localInvoice = localInvoices[localIndex];
            if (firestoreInvoice.updatedAt.isAfter(localInvoice.updatedAt)) {
              await _localBox.put(firestoreInvoice.id, firestoreInvoice);
              localInvoices[localIndex] = firestoreInvoice;
            }
          } else {
            // Add to local storage
            await _localBox.put(firestoreInvoice.id, firestoreInvoice);
            localInvoices.add(firestoreInvoice);
          }
        }

        // Mark all as synced
        for (final invoice in localInvoices) {
          if (!invoice.synced) {
            await _localBox.put(invoice.id, invoice.copyWith(synced: true));
          }
        }
      } catch (e) {
        debugPrint('Error syncing with Firestore: $e');
        // Continue with local data if Firestore fails
      }

      // Sort by date (newest first)
      localInvoices.sort((a, b) => b.date.compareTo(a.date));
      return localInvoices;
    } catch (e) {
      debugPrint('Error getting invoices: $e');
      throw 'Failed to get invoices: $e';
    }
  }

  // Get invoices for a specific customer
  Future<List<InvoiceModel>> getInvoicesForCustomer(String customerId) async {
    try {
      final allInvoices = await getInvoices();
      return allInvoices
          .where((invoice) => invoice.customerId == customerId)
          .toList();
    } catch (e) {
      debugPrint('Error getting invoices for customer: $e');
      throw 'Failed to get invoices for customer: $e';
    }
  }

  // Add a new invoice
  Future<InvoiceModel> addInvoice({
    required String customerId,
    required String customerName,
    required String customerNumber,
    required String customerAddress,
    required String invoiceNumber,
    required DateTime date,
    required List<InvoiceItemModel> items,
    required double totalAmount,
    String status = 'issued',
  }) async {
    try {
      // Create the new invoice model
      final newInvoice = InvoiceModel(
        id: const Uuid().v4(),
        customerId: customerId,
        customerName: customerName,
        customerNumber: customerNumber,
        customerAddress: customerAddress,
        invoiceNumber: invoiceNumber,
        date: date,
        items: items,
        totalAmount: totalAmount,
        status: status,
        userId: _currentUser.uid,
        paymentStatus: 'pending',
      );

      // Save to local storage first
      await _localBox.put(newInvoice.id, newInvoice);

      // Try to sync with Firestore
      try {
        await _getInvoicesCollection()
            .doc(newInvoice.id)
            .set(newInvoice.toMap());

        // Mark as synced
        final syncedInvoice = newInvoice.copyWith(synced: true);
        await _localBox.put(syncedInvoice.id, syncedInvoice);
        return syncedInvoice;
      } catch (e) {
        debugPrint('Failed to sync new invoice to Firestore: $e');
        // Continue with unsynced invoice
        return newInvoice;
      }
    } catch (e) {
      debugPrint('Error adding invoice: $e');
      throw 'Failed to add invoice: $e';
    }
  }

  // Update invoice status
  Future<InvoiceModel> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    try {
      // Get current invoice from local storage
      final currentInvoice = _localBox.get(id);

      if (currentInvoice == null) {
        throw 'Invoice not found';
      }

      // Create updated invoice
      final updatedInvoice = currentInvoice.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Update locally first
      await _localBox.put(id, updatedInvoice);

      // Try to sync with Firestore
      try {
        await _getInvoicesCollection().doc(id).update({
          'status': status,
          'updatedAt': Timestamp.fromDate(updatedInvoice.updatedAt),
        });

        // Mark as synced
        final syncedInvoice = updatedInvoice.copyWith(synced: true);
        await _localBox.put(id, syncedInvoice);
        return syncedInvoice;
      } catch (e) {
        debugPrint('Failed to sync updated invoice status to Firestore: $e');
        // Continue with unsynced invoice
        return updatedInvoice;
      }
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
      throw 'Failed to update invoice status: $e';
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String id) async {
    try {
      // Remove from local storage first
      await _localBox.delete(id);

      // Then try to remove from Firestore
      try {
        await _getInvoicesCollection().doc(id).delete();
      } catch (e) {
        debugPrint('Failed to delete invoice from Firestore: $e');
        // Continue with local deletion
      }
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      throw 'Failed to delete invoice: $e';
    }
  }

  // Get the Firestore collection reference for invoices
  CollectionReference<Map<String, dynamic>> _getInvoicesCollection() {
    return _firestore
        .collection('users')
        .doc(_currentUser.uid)
        .collection('invoices');
  }
}
