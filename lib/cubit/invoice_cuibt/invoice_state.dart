import 'package:equatable/equatable.dart';
import 'package:trust_finiance/models/invoice_model.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object> get props => [];
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceModel> invoices;

  const InvoiceLoaded(this.invoices);

  @override
  List<Object> get props => [invoices];
}

class InvoiceError extends InvoiceState {
  final String message;

  const InvoiceError(this.message);

  @override
  List<Object> get props => [message];
}

class InvoiceActionSuccess extends InvoiceState {
  final String message;
  final InvoiceModel? invoice;

  const InvoiceActionSuccess(this.message, [this.invoice]);

  @override
  List<Object> get props => [message]; // Only include non-nullable values

  // Override equality to account for the nullable invoice
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceActionSuccess &&
        other.message == message &&
        other.invoice == invoice;
  }

  @override
  int get hashCode => message.hashCode ^ (invoice?.hashCode ?? 0);
}
