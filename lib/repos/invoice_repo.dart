import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:trust_finiance/models/invoice_model.dart';
import 'package:trust_finiance/models/user_model.dart';
import 'package:trust_finiance/view/invoice/widget/connection_checker.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing invoices with offline-first capabilities.
/// Handles syncing between local Hive storage and Firestore.
class InvoiceRepository {
  final FirebaseFirestore _firestore;
  final Box<InvoiceModel> _localBox;
  final UserModel _currentUser;
  final bool _enableLogging;

  /// Creates an [InvoiceRepository] with the specified user.
  ///
  /// [currentUser] is required to associate invoices with a specific user.
  /// [localBox] is optional and will default to 'invoices' box if not provided.
  /// [firestore] allows injecting a custom Firestore instance (useful for testing).
  /// [enableLogging] controls whether debug logs are printed.
  InvoiceRepository({
    required UserModel currentUser,
    Box<InvoiceModel>? localBox,
    FirebaseFirestore? firestore,
    bool enableLogging = true,
  })  : _currentUser = currentUser,
        _localBox = localBox ?? Hive.box<InvoiceModel>('invoices'),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _enableLogging = enableLogging;

  /// Logs debug messages if logging is enabled
  void _log(String message) {
    if (_enableLogging) {
      debugPrint('InvoiceRepository: $message');
    }
  }

  /// Get all invoices for the current user, with local-first approach
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      _log('Getting invoices from local storage and syncing with Firestore');
      // First check local storage
      final localInvoices = _localBox.values.toList();
      _log('Found ${localInvoices.length} invoices locally');

      // Then check Firestore
      await _syncInvoicesWithFirestore(localInvoices);

