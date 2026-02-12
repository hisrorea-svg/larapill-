import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/custom_month_picker.dart';
import 'package:drift/drift.dart' show Variable;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/drift/database_provider.dart';

// --- Models ---

class TopProductData {
  final String name;
  final int quantity;
  final double amount;

  TopProductData(
      {required this.name, required this.quantity, required this.amount});
}

class TopSupplierData {
  final String name;
  final int orderCount;
  final double amount;

  TopSupplierData(
      {required this.name, required this.orderCount, required this.amount});
}

class DailySpendingData {
  final int day;
  final double amount;

  DailySpendingData({required this.day, required this.amount});
}

class MonthlyReportData {
  final DateTime month;
  final int totalOrders;
  final double totalAmount;
  final List<TopProductData> topProducts;
  final List<TopSupplierData> topSuppliers;
  final List<DailySpendingData> dailySpending;

  MonthlyReportData({
    required this.month,
    required this.totalOrders,
    required this.totalAmount,
    required this.topProducts,
    required this.topSuppliers,
    required this.dailySpending,
  });
}

// --- Provider ---

final monthlyReportProvider =
    FutureProvider.family<MonthlyReportData, DateTime>((ref, month) async {
  final db = ref.watch(appDatabaseProvider);

  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  // 1. Totals
  final totalsResult = await db.customSelect('''
    SELECT COUNT(*) as count, SUM(total) as total_amount 
    FROM purchase_orders 
    WHERE status = 'posted' 
      AND posted_at >= ? AND posted_at <= ?
  ''', variables: [
    Variable.withString(startOfMonth.toIso8601String()),
    Variable.withString(endOfMonth.toIso8601String()),
  ]).get();

  final totalOrders = totalsResult.isNotEmpty
      ? (totalsResult.first.data['count'] as int?) ?? 0
      : 0;
  final totalAmount = totalsResult.isNotEmpty
      ? (totalsResult.first.data['total_amount'] as num?)?.toDouble() ?? 0
      : 0.0;

  // 2. Top Products
  final productsResult = await db.customSelect('''
    SELECT 
      oi.product_name, 
      SUM(oi.quantity) as total_qty, 
      SUM(oi.total) as total_amt
    FROM purchase_items oi
    JOIN purchase_orders po ON oi.purchase_order_id = po.id
    WHERE po.status = 'posted'
      AND po.posted_at >= ? AND po.posted_at <= ?
    GROUP BY oi.product_name
    ORDER BY total_amt DESC
    LIMIT 5
  ''', variables: [
    Variable.withString(startOfMonth.toIso8601String()),
    Variable.withString(endOfMonth.toIso8601String()),
  ]).get();

  final topProducts = productsResult
      .map((e) => TopProductData(
            name: e.data['product_name'] as String? ?? 'منتج غير معروف',
            quantity: (e.data['total_qty'] as num?)?.toInt() ?? 0,
            amount: (e.data['total_amt'] as num?)?.toDouble() ?? 0,
          ))
      .toList();

  // 3. Top Suppliers
  final suppliersResult = await db.customSelect('''
    SELECT 
      s.name as supplier_name, 
      COUNT(*) as order_count, 
      SUM(po.total) as supplier_total
    FROM purchase_orders po
    JOIN suppliers s ON po.supplier_id = s.id
    WHERE po.status = 'posted'
      AND po.posted_at >= ? AND po.posted_at <= ?
    GROUP BY s.name
    ORDER BY supplier_total DESC
    LIMIT 5
  ''', variables: [
    Variable.withString(startOfMonth.toIso8601String()),
    Variable.withString(endOfMonth.toIso8601String()),
  ]).get();

  final topSuppliers = suppliersResult
      .map((e) => TopSupplierData(
            name: e.data['supplier_name'] as String? ?? 'مورد غير معروف',
            orderCount: (e.data['order_count'] as int?) ?? 0,
            amount: (e.data['supplier_total'] as num?)?.toDouble() ?? 0,
          ))
      .toList();

  // 4. Daily Spending
  final dailyResult = await db.customSelect('''
    SELECT 
      CAST(strftime('%d', posted_at) as INTEGER) as day,
      SUM(total) as daily_total
    FROM purchase_orders 
    WHERE status = 'posted'
      AND posted_at >= ? AND posted_at <= ?
    GROUP BY day
    ORDER BY day ASC
  ''', variables: [
    Variable.withString(startOfMonth.toIso8601String()),
    Variable.withString(endOfMonth.toIso8601String()),
  ]).get();

  final dailySpending = dailyResult.map((row) {
    final dayVal = row.data['day'];
    int day = 1;
    if (dayVal is int) {
      day = dayVal;
    } else if (dayVal is String) {
      day = int.tryParse(dayVal) ?? 1;
    }

    return DailySpendingData(
      day: day,
      amount: (row.data['daily_total'] as num?)?.toDouble() ?? 0,
    );
  }).toList();

  return MonthlyReportData(
    month: month,
    totalOrders: totalOrders,
    totalAmount: totalAmount,
    topProducts: topProducts,
    topSuppliers: topSuppliers,
    dailySpending: dailySpending,
  );
});

