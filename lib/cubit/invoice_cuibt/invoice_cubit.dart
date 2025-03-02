import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:trust_finiance/cubit/invoice_cuibt/invoice_state.dart';
import 'package:trust_finiance/models/invoice_model.dart';
import 'package:trust_finiance/repos/invoice_repo.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final InvoiceRepository _invoiceRepository;

  InvoiceCubit({
    required InvoiceRepository invoiceRepository,
  })  : _invoiceRepository = invoiceRepository,
        super(const InvoiceInitial());

  // Load all invoices
  Future<void> loadInvoices() async {
    try {
      emit(const InvoiceLoading());
      final invoices = await _invoiceRepository.getInvoices();
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      debugPrint('Error in InvoiceCubit.loadInvoices: $e');
      emit(InvoiceError(e.toString()));
    }
  }

  // Load invoices for a specific customer
  Future<void> loadInvoicesForCustomer(String customerId) async {
    try {
      emit(const InvoiceLoading());
      final invoices =
          await _invoiceRepository.getInvoicesForCustomer(customerId);
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      debugPrint('Error in InvoiceCubit.loadInvoicesForCustomer: $e');
      emit(InvoiceError(e.toString()));
    }
  }

  // Add a new invoice
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
      emit(InvoiceLoading());

      // This may be calling a method that isn't properly syncing with Firestore
      await invoiceRepository.addInvoice(
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

      // Success message is emitted here, but actual operation might have failed
      emit(InvoiceActionSuccess('Invoice created successfully'));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  // Update invoice status
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

      // Reload all invoices to update the list
      final invoices = await _invoiceRepository.getInvoices();

      emit(InvoiceActionSuccess('Invoice status updated', invoice));
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      debugPrint('Error in InvoiceCubit.updateInvoiceStatus: $e');
      emit(InvoiceError(e.toString()));
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String id) async {
    try {
      emit(const InvoiceLoading());

      await _invoiceRepository.deleteInvoice(id);

      // Reload all invoices to update the list
      final invoices = await _invoiceRepository.getInvoices();

      emit(const InvoiceActionSuccess('Invoice deleted successfully'));
      emit(InvoiceLoaded(invoices));
    } catch (e) {
      debugPrint('Error in InvoiceCubit.deleteInvoice: $e');
      emit(InvoiceError(e.toString()));
    }
  }
}