      // Sort by date (newest first)
      localInvoices.sort((a, b) => b.date.compareTo(a.date));
      return localInvoices;
    } catch (e) {
      _log('Error getting invoices: $e');
      throw 'Failed to get invoices: $e';
    }
  }

  /// Syncs local invoices with Firestore data
  Future<void> _syncInvoicesWithFirestore(
      List<InvoiceModel> localInvoices) async {
    try {
      _log('Syncing with Firestore');
      final querySnapshot = await _getInvoicesCollection().get();
      _log('Found ${querySnapshot.docs.length} invoices in Firestore');

      // Process Firestore documents
      for (final doc in querySnapshot.docs) {
        final firestoreInvoice = InvoiceModel.fromFirestore(doc);

        // Check if we already have this invoice locally
        final localIndex = localInvoices
            .indexWhere((local) => local.id == firestoreInvoice.id);

        if (localIndex >= 0) {
          // Update local copy if Firestore version is newer
          final localInvoice = localInvoices[localIndex];
          if (firestoreInvoice.updatedAt.isAfter(localInvoice.updatedAt)) {
            _log(
                'Updating local invoice ${firestoreInvoice.id} with newer Firestore data');
            await _localBox.put(firestoreInvoice.id, firestoreInvoice);
            localInvoices[localIndex] = firestoreInvoice;
          }
        } else {
          // Add new Firestore invoice to local storage
          _log(
              'Adding new invoice ${firestoreInvoice.id} from Firestore to local storage');
          await _localBox.put(firestoreInvoice.id, firestoreInvoice);
          localInvoices.add(firestoreInvoice);
        }
      }

      // Mark all as synced
      await _markInvoicesAsSynced(localInvoices);
    } catch (e) {
      _log('Error syncing with Firestore: $e');
      // Continue with local data if Firestore sync fails
    }
  }

  /// Mark all invoices as synced with Firestore
  Future<void> _markInvoicesAsSynced(List<InvoiceModel> invoices) async {
    for (final invoice in invoices) {
      if (!invoice.synced) {
        _log('Marking invoice ${invoice.id} as synced');
        await _localBox.put(invoice.id, invoice.copyWith(synced: true));
      }
    }
  }

  /// Get invoices for a specific customer
  Future<List<InvoiceModel>> getInvoicesForCustomer(String customerId) async {
    try {
      _log('Getting invoices for customer $customerId');
      final allInvoices = await getInvoices();

      final customerInvoices = allInvoices
          .where((invoice) => invoice.customerId == customerId)
          .toList();

      _log(
          'Found ${customerInvoices.length} invoices for customer $customerId');
      return customerInvoices;
    } catch (e) {
      _log('Error getting invoices for customer: $e');
      throw 'Failed to get invoices for customer: $e';
    }
  }

  /// Add a new invoice
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
      debugPrint(
          'InvoiceRepository: Creating new invoice for customer: $customerName');

      // Generate ID for the invoice
      final id = const Uuid().v4();
      debugPrint('InvoiceRepository: Generated invoice ID: $id');

      // Ensure customerId is not empty
      if (customerId.isEmpty) {
        debugPrint('InvoiceRepository: Warning - customerId is empty!');
      }

      // Create the invoice model with the customer ID
      final invoiceModel = InvoiceModel(
        id: id,
        customerId: customerId, // Ensure this is properly set
        customerName: customerName,
        customerNumber: customerNumber,
        customerAddress: customerAddress,
        invoiceNumber: invoiceNumber,
        date: date,
        items: items,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        synced: false,
        status: status,
        userId: _currentUser.uid,
        paymentStatus: 'pending',
      );

      // Save to local storage
      debugPrint('InvoiceRepository: Saving invoice to local storage');
      await _saveInvoiceLocally(invoiceModel);

      // Try to sync to Firestore if online
      if (await ConnectionChecker.isConnected()) {
        await _syncInvoiceToFirestore(invoiceModel);

        // Also update the customer's invoice count
        await _updateCustomerInvoiceCount(customerId);
      }

      return invoiceModel;
    } catch (e) {
      debugPrint('InvoiceRepository: Error adding invoice: $e');
      rethrow;
    }
  }

  Future<void> _updateCustomerInvoiceCount(String customerId) async {
    if (customerId.isEmpty) return;

    try {
      debugPrint(
          'InvoiceRepository: Updating invoice count for customer: $customerId');

      // Get a reference to the customer document
      final customerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('customers')
          .doc(customerId);

      // Use a transaction to safely update the count
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final customerDoc = await transaction.get(customerRef);

        if (customerDoc.exists) {
          // Get current count or default to 0
          final currentCount = customerDoc.data()?['invoiceCount'] ?? 0;

          // Update the count
          transaction.update(customerRef, {
            'invoiceCount': currentCount + 1,
            'lastInvoiceDate': FieldValue.serverTimestamp(),
          });

          debugPrint(
              'InvoiceRepository: Updated invoice count to ${currentCount + 1}');
        } else {
          debugPrint(
              'InvoiceRepository: Customer document not found: $customerId');
        }
      });
    } catch (e) {
      debugPrint(
          'InvoiceRepository: Error updating customer invoice count: $e');
    }
  }

