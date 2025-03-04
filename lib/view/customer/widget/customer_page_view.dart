import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_state.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/repos/customer_repo.dart';
import 'package:trust_finiance/view/customer/widget/customer_header_card.dart';
import 'package:trust_finiance/view/customer/widget/edit_customer_information.dart';
import 'package:trust_finiance/view/home/home.dart';

class CustomerDetailPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomerCubit(
        customerRepository: CustomerRepository(
          currentUser: (context.read<AuthCubit>().state as Authenticated).user,
        ),
      )..loadCustomerDetails(customerId),
      child: CustomerDetailView(customerId: customerId),
    );
  }
}

class CustomerDetailView extends StatelessWidget {
  final String customerId;

  const CustomerDetailView({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Customer Details',
        style: TextStyle(fontSize: 18.sp),
      ),
      actions: [
        BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            if (state is CustomerDetailLoaded) {
              return IconButton(
                icon: Icon(Icons.edit),
                onPressed: () =>
                    _navigateToEditCustomer(context, state.customer),
              );
            }
            return const SizedBox();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8.w),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<CustomerCubit, CustomerState>(
      listener: (context, state) {
        if (state is CustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is CustomerActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );

          // If customer was deleted, go back
          if (state.message.contains('deleted')) {
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerDetailLoaded) {
          final customer = state.customer;
          return _buildCustomerContent(context, customer);
        }

        return Center(
          child: Text('No customer data found'),
        );
      },
    );
  }

  Widget _buildCustomerContent(BuildContext context, CustomerModel customer) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerHeaderCard(customer: customer),
          SizedBox(height: 16.h),
          CustomerContactCard(customer: customer),
          SizedBox(height: 16.h),
          CustomerFinancialCard(customer: customer),
          SizedBox(height: 16.h),
          SizedBox(height: 16.h),
          Builder(builder: (context) {
            debugPrint(
                'Rendering CustomerInvoicesCard with ${customer.invoices?.length ?? 0} invoices');
            return CustomerInvoicesCard(customer: customer);
          }),
          if (customer.notes != null && customer.notes!.isNotEmpty)
            CustomerNotesCard(customer: customer),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerDetailLoaded) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                // Navigate to create loan page
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => CreateLoanPage(customerId: customerId),
                //   ),
                // );
              },
              child: Text(
                'Add New Loan',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _navigateToEditCustomer(BuildContext context, CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerPage(customer: customer),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final String customerIdToDelete = customerId;
    final customerCubit = context.read<CustomerCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Close confirmation dialog
              Navigator.pop(dialogContext);

              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Delete customer
                debugPrint(
                    'Calling deleteCustomer for ID: $customerIdToDelete');
                await customerCubit.deleteCustomer(customerIdToDelete);
                debugPrint('Customer deletion completed successfully');

                // Close loading indicator
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                // First notify the home page to refresh BEFORE navigation
                try {
                  Home.refreshCustomerList();
                  debugPrint('Refresh triggered before navigation');
                } catch (e) {
                  debugPrint('Error refreshing list: $e');
                }

                // Then return to previous screen with a short delay to ensure refresh is triggered
                await Future.delayed(const Duration(milliseconds: 100));
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);

                  // Show success snackbar after navigation completes
                  await Future.delayed(const Duration(milliseconds: 100));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Customer deleted successfully')),
                  );
                }
              } catch (e) {
                debugPrint('Error in _confirmDelete: $e');

                // Close loading dialog
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                // Show error message
                final errorMessage = e.toString();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting customer: ${errorMessage.length > 100 ? '${errorMessage.substring(0, 100)}...' : errorMessage}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
