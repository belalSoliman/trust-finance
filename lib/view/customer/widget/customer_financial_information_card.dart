import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:trust_finiance/models/customer_model/customer_model.dart';
import 'package:trust_finiance/models/invoice_model/invoice_model.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this package to your pubspec.yaml

class CustomerFinancialCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerFinancialCard({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get invoices to calculate financial metrics
    final invoices = customer.invoices ?? [];

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
            Text(
              'Financial Summary',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            // Financial summary
            _buildFinancialSummary(context, customer, invoices),

            SizedBox(height: 20.h),

            // Payment history chart
            if (invoices.isNotEmpty) ...[
              Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12.h),
              _buildPaymentHistoryChart(context, invoices),
              SizedBox(height: 20.h),
            ],

            // Aging analysis
            if (invoices.isNotEmpty) ...[
              Text(
                'Invoice Aging',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12.h),
              _buildAgingAnalysis(invoices),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context, CustomerModel customer,
      List<InvoiceModel> invoices) {
    // Calculate financial metrics
    final formatter = NumberFormat.currency(symbol: '\$');

    double totalBilled = 0;
    double totalPaid = 0;
    double overdueAmount = 0;

    for (final invoice in invoices) {
      totalBilled += invoice.totalAmount;

      if (invoice.paymentStatus.toLowerCase() == 'paid') {
        totalPaid += invoice.totalAmount;
      }

      if (invoice.date.add(Duration(days: 30)).isBefore(DateTime.now()) &&
          invoice.paymentStatus.toLowerCase() != 'paid') {
        overdueAmount += invoice.totalAmount;
      }
    }

    final outstandingBalance = totalBilled - totalPaid;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildFinancialRow(
            'Total Billed',
            formatter.format(totalBilled),
            icon: Icons.receipt_long,
          ),
          SizedBox(height: 12.h),
          _buildFinancialRow(
            'Total Paid',
            formatter.format(totalPaid),
            icon: Icons.check_circle,
            valueColor: Colors.green,
          ),
          SizedBox(height: 12.h),
          Divider(height: 1),
          SizedBox(height: 12.h),
          _buildFinancialRow(
            'Outstanding Balance',
            formatter.format(outstandingBalance),
            icon: Icons.account_balance_wallet,
            valueColor: outstandingBalance > 0 ? Colors.orange : Colors.green,
            valueFontSize: 18.sp,
            titleFontSize: 16.sp,
            isBold: true,
          ),
          if (overdueAmount > 0) ...[
            SizedBox(height: 12.h),
            _buildFinancialRow(
              'Overdue Amount',
              formatter.format(overdueAmount),
              icon: Icons.warning,
              valueColor: Colors.red,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String title,
    String value, {
    IconData? icon,
    Color? valueColor,
    double? valueFontSize,
    double? titleFontSize,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20.sp,
                color: valueColor ?? Colors.grey,
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize ?? 14.sp,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize ?? 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryChart(
      BuildContext context, List<InvoiceModel> invoices) {
    // Sort invoices by date
    final sortedInvoices = List<InvoiceModel>.from(invoices)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Group invoices by month
    final Map<int, _MonthlyFinancial> monthlyData = {};

    for (final invoice in sortedInvoices) {
      final monthKey = invoice.date.year * 100 +
          invoice.date.month; // e.g. 202403 for March 2024

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = _MonthlyFinancial(
          month: DateTime(invoice.date.year, invoice.date.month),
          billed: 0,
          paid: 0,
        );
      }

      monthlyData[monthKey]!.billed += invoice.totalAmount;

      if (invoice.paymentStatus.toLowerCase() == 'paid') {
        monthlyData[monthKey]!.paid += invoice.totalAmount;
      }
    }

    // Convert to list and ensure we have at least 6 months
    final dataPoints = monthlyData.values.toList();

    // If we have fewer than 6 months, add empty months
    if (dataPoints.isNotEmpty && dataPoints.length < 6) {
      final firstMonth = dataPoints.first.month;
      for (int i = 1; i <= (6 - dataPoints.length); i++) {
        final previousMonth = DateTime(
          firstMonth.year,
          firstMonth.month - i,
        );
        dataPoints.insert(
            0,
            _MonthlyFinancial(
              month: previousMonth,
              billed: 0,
              paid: 0,
            ));
      }
    }

    // Ensure we display at most 6 months
    final chartData = dataPoints.length > 6
        ? dataPoints.sublist(dataPoints.length - 6)
        : dataPoints;

    // If no data, show a placeholder
    if (chartData.isEmpty) {
      return Container(
        height: 200.h,
        alignment: Alignment.center,
        child: Text(
          'No payment history available yet',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      height: 200.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return Text('');
                  return Text(
                    '\$${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10.sp,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= chartData.length) return Text('');

                  final month = chartData[index].month;
                  return Text(
                    DateFormat('MMM').format(month),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10.sp,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: false,
          ),
          groupsSpace: 12,
          barGroups: List.generate(
            chartData.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: chartData[index].billed,
                  color: Theme.of(context).primaryColor,
                  width: 8,
                ),
                BarChartRodData(
                  toY: chartData[index].paid,
                  color: Colors.green,
                  width: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgingAnalysis(List<InvoiceModel> invoices) {
    // Group invoices by aging brackets
    int current = 0;
    int days30 = 0;
    int days60 = 0;
    int days90 = 0;
    int days90Plus = 0;

    double currentAmount = 0;
    double days30Amount = 0;
    double days60Amount = 0;
    double days90Amount = 0;
    double days90PlusAmount = 0;

    final now = DateTime.now();

    for (final invoice in invoices) {
      // Skip paid invoices
      if (invoice.paymentStatus.toLowerCase() == 'paid') {
        continue;
      }

      final daysDiff = now.difference(invoice.date).inDays;

      if (daysDiff < 30) {
        current++;
        currentAmount += invoice.totalAmount;
      } else if (daysDiff < 60) {
        days30++;
        days30Amount += invoice.totalAmount;
      } else if (daysDiff < 90) {
        days60++;
        days60Amount += invoice.totalAmount;
      } else if (daysDiff < 120) {
        days90++;
        days90Amount += invoice.totalAmount;
      } else {
        days90Plus++;
        days90PlusAmount += invoice.totalAmount;
      }
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Age',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 8.w),
              Expanded(
                  child: Text('Count',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Divider(),
          _buildAgingRow('Current', current, currentAmount),
          _buildAgingRow('30 Days', days30, days30Amount, isOverdue: true),
          _buildAgingRow('60 Days', days60, days60Amount, isOverdue: true),
          _buildAgingRow('90 Days', days90, days90Amount, isOverdue: true),
          _buildAgingRow('90+ Days', days90Plus, days90PlusAmount,
              isOverdue: true),
        ],
      ),
    );
  }

  Widget _buildAgingRow(String label, int count, double amount,
      {bool isOverdue = false}) {
    final formatter = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isOverdue ? Colors.red : null,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: isOverdue && count > 0 ? Colors.red : null,
                fontWeight: isOverdue && count > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              formatter.format(amount),
              style: TextStyle(
                color: isOverdue && amount > 0 ? Colors.red : null,
                fontWeight: isOverdue && amount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for monthly financial data
class _MonthlyFinancial {
  final DateTime month;
  double billed;
  double paid;

  _MonthlyFinancial({
    required this.month,
    required this.billed,
    required this.paid,
  });
}
