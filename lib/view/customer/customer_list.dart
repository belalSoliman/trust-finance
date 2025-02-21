import 'package:flutter/material.dart';
import 'package:trust_finiance/view/customer/widget/customer_item.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Example customer data - replace with your actual data source
    final List<Map<String, dynamic>> customers = [
      {
        'name': 'John Doe',
        'address': '123 Main St, City',
        'balance': 1500.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      {
        'name': 'Alice Brown',
        'address': '789 Pine Rd, Village',
        'balance': 200.0,
      },
      {
        'name': 'Bob Johnson',
        'address': '101 Maple St, Hamlet',
        'balance': 300.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      {
        'name': 'Jane Smith',
        'address': '456 Oak Ave, Town',
        'balance': -500.0,
      },
      // Add more customers here
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Customers',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customers.length} total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 26,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  // TODO: Add filter/sort functionality
                },
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return CustomerItem(
              name: customer['name'],
              address: customer['address'],
              balance: customer['balance'],
              onTap: () {
                // TODO: Navigate to customer details
              },
            );
          },
        ),
      ],
    );
  }
}
