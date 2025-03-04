import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model.dart';

class CustomerHeaderCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerHeaderCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32.r,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                customer.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Customer ID: ${customer.id.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Added on ${formatDate(customer.createdAt)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerContactCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerContactCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _infoRow(Icons.phone, 'Phone', customer.phone),
            if (customer.email != null && customer.email!.isNotEmpty)
              _infoRow(Icons.email, 'Email', customer.email!),
            if (customer.address != null && customer.address!.isNotEmpty)
              _infoRow(Icons.location_on, 'Address', customer.address!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerFinancialCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerFinancialCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _financialRow('Total Loans', customer.totalLoanAmount),
            _financialRow('Total Repaid', customer.totalPaidAmount),
            Divider(height: 24.h),
            _financialRow(
              'Outstanding Balance',
              customer.outstandingBalance,
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _financialRow(String label, double amount,
      {bool isHighlighted = false}) {
    final textColor = isHighlighted
        ? (amount >= 0 ? Colors.green : Colors.red)
        : Colors.black;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? textColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerNotesCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerNotesCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              customer.notes!,
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerInvoicesCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerInvoicesCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final invoices = customer.invoices ?? [];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
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
                Text(
                  '${invoices.length} total',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            invoices.isEmpty
                ? _buildEmptyInvoicesMessage()
                : _buildInvoicesList(invoices),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInvoicesMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          'No invoices yet',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesList(List<InvoiceModel> invoices) {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: invoices.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InvoiceListItem(invoice: invoice);
      },
    );
  }
}

class InvoiceListItem extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceListItem({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Adapt this to work with your actual InvoiceModel implementation
    bool isOverdue = false;
    double remainingBalance = 0;

    // For the existing InvoiceModel that has date and paymentStatus fields
    if (invoice.date != null) {
      isOverdue =
          invoice.date.add(Duration(days: 30)).isBefore(DateTime.now()) &&
              invoice.paymentStatus != 'paid';
      remainingBalance = invoice.totalAmount;
    }

    return InkWell(
      onTap: () {
        // Navigate to invoice details page
        // Uncomment when you have an invoice detail page
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => InvoiceDetailPage(invoiceId: invoice.id),
        //   ),
        // );
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.paymentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(invoice.paymentStatus),
                  color: _getStatusColor(invoice.paymentStatus),
                ),
              ),
            ),
            SizedBox(width: 12.w),
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
                  Text(
                    'Date: ${formatDate(invoice.date)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isOverdue ? Colors.red : Colors.grey,
                      fontWeight:
                          isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${invoice.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: invoice.paymentStatus == 'paid'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(invoice.paymentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _capitalizeFirst(invoice.paymentStatus),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _getStatusColor(invoice.paymentStatus),
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

  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Utility functions
String formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}