// Add this method to your InvoiceRepository class

  /// Update an invoice in local storage
  Future<void> _updateInvoiceLocally(InvoiceModel invoice) async {
    try {
      _log('Updating invoice ${invoice.id} in local storage');
      await _localBox.put(invoice.id, invoice);
      _log('Successfully updated invoice in local storage');
    } catch (e) {
      _log('Error updating invoice in local storage: $e');
      throw 'Failed to update invoice locally: $e';
    }
  }

  /// Syncs an invoice to Firestore and marks it as synced if successful
  Future<void> _syncInvoiceToFirestore(InvoiceModel invoice) async {
    try {
      debugPrint(
          'InvoiceRepository: Syncing invoice ${invoice.id} to Firestore');

      // Convert to Map
      final map = invoice.toMap();

      // Log for debugging
      debugPrint('InvoiceRepository: Invoice data for Firestore: $map');

      // Create reference to invoice document in Firestore
      final docRef = _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('invoices')
          .doc(invoice.id);

      // Set the document
      await docRef.set(map);

      // Update the local copy to mark as synced
      final updatedInvoice = invoice.copyWith(synced: true);
      await _updateInvoiceLocally(updatedInvoice);

      debugPrint(
          'InvoiceRepository: Successfully synced invoice ${invoice.id} to Firestore');

      // Important: Also update the customer-invoice relationship
      await _addInvoiceToCustomer(updatedInvoice);
    } catch (e) {
      debugPrint('InvoiceRepository: Error syncing invoice to Firestore: $e');
    }
  }

  Future<void> _addInvoiceToCustomer(InvoiceModel invoice) async {
    if (invoice.customerId!.isEmpty) {
      debugPrint(
          'InvoiceRepository: Warning - customerId is empty, cannot add invoice to customer');
      return;
    }

    try {
      // Reference to the customer document
      final customerRef = _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection('customers')
          .doc(invoice.customerId);

      // Check if customer exists
      final customerDoc = await customerRef.get();

      if (!customerDoc.exists) {
        debugPrint(
            'InvoiceRepository: Customer not found in Firestore, creating reference document');

        // Create basic customer document if it doesn't exist
        await customerRef.set({
          'id': invoice.customerId,
          'name': invoice.customerName,
          'phone': invoice.customerNumber,
          'address': invoice.customerAddress,
          'invoiceCount': 1,
          'lastInvoiceDate': Timestamp.fromDate(invoice.date),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing customer's invoice count and last invoice date
        await customerRef.update({
          'invoiceCount': FieldValue.increment(1),
          'lastInvoiceDate': Timestamp.fromDate(invoice.date),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create or update the customer-invoice relationship
      final invoiceRef = customerRef.collection('invoices').doc(invoice.id);
      await invoiceRef.set({
        'id': invoice.id,
        'invoiceNumber': invoice.invoiceNumber,
        'date': Timestamp.fromDate(invoice.date),
        'totalAmount': invoice.totalAmount,
        'status': invoice.status,
        'paymentStatus': invoice.paymentStatus,
        'createdAt': Timestamp.fromDate(invoice.createdAt),
      });

      debugPrint(
          'InvoiceRepository: Added invoice reference to customer ${invoice.customerId}');
    } catch (e) {
      debugPrint('InvoiceRepository: Error adding invoice to customer: $e');
    }
  }

  /// Update invoice status
  Future<InvoiceModel> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    try {
      _log('Updating invoice $id status to: $status');

      // Get current invoice from local storage
      final currentInvoice = _localBox.get(id);

      if (currentInvoice == null) {
        _log('Invoice not found: $id');
        throw 'Invoice not found';
      }

      // Create updated invoice with new status
      final updatedInvoice = currentInvoice.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Update locally first
      await _localBox.put(id, updatedInvoice);

      // Try to sync with Firestore
      try {
        _log('Syncing updated status to Firestore');
        await _getInvoicesCollection().doc(id).update({
          'status': status,
          'updatedAt': Timestamp.fromDate(updatedInvoice.updatedAt),
        });

        _log('Successfully synced status update to Firestore');

        // Mark as synced
        final syncedInvoice = updatedInvoice.copyWith(synced: true);
        await _localBox.put(id, syncedInvoice);
        return syncedInvoice;
      } catch (e) {
        _log('Failed to sync updated invoice status to Firestore: $e');
        // Return the updated but unsynced invoice
        return updatedInvoice;
      }
    } catch (e) {
      _log('Error updating invoice status: $e');
      throw 'Failed to update invoice status: $e';
    }
  }

  /// Update invoice payment status
  Future<InvoiceModel> updatePaymentStatus({
    required String id,
    required String paymentStatus,
  }) async {
    try {
      _log('Updating invoice $id payment status to: $paymentStatus');

      // Get current invoice from local storage
      final currentInvoice = _localBox.get(id);

      if (currentInvoice == null) {
        _log('Invoice not found: $id');
        throw 'Invoice not found';
      }

      // Create updated invoice with new payment status
      final updatedInvoice = currentInvoice.copyWith(
        paymentStatus: paymentStatus,
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Update locally first
      await _localBox.put(id, updatedInvoice);

      // Try to sync with Firestore
      try {
        _log('Syncing updated payment status to Firestore');
        await _getInvoicesCollection().doc(id).update({
          'paymentStatus': paymentStatus,
          'updatedAt': Timestamp.fromDate(updatedInvoice.updatedAt),
        });

        _log('Successfully synced payment status update to Firestore');

        // Mark as synced
        final syncedInvoice = updatedInvoice.copyWith(synced: true);
        await _localBox.put(id, syncedInvoice);
        return syncedInvoice;
      } catch (e) {
        _log('Failed to sync updated payment status to Firestore: $e');
        // Return the updated but unsynced invoice
        return updatedInvoice;
      }
    } catch (e) {
      _log('Error updating invoice payment status: $e');
      throw 'Failed to update invoice payment status: $e';
    }
  }

  /// Delete an invoice
  Future<void> deleteInvoice(String id) async {
    try {
      _log('Deleting invoice: $id');

      // Remove from local storage first
      await _localBox.delete(id);
      _log('Removed invoice from local storage');

      // Then try to remove from Firestore
      try {
        await _getInvoicesCollection().doc(id).delete();
        _log('Successfully deleted invoice from Firestore');
      } catch (e) {
        _log('Failed to delete invoice from Firestore: $e');
        // Continue with local deletion even if Firestore fails
      }
    } catch (e) {
      _log('Error deleting invoice: $e');
      throw 'Failed to delete invoice: $e';
    }
  }

  /// Get a single invoice by ID
  Future<InvoiceModel?> getInvoiceById(String id) async {
    try {
      _log('Getting invoice by ID: $id');

      // First check local storage
      final localInvoice = _localBox.get(id);

      if (localInvoice != null) {
        _log('Found invoice in local storage');
        return localInvoice;
      }

      // If not in local storage, try Firestore
      try {
        final doc = await _getInvoicesCollection().doc(id).get();

        if (doc.exists) {
          _log('Found invoice in Firestore');
          final invoice = InvoiceModel.fromFirestore(doc);

          // Save to local storage
          await _localBox.put(id, invoice);

          return invoice;
        }
      } catch (e) {
        _log('Error fetching invoice from Firestore: $e');
      }

      _log('Invoice not found');
      return null;
    } catch (e) {
      _log('Error getting invoice by ID: $e');
      throw 'Failed to get invoice: $e';
    }
  }

  /// Perform a full sync of unsynced invoices with Firestore
  Future<void> syncPendingInvoices() async {
    try {
      _log('Syncing pending invoices with Firestore');

      // Get all unsynced invoices
      final unsyncedInvoices =
          _localBox.values.where((invoice) => !invoice.synced).toList();

      _log('Found ${unsyncedInvoices.length} unsynced invoices');

      // Try to sync each one
      for (final invoice in unsyncedInvoices) {
        await _syncInvoiceToFirestore(invoice);
      }

      _log('Completed sync of pending invoices');
    } catch (e) {
      _log('Error syncing pending invoices: $e');
      // Continue even if there are errors
    }
  }

  /// Get the Firestore collection reference for invoices
  CollectionReference<Map<String, dynamic>> _getInvoicesCollection() {
    return _firestore
        .collection('users')
        .doc(_currentUser.uid)
        .collection('invoices');
  }

  /// Disposes resources used by the repository
  void dispose() {
    // Add any cleanup if needed
  }

  /// Save an invoice to local storage
  Future<void> _saveInvoiceLocally(InvoiceModel invoice) async {
    try {
      _log('Saving invoice ${invoice.id} to local storage');
      await _localBox.put(invoice.id, invoice);
      _log('Successfully saved invoice to local storage');
    } catch (e) {
      _log('Error saving invoice to local storage: $e');
      throw 'Failed to save invoice locally: $e';
    }
  }
}
