import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/cubit/customer_cubit/customer_cubit_cubit.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model.dart';

class CustomerInvoicesCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerInvoicesCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get invoices from the customer model
    final invoices = customer.invoices ?? [];
    debugPrint('Building InvoicesCard with ${invoices.length} invoices');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Add refresh button
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.grey),
                      onPressed: () {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Refreshing invoices...')),
                        );

                        // Refresh invoices for this customer
                        context
                            .read<CustomerCubit>()
                            .refreshInvoices(customer.id);
                      },
                      tooltip: 'Refresh Invoices',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${invoices.length} total',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: Theme.of(context).primaryColor),
                      onPressed: () {
                        // Create new invoice - implement later
                        _showAddInvoiceDialog(context);
                      },
                      tooltip: 'Create New Invoice',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Add invoice statistics if we have invoices
            if (invoices.isNotEmpty) _buildInvoiceStatistics(invoices),

            SizedBox(height: 16.h),

            // Invoice list or empty state
            if (invoices.isEmpty)
              _buildEmptyInvoiceMessage()
            else
              _buildInvoicesList(context, invoices),
          ],
        ),
      ),
    );
  }

  // Add this new method for invoice statistics
  Widget _buildInvoiceStatistics(List<InvoiceModel> invoices) {
    // Calculate statistics
    double totalAmount = 0;
    double paidAmount = 0;
    int pendingCount = 0;
    int overdueCount = 0;

    for (var invoice in invoices) {
      totalAmount += invoice.totalAmount;

      if (invoice.paymentStatus.toLowerCase() == 'paid') {
        paidAmount += invoice.totalAmount;
      }

      if (invoice.paymentStatus.toLowerCase() == 'pending') {
        pendingCount++;
      }

      // Check if invoice is overdue
      if (invoice.date.add(const Duration(days: 30)).isBefore(DateTime.now()) &&
          invoice.paymentStatus.toLowerCase() != 'paid') {
        overdueCount++;
      }
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statisticsItem('Total', '\$${totalAmount.toStringAsFixed(2)}'),
          _statisticsItem('Paid', '\$${paidAmount.toStringAsFixed(2)}',
              color: Colors.green),
          _statisticsItem('Pending', pendingCount.toString(),
              color: Colors.orange),
          _statisticsItem('Overdue', overdueCount.toString(),
              color: Colors.red),
        ],
      ),
    );
  }

  Widget _statisticsItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.normal,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddInvoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Invoice'),
        content: Text('Invoice creation will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvoiceMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48.sp,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No invoices yet',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the + button to create an invoice',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(BuildContext context, List<InvoiceModel> invoices) {
    // Sort invoices by date (newest first)
    final sortedInvoices = List<InvoiceModel>.from(invoices)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedInvoices.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final invoice = sortedInvoices[index];
        return InvoiceListItem(
          invoice: invoice,
          onTap: () {
            // Navigate to invoice details
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => InvoiceDetailPage(invoice: invoice),
            //   ),
            // );
          },
        );
      },
    );
  }
}

class InvoiceListItem extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;

  const InvoiceListItem({
    Key? key,
    required this.invoice,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate if invoice is overdue
    final bool isOverdue =
        invoice.date.add(Duration(days: 30)).isBefore(DateTime.now()) &&
            invoice.paymentStatus.toLowerCase() != 'paid';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.paymentStatus, isOverdue)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(invoice.paymentStatus, isOverdue),
                  color: _getStatusColor(invoice.paymentStatus, isOverdue),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Invoice details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${invoice.invoiceNumber}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        'Date: ${_formatDate(invoice.date)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${invoice.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: invoice.paymentStatus.toLowerCase() == 'paid'
                        ? Colors.green
                        : isOverdue
                            ? Colors.red
                            : Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.paymentStatus, isOverdue)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _getStatusText(invoice.paymentStatus, isOverdue),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _getStatusColor(invoice.paymentStatus, isOverdue),
                      fontWeight: FontWeight.w500,
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

  Color _getStatusColor(String status, bool isOverdue) {
    if (isOverdue) return Colors.red;

    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status, bool isOverdue) {
    if (isOverdue) return Icons.warning;

    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusText(String status, bool isOverdue) {
    if (isOverdue && status.toLowerCase() != 'paid') {
      return 'OVERDUE';
    }

    return _capitalizeFirst(status);
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
