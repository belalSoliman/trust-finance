import 'package:equatable/equatable.dart';
import 'package:trust_finiance/models/invoice_model/invoice_model.dart';

/// Base class for all invoice-related states.
abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the cubit is created.
class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

/// State representing that invoice data is being loaded or processed.
class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
}

/// State emitted when invoices have been successfully loaded.
class InvoiceLoaded extends InvoiceState {
  final List<InvoiceModel> invoices;

  const InvoiceLoaded(this.invoices);

  @override
  List<Object?> get props => [invoices];
}

/// State emitted when a single invoice has been successfully loaded.
class InvoiceSingleLoaded extends InvoiceState {
  final InvoiceModel invoice;

  const InvoiceSingleLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

/// State emitted when an invoice action (create, update, delete) completed successfully.
class InvoiceActionSuccess extends InvoiceState {
  final String message;
  final InvoiceModel? invoice;

  const InvoiceActionSuccess(this.message, [this.invoice]);

  @override
  List<Object?> get props => [message, invoice];
}

/// State representing an error during invoice operations.
class InvoiceError extends InvoiceState {
  final String message;

  const InvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
