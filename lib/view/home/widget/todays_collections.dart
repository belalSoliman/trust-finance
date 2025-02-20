import 'package:flutter/material.dart';
import 'package:trust_finiance/view/home/widget/customer_collection_day_item.dart';

class TodaysCollections extends StatelessWidget {
  const TodaysCollections({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> customers = [
      {'name': 'John Doe', 'amount': 1000, 'id': '1'},
      {'name': 'Jane Doe', 'amount': -2000, 'id': '2'},
      {'name': 'Alice', 'amount': 3000, 'id': '3'},
      {'name': 'Bob', 'amount': -4000, 'id': '4'},
      {'name': 'Charlie', 'amount': 5000, 'id': '5'},
      {'name': 'David', 'amount': 6000, 'id': '6'},
      {'name': 'Eve', 'amount': -7000, 'id': '7'},
      {'name': 'Frank', 'amount': 8000, 'id': '8'},
      {'name': 'Grace', 'amount': 9000, 'id': '9'},
      {'name': 'Hank', 'amount': -10000, 'id': '10'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Today\'s Collections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customers.length} customers',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 8.0,
                ),
                child: CustomerItemDayForCollection(
                  name: customer['name'],
                  amount: customer['amount'],
                  onTap: () {
                    _showCustomerDetails(context, customer);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCustomerDetails(
      BuildContext context, Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customer['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Amount Due', 'EGP ${customer['amount'].abs()}'),
            _buildDetailRow('Customer ID', '#${customer['id']}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to collection page
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Collect Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
