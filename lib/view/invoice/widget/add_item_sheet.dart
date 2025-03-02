import 'package:flutter/material.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/invoice/add_invoice.dart';

class AddItemSheet extends StatefulWidget {
  final Function(InvoiceItem) onItemAdded;
  final InvoiceItem? initialItem;
  final bool editMode;

  const AddItemSheet({
    Key? key,
    required this.onItemAdded,
    this.initialItem,
    this.editMode = false,
  }) : super(key: key);

  @override
  _AddItemSheetState createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  final _priceFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  double _subtotal = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with initial values if in edit mode
    _nameController = TextEditingController(
      text: widget.initialItem?.name ?? '',
    );

    _quantityController = TextEditingController(
      text: widget.initialItem != null
          ? widget.initialItem!.quantity.toString()
          : '1',
    );

    _priceController = TextEditingController(
      text: widget.initialItem != null
          ? widget.initialItem!.price.toString()
          : '',
    );

    // Calculate initial subtotal for edit mode
    _updateSubtotal();

    // Add listeners to update subtotal when values change
    _quantityController.addListener(_updateSubtotal);
    _priceController.addListener(_updateSubtotal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _updateSubtotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _subtotal = quantity * price;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onItemAdded(
        InvoiceItem(
          name: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          price: double.parse(_priceController.text),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _incrementQuantity() {
    final currentValue = int.tryParse(_quantityController.text) ?? 0;
    _quantityController.text = (currentValue + 1).toString();
  }

  void _decrementQuantity() {
    final currentValue = int.tryParse(_quantityController.text) ?? 0;
    if (currentValue > 1) {
      _quantityController.text = (currentValue - 1).toString();
    }
  }

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.editMode ? 'Edit Item' : AppConst.addInvoiceItem,
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppConst.itemName,
                hintText: 'Enter item name',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _quantityFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantity and price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity field with increment/decrement buttons
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    decoration: InputDecoration(
                      labelText: AppConst.quantity,
                      prefixIcon: const Icon(Icons.numbers),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _decrementQuantity,
                            splashRadius: 20,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _incrementQuantity,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _priceFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null) {
                        return 'Invalid number';
                      }
                      if (quantity <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Price field
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    decoration: InputDecoration(
                      labelText: AppConst.price,
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitForm(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Invalid number';
                      }
                      if (price <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // Subtotal display
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${_subtotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Button row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(widget.editMode ? Icons.check : Icons.add),
                  label: Text(widget.editMode ? 'Update Item' : 'Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
