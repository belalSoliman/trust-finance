import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:trust_finiance/cubit/invoice_cuibt/invoice_state.dart';
import 'package:trust_finiance/models/invoice_model/invoice_model.dart';
import 'package:trust_finiance/repos/invoice_repo.dart';

/// Cubit for managing invoice-related state and operations.
///
/// This cubit handles operations like loading, creating, updating, and deleting invoices,
/// with proper state transitions to reflect the current operation status.
class InvoiceCubit extends Cubit<InvoiceState> {
  final InvoiceRepository _invoiceRepository;

  /// Creates an instance of [InvoiceCubit] with a required invoice repository.
  ///
  /// The repository is used to perform all data operations related to invoices.
  InvoiceCubit({
    required InvoiceRepository invoiceRepository,
  })  : _invoiceRepository = invoiceRepository,
        super(const InvoiceInitial());

  /// Loads all invoices for the current user.
  ///
  /// Emits [InvoiceLoading] while loading, then either [InvoiceLoaded]
  /// with the loaded invoices, or [InvoiceError] if loading fails.
  Future<void> loadInvoices() async {
    try {
      emit(const InvoiceLoading());
      final invoices = await _invoiceRepository.getInvoices();

      if (!isClosed) {
        emit(InvoiceLoaded(invoices));
      }
    } catch (e) {
      _handleError('loadInvoices', e);
    }
  }

  /// Loads invoices for a specific customer.
  ///
  /// [customerId] The ID of the customer whose invoices should be loaded.
  Future<void> loadInvoicesForCustomer(String customerId) async {
    try {
      emit(const InvoiceLoading());
      final invoices =
          await _invoiceRepository.getInvoicesForCustomer(customerId);

      if (!isClosed) {
        emit(InvoiceLoaded(invoices));
      }
    } catch (e) {
      _handleError('loadInvoicesForCustomer', e);
    }
  }

  /// Adds a new invoice.
  ///
  /// This method creates a new invoice with the provided details and emits
  /// appropriate states to reflect the operation's progress and result.
  Future<void> addInvoice({
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
      emit(const InvoiceLoading());

      final invoice = await _invoiceRepository.addInvoice(
        customerId: customerId,
        customerName: customerName,
        customerNumber: customerNumber,
        customerAddress: customerAddress,
        invoiceNumber: invoiceNumber,
        date: date,
        items: items,
        totalAmount: totalAmount,
        status: status,
      );

      if (!isClosed) {
        // Emit success state with the created invoice
        emit(InvoiceActionSuccess('Invoice created successfully', invoice));
      }

      // Reload the list of invoices to include the new one
      await loadInvoices();
    } catch (e) {
      _handleError('addInvoice', e);
    }
  }

  /// Updates the status of an existing invoice.
  ///
  /// [id] The ID of the invoice to update.
  /// [status] The new status for the invoice.
  Future<void> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    try {
      emit(const InvoiceLoading());

      final invoice = await _invoiceRepository.updateInvoiceStatus(
        id: id,
        status: status,
      );

      if (!isClosed) {
        // Emit success with the updated invoice
        emit(InvoiceActionSuccess('Invoice status updated', invoice));

        // Reload all invoices to update the list
        await loadInvoices();
      }
    } catch (e) {
      _handleError('updateInvoiceStatus', e);
    }
  }

  /// Updates the payment status of an existing invoice.
  ///
  /// [id] The ID of the invoice to update.
  /// [paymentStatus] The new payment status for the invoice.
  Future<void> updatePaymentStatus({
    required String id,
    required String paymentStatus,
  }) async {
    try {
      emit(const InvoiceLoading());

      final invoice = await _invoiceRepository.updatePaymentStatus(
        id: id,
        paymentStatus: paymentStatus,
      );

      if (!isClosed) {
        // Emit success with the updated invoice
        emit(InvoiceActionSuccess('Payment status updated', invoice));

        // Reload all invoices to update the list
        await loadInvoices();
      }
    } catch (e) {
      _handleError('updatePaymentStatus', e);
    }
  }

  /// Deletes an invoice.
  ///
  /// [id] The ID of the invoice to delete.
  Future<void> deleteInvoice(String id) async {
    try {
      emit(const InvoiceLoading());

      await _invoiceRepository.deleteInvoice(id);

      if (!isClosed) {
        emit(const InvoiceActionSuccess('Invoice deleted successfully'));

        // Reload all invoices to update the list
        await loadInvoices();
      }
    } catch (e) {
      _handleError('deleteInvoice', e);
    }
  }

  /// Gets a single invoice by ID.
  ///
  /// [id] The ID of the invoice to fetch.
  /// Returns the invoice or null if not found.
  Future<void> getInvoiceById(String id) async {
    try {
      emit(const InvoiceLoading());

      final invoice = await _invoiceRepository.getInvoiceById(id);

      if (!isClosed) {
        if (invoice != null) {
          emit(InvoiceSingleLoaded(invoice));
        } else {
          emit(const InvoiceError('Invoice not found'));
        }
      }
    } catch (e) {
      _handleError('getInvoiceById', e);
    }
  }

  /// Forces a sync of any pending (unsynced) invoices with Firestore.
  ///
  /// This is useful when coming back online after being offline.
  Future<void> syncPendingInvoices() async {
    try {
      emit(const InvoiceLoading());

      await _invoiceRepository.syncPendingInvoices();

      if (!isClosed) {
        emit(const InvoiceActionSuccess('Invoices synced successfully'));

        // Reload invoices to get the updated sync status
        await loadInvoices();
      }
    } catch (e) {
      _handleError('syncPendingInvoices', e);
    }
  }

  /// Helper method to handle errors consistently.
  ///
  /// [operation] The name of the operation that failed, for logging.
  /// [error] The error that occurred.
  void _handleError(String operation, dynamic error) {
    debugPrint('Error in InvoiceCubit.$operation: $error');
    if (!isClosed) {
      emit(InvoiceError(error.toString()));
    }
  }
}
