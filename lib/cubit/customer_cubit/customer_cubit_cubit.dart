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
  Future<void> loadCustomerDetails(String id) async {
    try {
      emit(const CustomerLoading());
      final customer = await _customerRepository.getCustomer(id);

      if (customer != null) {
        emit(CustomerDetailLoaded(customer));
      } else {
        emit(const CustomerError('Customer not found'));
      }
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  // Add a new customer
  Future<void> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      emit(CustomerLoading());

      final customer = await _customerRepository.addCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );

      emit(CustomerActionSuccess('Customer $name added successfully'));

      // Important: Load the updated customer list immediately
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
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
  Future<void> deleteCustomer(String id) async {
    try {
      emit(const CustomerLoading());
      await _customerRepository.deleteCustomer(id);

      emit(const CustomerActionSuccess('Customer deactivated successfully'));
      loadCustomers(); // Reload the customer list
    } catch (e) {
      emit(CustomerError(e.toString()));
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
}
