import 'package:flutter/material.dart';

class CustomerItemDayForCollection extends StatelessWidget {
  final String name;
  final int amount;
  final VoidCallback? onTap;

  const CustomerItemDayForCollection({
    super.key,
    required this.name,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositiveAmount = amount >= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isPositiveAmount ? Colors.green.shade50 : Colors.red.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(
                alpha: 26,
              ),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                isPositiveAmount ? Colors.green.shade200 : Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Collection Due',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EGP ${amount.abs()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositiveAmount ? Colors.green : Colors.red,
                  ),
                ),
                Icon(
                  isPositiveAmount ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositiveAmount ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
