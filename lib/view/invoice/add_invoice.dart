import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/cubit/invoice_cuibt/invoice_cubit.dart';
import 'package:trust_finiance/cubit/invoice_cuibt/invoice_state.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model.dart';
import 'package:trust_finiance/repos/customer_repo.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/home/widget/add_customer.dart';
import 'package:trust_finiance/view/invoice/widget/add_item_sheet.dart';
import 'package:trust_finiance/view/invoice/widget/connection_checker.dart';
import 'package:trust_finiance/view/invoice/widget/customer_selection_dialog.dart';
import 'package:trust_finiance/view/invoice/widget/invoice_preview.dart';

class CreateInvoicePage extends StatefulWidget {
  // Optional selected customer to pre-fill data
  final CustomerModel? selectedCustomer;

  const CreateInvoicePage({
    super.key,
    this.selectedCustomer,
  });

  @override
  CreateInvoicePageState createState() => CreateInvoicePageState();
}

class CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  final _itemsNotifier = ValueNotifier<List<InvoiceItem>>([]);
  final _totalAmountNotifier = ValueNotifier<double>(0.0);
  final _selectedDateNotifier = ValueNotifier<DateTime>(DateTime.now());
  final _isLoadingNotifier = ValueNotifier<bool>(false);

  // Selected customer for linking
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customersList = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _isOnline = true;

  // Selected customer for linking

  @override
  void initState() {
    super.initState();

    // Generate a unique invoice number
    _invoiceNumberController.text =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // If a customer was passed in, use their info
    if (widget.selectedCustomer != null) {
      _setSelectedCustomer(widget.selectedCustomer!);
    }
    ConnectionChecker.isConnected().then((isConnected) {
      setState(() {
        _isOnline = isConnected;
      });
    });

    // Load customers list
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerNumberController.dispose();
    _invoiceNumberController.dispose();
    _itemsNotifier.dispose();
    _totalAmountNotifier.dispose();
    _selectedDateNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  // Load customers for dropdown selection
  Future<void> _loadCustomers() async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final customerRepository =
            CustomerRepository(currentUser: authState.user);
        final customers = await customerRepository.getCustomers();

        setState(() {
          _customersList = customers;
          _filteredCustomers = customers;
        });
      }
    } catch (e) {
      debugPrint('Error loading customers: $e');
      if (mounted) {
        showErrorSnackBar('Error loading customers: ${_formatError(e)}');
      }
    }
  }

  String _formatError(dynamic error) {
    final errorMsg = error.toString();

    if (errorMsg.contains('network')) {
      return 'Network error. Check your connection.';
    } else if (errorMsg.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorMsg.contains('Provider<InvoiceCubit>')) {
      return 'App error. Please restart the app.';
    }

    return 'An unexpected error occurred.';
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Set form values from selected customer
  void _setSelectedCustomer(CustomerModel customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerNameController.text = customer.name;
      _customerNumberController.text = customer.phone;
      _customerAddressController.text = customer.address ?? '';
    });
  }

  // Update total amount when items change
  void _updateTotal() {
    final items = _itemsNotifier.value;
    final total = items.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity.toDouble()));
    _totalAmountNotifier.value = total;
  }

  // Show bottom sheet to add an item
  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        onItemAdded: (item) {
          final currentItems = List<InvoiceItem>.from(_itemsNotifier.value);
          currentItems.add(item);
          _itemsNotifier.value = currentItems;
          _updateTotal();
        },
      ),
    );
  }

  // Show customer selection dialog

  Future<void> _showCustomerSelectionDialog() async {
    showDialog(
      context: context,
      builder: (context) => CustomerSelectionDialog(
        customers: _customersList,
        onCustomerSelected: (customer) {
          _setSelectedCustomer(customer);
        },
        onCreateNew: () async {
          Navigator.pop(context);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCustomerPage(),
            ),
          );
          if (result is CustomerModel) {
            _setSelectedCustomer(result);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConst.createInvoice,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              return IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                onPressed: isLoading ? null : _saveInvoice,
              );
            },
          ),
        ],
      ),
      body: BlocListener<InvoiceCubit, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceActionSuccess) {
            _isLoadingNotifier.value = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          } else if (state is InvoiceError) {
            _isLoadingNotifier.value = false;
            showErrorSnackBar(state.message);
          }
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, child) {
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : child!;
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline indicator
                  if (!_isOnline)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade800),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'You are offline. Invoice will be saved locally and synced when you\'re back online.',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomerSection(theme),
                        const SizedBox(height: 16),
                        _buildInvoiceDetails(theme),
                        const SizedBox(height: 16),
                        _buildItemsList(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppConst.customerDetails,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12.sp),
                ),
                ElevatedButton.icon(
                  onPressed: _showCustomerSelectionDialog,
                  icon: const Icon(Icons.person_search),
                  label: const Text('Select Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            if (_selectedCustomer != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Chip(
                  label: Text(_selectedCustomer!.name),
                  avatar: const Icon(Icons.person),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() {
                      _selectedCustomer = null;
                    });
                  },
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withOpacity(0.4),
                  side: BorderSide.none,
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: AppConst.customerNameLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Customer name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNumberController,
              decoration: InputDecoration(
                labelText: AppConst.phoneNumberLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty == true ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerAddressController,
              decoration: InputDecoration(
                labelText: AppConst.addressLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.home_outlined),
              ),
              maxLines: 2,
              validator: (value) =>
                  value?.isEmpty == true ? 'Address is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Invoice Details",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12.sp),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoiceNumberController,
                    decoration: InputDecoration(
                      labelText: AppConst.invoiceNumber,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.receipt_outlined),
                    ),
                    validator: (value) => value?.isEmpty == true
                        ? 'Invoice number is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<DateTime>(
                      valueListenable: _selectedDateNotifier,
                      builder: (context, selectedDate, _) {
                        return InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              _selectedDateNotifier.value = date;
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Invoice Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(selectedDate),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConst.item,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<InvoiceItem>>(
              valueListenable: _itemsNotifier,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_cart_outlined,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          AppConst.noItemAddedYet,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('${item.quantity} x ${item.price}'),
                            trailing: Text(
                              '${(item.quantity * item.price).toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            leading: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                final updatedItems =
                                    List<InvoiceItem>.from(items);
                                updatedItems.removeAt(index);
                                _itemsNotifier.value = updatedItems;
                                _updateTotal();
                              },
                            ),
                            onLongPress: () => _editItem(index, item),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),
                    ValueListenableBuilder<double>(
                      valueListenable: _totalAmountNotifier,
                      builder: (context, totalAmount, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppConst.totalAmount,
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              ' ${totalAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Items'),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton.icon(
                          onPressed: _previewInvoice,
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Preview'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editItem(int index, InvoiceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        onItemAdded: (updatedItem) {
          final currentItems = List<InvoiceItem>.from(_itemsNotifier.value);
          currentItems[index] = updatedItem;
          _itemsNotifier.value = currentItems;
          _updateTotal();
        },
        initialItem: item,
        editMode: true,
      ),
    );
  }

  void _previewInvoice() {
    if (_itemsNotifier.value.isEmpty) {
      showErrorSnackBar('Add at least one item before previewing');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => InvoicePreviewDialog(
        customerName: _customerNameController.text,
        customerPhone: _customerNumberController.text,
        customerAddress: _customerAddressController.text,
        invoiceNumber: _invoiceNumberController.text,
        invoiceDate: _selectedDateNotifier.value,
        items: _itemsNotifier.value,
        totalAmount: _totalAmountNotifier.value,
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_itemsNotifier.value.isEmpty) {
        showErrorSnackBar('Please add at least one item');
        return;
      }

      _isLoadingNotifier.value = true;

      try {
        final authState = context.read<AuthCubit>().state;
        if (authState is! Authenticated) {
          throw Exception('User not authenticated');
        }

        // Create invoice items list for model
        final invoiceItems = _itemsNotifier.value
            .map((item) => InvoiceItemModel(
                  name: item.name,
                  quantity: item.quantity,
                  price: item.price,
                ))
            .toList();

        // Pass all required parameters to addInvoice method
        final invoiceCubit = context.read<InvoiceCubit>();
        await invoiceCubit.addInvoice(
          customerId: _selectedCustomer?.id ?? '',
          customerName: _customerNameController.text,
          customerNumber: _customerNumberController.text,
          customerAddress: _customerAddressController.text,
          invoiceNumber: _invoiceNumberController.text,
          date: _selectedDateNotifier.value,
          items: invoiceItems,
          totalAmount: _totalAmountNotifier.value,
          status: 'issued',
        );

        // State handling is now done via BlocListener in the build method
      } catch (e) {
        debugPrint('Error saving invoice: $e');
        _isLoadingNotifier.value = false;

        String errorMessage = 'Error creating invoice';
        if (e.toString().contains('Provider<InvoiceCubit>')) {
          errorMessage = 'Invoice service unavailable. Please restart the app.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Your invoice is saved offline and will sync when online.';
        }

        showErrorSnackBar(errorMessage);
      }
    }
  }
}

class InvoiceItem {
  final String name;
  final int quantity;
  final double price;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };
}
