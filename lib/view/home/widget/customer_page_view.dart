import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailsPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer['name'],
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCustomerInfo(theme),
            _buildInvoiceList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              icon: Icons.store_outlined,
              label: 'Store Name',
              value: customer['storeName'],
            ),
            _buildInfoRow(
              theme,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: customer['phone'],
            ),
            _buildInfoRow(
              theme,
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: customer['address'],
            ),
            _buildBalanceCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    final isPositive = customer['balance'] >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive
            ? theme.colorScheme.primary.withValues(alpha: 26)
            : theme.colorScheme.error.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive
              ? theme.colorScheme.primary.withValues(alpha: 51)
              : theme.colorScheme.error.withValues(alpha: 51),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Current Balance',
            style: theme.textTheme.titleMedium,
          ),
          Text(
            'EGP ${customer['balance'].abs().toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isPositive ? Colors.white : theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(ThemeData theme) {
    // Replace with actual invoice data from database
    final List<Map<String, dynamic>> invoices = [];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Invoice History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (invoices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No invoices yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 153),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (context, index) => Divider(
                color: theme.colorScheme.outline.withValues(alpha: 26),
              ),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return ListTile(
                  title: Text(
                    'Invoice #${invoice['number']}',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(invoice['date']),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 153),
                    ),
                  ),
                  trailing: Text(
                    'EGP ${invoice['amount'].toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // Navigate to invoice details
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 153),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 153),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
