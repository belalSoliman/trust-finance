import 'package:flutter/material.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/view/home/widget/add_customer.dart';

enum PaymentMethod {
  vodafoneCash(AppConst.vodafoneCash, Icons.phone_android_outlined),
  instaPay(AppConst.instaPay, Icons.payment_outlined),
  direct(AppConst.directPayment, Icons.money_outlined);

  final String label;
  final IconData icon;
  const PaymentMethod(this.label, this.icon);
}

class AddPaymentPage extends StatefulWidget {
  const AddPaymentPage({super.key});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  PaymentMethod _selectedMethod = PaymentMethod.direct;
  Map<String, dynamic>? _selectedCustomer;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Dummy data - Replace with actual database query
  final List<Map<String, dynamic>> _customers = [];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNewCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomerPage()),
    );

    if (result != null) {
      setState(() {
        _customers.add(result);
        _selectedCustomer = result;
      });
    }
  }

  void _savePayment() {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      final payment = {
        'customerId': _selectedCustomer!['id'],
        'customerName': _selectedCustomer!['name'],
        'amount': double.parse(_amountController.text),
        'paymentMethod': _selectedMethod.name,
        'note': _noteController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };
      Navigator.pop(context, payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConst.addpayment,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _savePayment,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerSection(theme),
              const SizedBox(height: 16),
              _buildPaymentSection(theme),
            ],
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
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewCustomer,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text(AppConst.addCustomer),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedCustomer,
              decoration: InputDecoration(
                labelText: AppConst.selectCustomer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: _customers.map((customer) {
                return DropdownMenuItem(
                  value: customer,
                  child: Text(customer['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCustomer = value);
              },
              validator: (value) =>
                  value == null ? AppConst.selectCustomer : null,
            ),
            if (_selectedCustomer != null) ...[
              const SizedBox(height: 16),
              _buildCustomerInfo(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: Text(_selectedCustomer![AppConst.phoneNumberLabel]),
          dense: true,
        ),
        ListTile(
          leading: const Icon(Icons.store_outlined),
          title: Text(_selectedCustomer![AppConst.storeNameLabel]),
          dense: true,
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(_selectedCustomer![AppConst.addressLabel]),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildPaymentSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConst.paymentDetails,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: AppConst.paymentAmount,
                prefixIcon: const Icon(Icons.attach_money_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConst.pleaseEnterAmount;
                }
                if (double.tryParse(value) == null) {
                  return AppConst.pleaseEnterValidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              AppConst.paymentMethod,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PaymentMethod.values.map((method) {
                return ChoiceChip(
                  label: Text(method.label),
                  selected: _selectedMethod == method,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMethod = method);
                    }
                  },
                  avatar: Icon(
                    method.icon,
                    size: 18,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: AppConst.note,
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
