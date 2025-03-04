import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_state.dart';
import 'package:trust_finiance/repos/customer_repo.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository _customerRepository;

  CustomerCubit({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(const CustomerInitial());

  // Load all customers
  Future<void> loadCustomers() async {
    try {
      emit(const CustomerLoading());
      final customers = await _customerRepository.getCustomers();
      // Filter to only show active customers
      final activeCustomers = customers.where((c) => c.isActive).toList();
      emit(CustomerLoaded(activeCustomers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  // Get customer details

  // Add a new customer
  Future<void> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    if (isClosed) return;

    try {
      emit(const CustomerLoading());

      await _customerRepository.addCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );

      if (!isClosed) {
        emit(CustomerActionSuccess('Customer $name added successfully'));

        // Don't try to load customers here, as that may cause the error
        // Instead we'll use the ValueNotifier approach
      }
    } catch (e) {
      if (!isClosed) {
        emit(CustomerError(e.toString()));
      }
    }
  }

  // Update customer details
  Future<void> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    try {
      emit(const CustomerLoading());
      final updatedCustomer = await _customerRepository.updateCustomer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        isActive: isActive,
      );

      emit(CustomerActionSuccess(
          'Customer ${updatedCustomer.name} updated successfully'));
      loadCustomerDetails(id); // Reload the customer details
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  // Delete customer (soft delete)
  // In your CustomerCubit class
  Future<void> deleteCustomer(String id) async {
    if (isClosed) {
      debugPrint('Cannot delete: CustomerCubit is already closed');
      return;
    }

    try {
      emit(const CustomerLoading());
      debugPrint('Attempting to delete customer with ID: $id');

      await _customerRepository.deleteCustomer(id);
      debugPrint('Customer successfully deleted from Firebase: $id');

      if (!isClosed) {
        emit(const CustomerActionSuccess('Customer deleted successfully'));
      }
    } catch (e) {
      debugPrint('Error in CustomerCubit.deleteCustomer: $e');
      if (!isClosed) {
        emit(CustomerError(e.toString()));
      }
      throw e; // Re-throw to let the UI handle it
    }
  }

  // Hard delete customer (for admins)
  Future<void> permanentlyDeleteCustomer(String id) async {
    try {
      emit(const CustomerLoading());
      await _customerRepository.permanentlyDeleteCustomer(id);

      emit(const CustomerActionSuccess('Customer permanently deleted'));
      loadCustomers(); // Reload the customer list
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  // Search customers
  Future<void> searchCustomers(String query) async {
    try {
      emit(const CustomerLoading());

      if (query.isEmpty) {
        loadCustomers(); // If query is empty, load all customers
        return;
      }

      final results = await _customerRepository.searchCustomers(query);
      emit(CustomerLoaded(results.where((c) => c.isActive).toList()));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  // Sync unsynced customers
  Future<void> syncCustomers() async {
    try {
      await _customerRepository.syncUnsyncedCustomers();
      // Don't change state, just sync in the background
    } catch (e) {
      // Maybe show a temporary notification/toast but don't disrupt the UI
      print('Failed to sync customers: $e');
    }
  }

  // Get customer details with invoices
  // Get customer details with invoices
  Future<void> loadCustomerDetails(String id) async {
    try {
      emit(const CustomerLoading());

      debugPrint('Loading customer details for ID: $id');
      final customer = await _customerRepository.getCustomer(id);

      if (customer == null) {
        emit(CustomerError('Customer not found'));
        return;
      }

      // Load customer's invoices - make sure this method exists in your repository
      debugPrint('Loading invoices for customer ID: $id');
      final invoices = await _customerRepository.getCustomerInvoices(id);

      // Create updated customer with invoices
      final customerWithInvoices = customer.copyWith(invoices: invoices);

      debugPrint('Found ${invoices.length} invoices for customer');
      emit(CustomerDetailLoaded(customerWithInvoices));
    } catch (e) {
      debugPrint('Error loading customer details: $e');
      emit(CustomerError(e.toString()));
    }
  }

  // Add this to your CustomerCubit
  Future<void> refreshInvoices(String customerId) async {
    try {
      debugPrint('Refreshing invoices for customer: $customerId');

      // Force reload invoices from repository
      final invoices =
          await _customerRepository.getCustomerInvoices(customerId);

      // Get current state
      if (state is CustomerDetailLoaded) {
        final currentState = state as CustomerDetailLoaded;
        final customer = currentState.customer;

        // Update customer with new invoices
        final updatedCustomer = customer.copyWith(invoices: invoices);

        debugPrint('Found ${invoices.length} invoices after refresh');
        emit(CustomerDetailLoaded(updatedCustomer));
      } else {
        // If not in detail view, just load full customer details
        loadCustomerDetails(customerId);
      }
    } catch (e) {
      debugPrint('Error refreshing invoices: $e');
      // Don't change state on error to avoid disrupting the UI
    }
  }
}
