import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/drift/daos/sales_drift_dao.dart';

/// Provider for weekly sales chart data
final weeklySalesDataProvider =
    FutureProvider<List<DailySalesData>>((ref) async {
  final dao = ref.watch(salesDriftDaoProvider);
  return dao.getWeeklySalesData();
});

class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesDataAsync = ref.watch(weeklySalesDataProvider);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مبيعات الأسبوع الحالي',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: salesDataAsync.when(
              data: (salesData) => _buildChart(salesData),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مبيعات لعرضها',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<DailySalesData> salesData) {
    if (salesData.isEmpty) {
      return _buildEmptyState();
    }

    // ✅ حساب القيم الديناميكية
    final maxValue =
        salesData.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    // ✅ حساب interval ديناميكي (لن يكون صفر أبداً)
    final interval = maxValue > 0 ? (maxValue / 4).ceilToDouble() : 100000.0;
    final roundedMax =
        maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 100000.0;

    // ✅ تحويل البيانات إلى FlSpots
    final spots = List.generate(
      salesData.length,
      (index) => FlSpot(
        index.toDouble(),
        salesData[index].total,
      ),
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  bottomTitleWidgets(value, meta, salesData.length),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 80,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        minX: 0,
        maxX: (salesData.length - 1).toDouble(),
        minY: 0,
        maxY: roundedMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.5),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0) {
      return const Text(
        '0',
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    // ✅ عرض القيم الديناميكية
    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      text = value.toStringAsFixed(0);
    }

    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta, int dataLength) {
    if (value.toInt() >= dataLength) {
      return const SizedBox();
    }

    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: AppColors.textSecondary,
    );

    final weekDays = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة'
    ];
    final dayIndex = (DateTime.now().weekday + value.toInt()) % 7;

    return Text(
      weekDays[dayIndex],
      style: const TextStyle(
        fontFamily: 'Tajawal',
      ).merge(style),
    );
  }
}
