import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:trust_finiance/view/invoice/add_invoice.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double totalAmount;

  const InvoicePreviewDialog({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.items,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = 1.sw > 600;

    // Create a full-screen page instead of a dialog
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice Preview',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt, size: 22.sp),
            tooltip: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Export to PDF functionality will be added soon'),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.close, size: 22.sp),
            tooltip: 'Close Preview',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildInvoiceContent(context, theme, isTablet),
      ),
      bottomNavigationBar: _buildBottomBar(context, theme),
    );
  }

  Widget _buildInvoiceContent(
      BuildContext context, ThemeData theme, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600.w : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Paper-like invoice container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business header
                    _buildBusinessHeader(theme),
                    SizedBox(height: 20.h),

                    // Invoice info section
                    _buildInvoiceInfoSection(theme, isTablet),
                    SizedBox(height: 20.h),

                    // Items table
                    _buildItemsTable(context, theme),
                    SizedBox(height: 20.h),

                    // Total and subtotals
                    _buildTotalSection(theme),

                    SizedBox(height: 24.h),

                    // Terms and conditions
                    _buildTermsSection(theme),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Additional info card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Invoice Information',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontSize: 14.sp),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This is a preview of your invoice before it\'s finalized. You can go back and make edits or save it as a PDF.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Business', // Replace with actual business name
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '123 Business Street, City',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    'Phone: +1 (123) 456-7890',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    'Email: business@example.com',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'INVOICE',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Divider(thickness: 1.h),
      ],
    );
  }

  Widget _buildInvoiceInfoSection(ThemeData theme, bool isTablet) {
    final infoSection = isTablet
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCustomerInfo(theme),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: _buildInvoiceDetails(theme),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerInfo(theme),
              SizedBox(height: 16.h),
              _buildInvoiceDetails(theme),
            ],
          );

    return infoSection;
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill To:',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          customerName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        Text(
          customerAddress,
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          'Phone: $customerPhone',
          style: TextStyle(fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildInvoiceDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice number
        Row(
          children: [
            Text(
              'Invoice #:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              invoiceNumber,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Invoice date
        Row(
          children: [
            Text(
              'Date:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              DateFormat('MMM dd, yyyy').format(invoiceDate),
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
        // Due date
        SizedBox(height: 8.h),
        Row(
          children: [
            Text(
              'Due Date:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              DateFormat('MMM dd, yyyy')
                  .format(invoiceDate.add(const Duration(days: 30))),
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item Description',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Price',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.3.sh,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1.h,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final itemTotal = item.price * item.quantity;

                return Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '₹${itemTotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 0.7.sw,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  '${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            // Add tax rows here if needed
            Divider(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Payment due within 30 days. Please make payments to the account specified in the invoice.',
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 16.h),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Thank you for your business!',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.edit, size: 18.sp),
                label: Text(
                  'Edit Invoice',
                  style: TextStyle(fontSize: 12.sp),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invoice saved successfully'),
                    ),
                  );
                  Navigator.pop(context, true); // Return true to indicate save
                },
                icon: Icon(Icons.check, size: 18.sp),
                label: Text(
                  'Finalize Invoice',
                  style: TextStyle(fontSize: 12.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
