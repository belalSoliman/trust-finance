import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/cubit/invoice_cuibt/invoice_cubit.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model.dart';
import 'package:trust_finiance/repos/customer_repo.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/home/widget/add_customer.dart';
import 'package:uuid/uuid.dart';

class CreateInvoicePage extends StatefulWidget {
  // Optional selected customer to pre-fill data
  final CustomerModel? selectedCustomer;

  const CreateInvoicePage({
    super.key,
    this.selectedCustomer,
  });

  @override
  _CreateInvoicePageState createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  DateTime? _selectedDate = DateTime.now();
  final List<InvoiceItem> _items = [];
  double _totalAmount = 0.0;
  bool _isLoading = false;

  // Selected customer for linking
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customersList = [];
  bool _isSearching = false;

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

    // Load customers list
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerNumberController.dispose();
    _invoiceNumberController.dispose();
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
        });
      }
    } catch (e) {
      debugPrint('Error loading customers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
      );
    }
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
    setState(() {
      _totalAmount =
          _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  // Show bottom sheet to add an item
  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddItemSheet(
        onItemAdded: (item) {
          setState(() {
            _items.add(item);
            _updateTotal();
          });
        },
      ),
    );
  }

  // Show customer selection dialog

  Future<void> _showCustomerSelectionDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Customer'),
              content: SizedBox(
                width: 10.w,
                height: MediaQuery.of(context).size.height *
                    0.5, // Constrain height
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search customers',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _isSearching = value.isNotEmpty;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Customer list - use Expanded to constrain list size
                    Expanded(
                      child: _customersList.isEmpty
                          ? const Center(child: Text('No customers found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _customersList.length,
                              itemBuilder: (context, index) {
                                final customer = _customersList[index];
                                return ListTile(
                                  title: Text(customer.name),
                                  subtitle: Text(customer.phone),
                                  onTap: () {
                                    _setSelectedCustomer(customer);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
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
                  child: const Text('Create New Customer'),
                ),
              ],
            );
          },
        );
      },
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
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _isLoading ? null : _saveInvoice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
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
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppConst.addInvoiceItem),
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
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNumberController,
              decoration: InputDecoration(
                labelText: AppConst.phoneNumberLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerAddressController,
              decoration: InputDecoration(
                labelText: AppConst.addressLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
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
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Invoice Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate!),
                        style: theme.textTheme.bodyLarge,
                      ),
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
            if (_items.isEmpty)
              Center(
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
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} x \₹${item.price}'),
                    trailing: Text(
                      '\₹${(item.quantity * item.price).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                          _updateTotal();
                        });
                      },
                    ),
                  );
                },
              ),
            if (_items.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConst.totalAmount,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '\₹${_totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authState = context.read<AuthCubit>().state;
        if (authState is! Authenticated) {
          throw Exception('User not authenticated');
        }

        // Create invoice items list for model
        final invoiceItems = _items
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
          date: _selectedDate!,
          items: invoiceItems,
          totalAmount: _totalAmount,
          status: 'issued',
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );

        // Return to previous screen
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving invoice: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invoice: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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

class _AddItemSheet extends StatefulWidget {
  final Function(InvoiceItem) onItemAdded;

  const _AddItemSheet({required this.onItemAdded});

  @override
  _AddItemSheetState createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppConst.addInvoiceItem,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: AppConst.itemName),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration:
                        const InputDecoration(labelText: AppConst.quantity),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final quantity = int.tryParse(value!);
                      if (quantity == null || quantity <= 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration:
                        const InputDecoration(labelText: AppConst.price),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onItemAdded(
                    InvoiceItem(
                      name: _nameController.text,
                      quantity: int.parse(_quantityController.text),
                      price: double.parse(_priceController.text),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(AppConst.addInvoiceItem),
            ),
          ],
        ),
      ),
    );
  }
}
