// // Update this method in your CustomerDetailView class
// Widget _buildInvoicesList(CustomerModel customer) {
//   // Check if customer has invoices
//   final invoices = customer.invoices ?? [];

//   return Card(
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(16.r),
//     ),
//     child: Padding(
//       padding: EdgeInsets.all(16.w),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Invoices',
//                 style: TextStyle(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 '${invoices.length} total',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           invoices.isEmpty
//               ? Center(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(vertical: 16.h),
//                     child: Text(
//                       'No invoices yet',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 )
//               : ListView.separated(
//                   physics: NeverScrollableScrollPhysics(),
//                   shrinkWrap: true,
//                   itemCount: invoices.length,
//                   separatorBuilder: (context, index) => Divider(),
//                   itemBuilder: (context, index) {
//                     final invoice = invoices[index];
//                     return _buildInvoiceItem(context, invoice);
//                   },
//                 ),
//         ],
//       ),
//     ),
//   );
// }

// // Update this method to work with your InvoiceModel
// Widget _buildInvoiceItem(BuildContext context, InvoiceModel invoice) {
//   // Calculate if invoice is overdue (based on date rather than dueDate)
//   final bool isOverdue =
//       invoice.date.add(Duration(days: 30)).isBefore(DateTime.now()) &&
//           invoice.paymentStatus != 'paid';

//   // Get remaining balance based on your model
//   final double remainingBalance = invoice.totalAmount;

//   return InkWell(
//     onTap: () {
//       // Navigate to invoice details page
//       // Implement when ready
//     },
//     borderRadius: BorderRadius.circular(8.r),
//     child: Padding(
//       padding: EdgeInsets.symmetric(vertical: 8.h),
//       child: Row(
//         children: [
//           Container(
//             width: 50.w,
//             height: 50.w,
//             decoration: BoxDecoration(
//               color: _getStatusColor(invoice.paymentStatus).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8.r),
//             ),
//             child: Center(
//               child: Icon(
//                 _getStatusIcon(invoice.paymentStatus),
//                 color: _getStatusColor(invoice.paymentStatus),
//               ),
//             ),
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Invoice #${invoice.invoiceNumber}',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: 4.h),
//                 Text(
//                   'Date: ${_formatDate(invoice.date)}',
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     color: isOverdue ? Colors.red : Colors.grey,
//                     fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '\$${invoice.totalAmount.toStringAsFixed(2)}',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.bold,
//                   color: invoice.paymentStatus == 'paid'
//                       ? Colors.green
//                       : Colors.red,
//                 ),
//               ),
//               SizedBox(height: 4.h),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
//                 decoration: BoxDecoration(
//                   color:
//                       _getStatusColor(invoice.paymentStatus).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(4.r),
//                 ),
//                 child: Text(
//                   _capitalizeFirst(invoice.paymentStatus),
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     color: _getStatusColor(invoice.paymentStatus),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }

// Color _getStatusColor(String status) {
//   switch (status.toLowerCase()) {
//     case 'paid':
//       return Colors.green;
//     case 'pending':
//       return Colors.orange;
//     case 'overdue':
//       return Colors.red;
//     default:
//       return Colors.blue;
//   }
// }

// IconData _getStatusIcon(String status) {
//   switch (status.toLowerCase()) {
//     case 'paid':
//       return Icons.check_circle;
//     case 'pending':
//       return Icons.hourglass_empty;
//     case 'overdue':
//       return Icons.warning;
//     default:
//       return Icons.receipt;
//   }
// }

// String _formatDate(DateTime date) {
//   return "${date.day}/${date.month}/${date.year}";
// }

// String _capitalizeFirst(String text) {
//   if (text == null || text.isEmpty) return '';
//   return text[0].toUpperCase() + text.substring(1);
// }
