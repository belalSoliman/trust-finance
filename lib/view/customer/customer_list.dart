import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_state.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/customer/widget/customer_page_view.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Use post-frame callback to safely access the customer cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Safe method to load customers with error handling
  void _safeLoadCustomers() {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<CustomerCubit>();
      if (!cubit.isClosed) {
        cubit.loadCustomers().then((_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }).catchError((error) {
          debugPrint('Error loading customers: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });
      }
    } catch (e) {
      debugPrint('Error accessing CustomerCubit: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Safe search function with error handling
  void _safeSearch(String query) {
    if (!mounted) return;

    try {
      final cubit = context.read<CustomerCubit>();
      if (!cubit.isClosed) {
        if (query.isEmpty) {
          cubit.loadCustomers();
        } else {
          cubit.searchCustomers(query);
        }
      }
    } catch (e) {
      debugPrint('Error searching customers: $e');
    }
  }

  // Sort function with error handling
  void _safeSortCustomers(
      int Function(CustomerModel, CustomerModel) comparator) {
    try {
      final cubit = context.read<CustomerCubit>();
      if (cubit.isClosed) return;

      final state = cubit.state;
      if (state is CustomerLoaded) {
        List<CustomerModel> sortedList = List.from(state.customers);
        sortedList.sort(comparator);
        cubit.emit(CustomerLoaded(sortedList));
      }
    } catch (e) {
      debugPrint('Error sorting customers: $e');
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort Customers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Name (A-Z)'),
                onTap: () {
                  Navigator.pop(context);
                  _safeSortCustomers((a, b) => a.name.compareTo(b.name));
                },
              ),
              ListTile(
                title: const Text('Balance (High to Low)'),
                onTap: () {
                  Navigator.pop(context);
                  _safeSortCustomers((a, b) =>
                      b.outstandingBalance.compareTo(a.outstandingBalance));
                },
              ),
              ListTile(
                title: const Text('Balance (Low to High)'),
                onTap: () {
                  Navigator.pop(context);
                  _safeSortCustomers((a, b) =>
                      a.outstandingBalance.compareTo(b.outstandingBalance));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                onChanged: _safeSearch,
              ),
            ),

            // Header with sort button
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
                      SizedBox(height: 4.h),
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

            // Customer List - this needs to be in a container with bounded height
            Expanded(
              child: _buildCustomerListContent(state, theme),
            ),
          ],
        );
      },
    );
  }

// Extract the customer list content to a separate method for clarity
  Widget _buildCustomerListContent(CustomerState state, ThemeData theme) {
    if (_isLoading || state is CustomerLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state is CustomerError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // Use min size to avoid expanding unnecessarily
            children: [
              Icon(
                Icons.error_outline,
                size: 48.r,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading customers',
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: _safeLoadCustomers,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    } else if (state is CustomerLoaded && state.customers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // Use min size to avoid expanding unnecessarily
            children: [
              Icon(
                Icons.people_outline,
                size: 48.r,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                'No customers found',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    } else if (state is CustomerLoaded) {
      return ListView.builder(
        itemCount: state.customers.length,
        itemBuilder: (context, index) {
          final customer = state.customers[index];
          return _buildCustomerCard(context, customer);
        },
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailPage(
                customerId: customer.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          customer.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${customer.outstandingBalance.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: customer.outstandingBalance > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Loans: ₹${customer.totalLoanAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