// --- Screen Widget ---

class MonthlyPurchaseReportScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const MonthlyPurchaseReportScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<MonthlyPurchaseReportScreen> createState() =>
      _MonthlyPurchaseReportScreenState();
}

class _MonthlyPurchaseReportScreenState
    extends ConsumerState<MonthlyPurchaseReportScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _selectMonth() async {
    final picked = await showCustomMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(monthlyReportProvider(_selectedMonth));

    Widget content = reportAsync.when(
      data: (data) => _buildReport(data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(
        child: SelectableText('حدث خطأ: $e\n$stack',
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقرير الشهري',
            style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _buildReport(MonthlyReportData data) {
    // Check if empty
    if (data.totalOrders == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Month Selector)
          _buildMonthHeader(data),
          const SizedBox(height: 24),

          // Summary Cards Grid
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'إجمالي المشتريات',
                    value:
                        NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0)
                            .format(data.totalAmount),
                    icon: Icons.monetization_on,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F9D58), Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'عدد الطلبات',
                    value: '${data.totalOrders}',
                    icon: Icons.receipt_long,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF29B6F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'المتوسط اليومي',
                      value: NumberFormat.currency(
                              symbol: 'د.ع', decimalDigits: 0)
                          .format(data.totalAmount /
                              DateTime(data.month.year, data.month.month + 1, 0)
                                  .day),
                      icon: Icons.show_chart,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFFFBC02D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),

          const SizedBox(height: 32),

          // Main Content: Chart + Tables
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildDailyTrendChart(data)),
                  const SizedBox(width: 24),
                  Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildTopProductsTable(data),
                          const SizedBox(height: 24),
                          _buildTopSuppliersTable(data),
                        ],
                      )),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildDailyTrendChart(data),
                  const SizedBox(height: 24),
                  _buildTopProductsTable(data),
                  const SizedBox(height: 24),
                  _buildTopSuppliersTable(data),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Month Selector even in empty state
          InkWell(
            onTap: _selectMonth,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'ar').format(_selectedMonth),
                    style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_calendar,
                      color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد مشتريات في هذا الشهر',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(MonthlyReportData data) {
    return Center(
      child: InkWell(
        onTap: _selectMonth,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMMM yyyy', 'ar').format(data.month),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTrendChart(MonthlyReportData data) {
    // Transform data for chart
    final spots = data.dailySpending
        .map((e) => FlSpot(e.day.toDouble(), e.amount))
        .toList();
    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'محننى المصروفات اليومي',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5, // Every 5 days
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                          showTitles:
                              false), // Hide Y axis numbers to keep it clean, rely on tooltip
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.blueGrey,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.x.toInt()} يوم \n ${NumberFormat.compact().format(spot.y)}',
                            const TextStyle(
                                color: Colors.white, fontFamily: 'Tajawal'),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsTable(MonthlyReportData data) {
    return _buildTableCard(
      title: 'أكثر المنتجات شراءً',
      icon: Icons.shopping_bag_outlined,
      children: data.topProducts
          .map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication,
                      color: Colors.purple, size: 20),
                ),
                title: Text(p.name,
                    style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                subtitle: Text('${p.quantity} قطع',
                    style:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                trailing: Text(
                  NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0)
                      .format(p.amount),
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTopSuppliersTable(MonthlyReportData data) {
    return _buildTableCard(
      title: 'أكثر الموردين تعاملاً',
      icon: Icons.business,
      children: data.topSuppliers
          .map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.store, color: Colors.orange, size: 20),
                ),
                title: Text(s.name,
                    style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                subtitle: Text('${s.orderCount} فواتير',
                    style:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                trailing: Text(
                  NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0)
                      .format(s.amount),
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTableCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 30),
            if (children.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد بيانات',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
