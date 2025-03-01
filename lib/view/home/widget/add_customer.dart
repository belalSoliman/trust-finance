import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_state.dart';
import 'package:trust_finiance/repos/customer_repo.dart';
import 'package:trust_finiance/utils/constant/app_const.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_state.dart';
import 'package:trust_finiance/view/home/home.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Add email controller
  final _notesController = TextEditingController(); // Add notes controller

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Provide the CustomerCubit
    return BlocProvider(
      create: (context) => CustomerCubit(
        customerRepository: CustomerRepository(
          currentUser: (context.read<AuthCubit>().state as Authenticated).user,
        ),
      ),
      child: BlocConsumer<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (state is CustomerActionSuccess) {
            Home.refreshCustomerList();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context); // Go back after successful save
          }

          if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                AppConst.addCustomer,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              actions: [
                if (state is CustomerLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save_rounded),
                    onPressed: () => _saveCustomer(context),
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
                    _buildCustomerCard(theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveCustomer(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Add debug log
      print('Saving customer: ${_nameController.text}');

      // Use the CustomerCubit to add the customer
      context.read<CustomerCubit>().addCustomer(
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            address: _addressController.text.isEmpty
                ? null
                : _addressController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
    }
  }

  Widget _buildCustomerCard(ThemeData theme) {
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
              AppConst.customerInformation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: AppConst.customerNameLabel,
              icon: Icons.person_outline_rounded,
              theme: theme,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: AppConst.phoneNumberLabel,
              icon: Icons.phone_outlined,
              theme: theme,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: "Email Address",
              icon: Icons.email_outlined,
              theme: theme,
              keyboardType: TextInputType.emailAddress,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: AppConst.addressLabel,
              icon: Icons.location_on_outlined,
              theme: theme,
              maxLines: 3,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: "Additional Notes",
              icon: Icons.note_outlined,
              theme: theme,
              maxLines: 3,
              isRequired: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? "$label *" : label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
