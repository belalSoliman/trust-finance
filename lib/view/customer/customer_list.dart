import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_state.dart';
import 'package:trust_finiance/models/customer_model.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/customer/widget/customer_item.dart';
import 'package:trust_finiance/view/customer/widget/customer_page_view.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load customers when the widget is first created
    context.read<CustomerCubit>().loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CustomerCubit, CustomerState>(
      listener: (context, state) {
        if (state is CustomerError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is CustomerActionSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                onChanged: (query) {
                  if (query.isEmpty) {
                    context.read<CustomerCubit>().loadCustomers();
                  } else {
                    context.read<CustomerCubit>().searchCustomers(query);
                  }
                },
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConst.allCustomer,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Show customer count when loaded
                      if (state is CustomerLoaded)
                        Text(
                          '${state.customers.length} total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: _showSortDialog,
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Customer list
            if (state is CustomerLoading)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (state is CustomerLoaded)
              _buildCustomerList(state.customers)
            else if (state is CustomerError)
              Center(
                child: Text('Error: ${state.message}'),
              )
            else if (state is CustomerInitial)
              Center(
                child: Text('No customers yet'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerList(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off,
                size: 64.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 16.h),
              Text(
                'No customers found',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add your first customer by tapping the + button',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerItem(
          name: customer.name,
          phone: customer.phone,
          address: customer.address ?? 'No address',
          balance: customer.outstandingBalance,
          onTap: () => _navigateToCustomerDetails(customer),
        );
      },
    );
  }

  void _navigateToCustomerDetails(CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailPage(customerId: customer.id),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sort Customers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Name (A-Z)'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting logic
                  if (context.read<CustomerCubit>().state is CustomerLoaded) {
                    List<CustomerModel> sortedList = List.from(
                        (context.read<CustomerCubit>().state as CustomerLoaded)
                            .customers);
                    sortedList.sort((a, b) => a.name.compareTo(b.name));
                    context
                        .read<CustomerCubit>()
                        .emit(CustomerLoaded(sortedList));
                  }
                },
              ),
              ListTile(
                title: Text('Balance (High to Low)'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting logic
                  if (context.read<CustomerCubit>().state is CustomerLoaded) {
                    List<CustomerModel> sortedList = List.from(
                        (context.read<CustomerCubit>().state as CustomerLoaded)
                            .customers);
                    sortedList.sort((a, b) =>
                        b.outstandingBalance.compareTo(a.outstandingBalance));
                    context
                        .read<CustomerCubit>()
                        .emit(CustomerLoaded(sortedList));
                  }
                },
              ),
              ListTile(
                title: Text('Balance (Low to High)'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting logic
                  if (context.read<CustomerCubit>().state is CustomerLoaded) {
                    List<CustomerModel> sortedList = List.from(
                        (context.read<CustomerCubit>().state as CustomerLoaded)
                            .customers);
                    sortedList.sort((a, b) =>
                        a.outstandingBalance.compareTo(b.outstandingBalance));
                    context
                        .read<CustomerCubit>()
                        .emit(CustomerLoaded(sortedList));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
