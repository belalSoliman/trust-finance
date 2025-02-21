import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  _CreateInvoicePageState createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  final List<InvoiceItem> _items = [];
  double _totalAmount = 0.0;

  void _updateTotal() {
    setState(() {
      _totalAmount =
          _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Invoice',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
        label: const Text('Add Item'),
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
            Text(
              'Customer Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
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
                labelText: 'Customer Number',
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
                labelText: 'Address',
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
                      labelText: 'Invoice #',
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
                  child: Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                    style: theme.textTheme.bodyLarge,
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
              'Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              Center(
                child: Text(
                  'No items added yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
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
                    subtitle: Text('${item.quantity} x \$${item.price}'),
                    trailing: Text(
                      '\$${(item.quantity * item.price).toStringAsFixed(2)}',
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
                    'Total',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '\$${_totalAmount.toStringAsFixed(2)}',
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

  void _saveInvoice() {
    if (_formKey.currentState!.validate()) {
      final invoice = {
        'customerName': _customerNameController.text,
        'customerNumber': _customerNumberController.text,
        'customerAddress': _customerAddressController.text,
        'invoiceNumber': _invoiceNumberController.text,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'items': _items.map((item) => item.toMap()).toList(),
        'total': _totalAmount,
      };
      Navigator.pop(context, invoice);
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
              'Add Item',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
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
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
