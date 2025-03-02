import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_state.dart';
import 'package:trust_finiance/repos/customer_repo.dart';
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
      appBar: AppBar(
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
      ),
      body: BlocConsumer<CustomerCubit, CustomerState>(
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
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                spacing: 20.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerHeader(context, customer),
                  _buildContactInfo(customer),
                  _buildFinancialInfo(customer),
                  _buildInvoicesList(customer),
                  if (customer.notes != null && customer.notes!.isNotEmpty)
                    _buildNotes(customer),
                ],
              ),
            );
          }

          return Center(
            child: Text('No customer data found'),
          );
        },
      ),
      // Add a bottom button for creating a loan for this customer
      bottomNavigationBar: BlocBuilder<CustomerCubit, CustomerState>(
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
      ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context, customer) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32.r,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                customer.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Customer ID: ${customer.id.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Added on ${_formatDate(customer.createdAt)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(customer) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _infoRow(Icons.phone, 'Phone', customer.phone),
            if (customer.email != null && customer.email!.isNotEmpty)
              _infoRow(Icons.email, 'Email', customer.email!),
            if (customer.address != null && customer.address!.isNotEmpty)
              _infoRow(Icons.location_on, 'Address', customer.address!),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfo(customer) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _financialRow('Total Loans', customer.totalLoanAmount),
            _financialRow('Total Repaid', customer.totalPaidAmount),
            Divider(height: 24.h),
            _financialRow(
              'Outstanding Balance',
              customer.outstandingBalance,
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(customer) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              customer.notes!,
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financialRow(String label, double amount,
      {bool isHighlighted = false}) {
    final textColor = isHighlighted
        ? (amount >= 0 ? Colors.green : Colors.red)
        : Colors.black;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? textColor : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _navigateToEditCustomer(BuildContext context, customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerPage(customer: customer),
      ),
    );
  }

// In your CustomerDetailView class:

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

Widget _buildInvoicesList(customer) {
  // Check if customer has invoices
  final invoices = customer.invoices ?? [];

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoices',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${invoices.length} total',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          invoices.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      'No invoices yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: invoices.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return _buildInvoiceItem(context, invoice);
                  },
                ),
        ],
      ),
    ),
  );
}

Widget _buildInvoiceItem(BuildContext context, invoice) {
  // Calculate if invoice is overdue
  final bool isOverdue =
      invoice.dueDate.isBefore(DateTime.now()) && invoice.status != 'paid';

  // Calculate remaining balance
  final double remainingBalance =
      invoice.totalAmount - (invoice.paidAmount ?? 0);

  return InkWell(
    onTap: () {
      // Navigate to invoice details page
      // Uncomment when you have an invoice detail page
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => InvoiceDetailPage(invoiceId: invoice.id),
      //   ),
      // );
    },
    borderRadius: BorderRadius.circular(8.r),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                _getStatusIcon(invoice.status),
                color: _getStatusColor(invoice.status),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Due: ${_formatDate(invoice.dueDate)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isOverdue ? Colors.red : Colors.grey,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${remainingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: remainingBalance > 0 ? Colors.red : Colors.green,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  _capitalizeFirst(invoice.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _getStatusColor(invoice.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'overdue':
      return Colors.red;
    default:
      return Colors.blue;
  }
}

IconData _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return Icons.check_circle;
    case 'pending':
      return Icons.hourglass_empty;
    case 'overdue':
      return Icons.warning;
    default:
      return Icons.receipt;
  }
}

String _capitalizeFirst(String text) {
  if (text == null || text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1);
}
