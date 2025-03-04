import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:trust_finiance/models/invoice_model/invoice_model.dart';
import 'package:trust_finiance/models/payment_model/payment_model.dart';

class CustomerPaymentHistoryCard extends StatelessWidget {
  final List<InvoiceModel> invoices;
  final List<PaymentModel> payments; // Assuming you'll create this model

  const CustomerPaymentHistoryCard({
    Key? key,
    required this.invoices,
    this.payments = const [], // Optional until implemented
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter only paid invoices
    final paidInvoices = invoices
        .where((inv) => inv.paymentStatus.toLowerCase() == 'paid')
        .toList();

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
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${paidInvoices.length} payments',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (paidInvoices.isEmpty)
              _buildEmptyPaymentHistory()
            else
              _buildPaymentList(context, paidInvoices),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPaymentHistory() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 48.sp,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No payment history yet',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(
      BuildContext context, List<InvoiceModel> paidInvoices) {
    final formatter = NumberFormat.currency(symbol: '\$');

    // Sort by payment date (most recent first)
    // For now, using invoice date, you can replace with actual payment date later
    paidInvoices.sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: paidInvoices.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final invoice = paidInvoices[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Icon(Icons.check, color: Colors.green),
          ),
          title: Text(
            'Invoice #${invoice.invoiceNumber}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('MMM dd, yyyy').format(invoice.date)),
              // You can add payment method here when available
              // Text('Paid via ${payment.method}'),
            ],
          ),
          trailing: Text(
            formatter.format(invoice.totalAmount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          onTap: () {
            // Navigate to payment details if needed
          },
        );
      },
    );
  }
}
