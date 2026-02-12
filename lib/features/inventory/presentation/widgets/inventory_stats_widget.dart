import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/data/repositories/dashboard_service.dart';

// ✅ Provider للإحصائيات - يتفاعل مع invalidate
final inventoryStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getDashboardStats();
});

class InventoryStatsWidget extends ConsumerWidget {
  const InventoryStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ استخدام Provider بدلاً من FutureBuilder
    final statsAsync = ref.watch(inventoryStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('خطأ: $e',
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
      ),
      data: (stats) {
        final inventoryValue = (stats['inventory_value'] as double?) ?? 0.0;
        final totalCost = (stats['total_cost'] as double?) ?? 0.0;
        final expectedProfit = (stats['expected_profit'] as double?) ?? 0.0;
        final lowStockCount = (stats['low_stock_count'] as int?) ?? 0;
        final totalProducts = (stats['total_products'] as int?) ?? 0;

        return Row(
          children: [
            // 1. إجمالي المنتجات
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.inventory_2,
                title: 'إجمالي المنتجات',
                value: totalProducts.toString(),
                color: AppColors.primary,
                valueColor: AppColors.textPrimary, // نص عادي
              ),
            ),
            const SizedBox(width: 12),

            // 2. المنتجات القليلة
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.warning_amber_rounded,
                title: 'منتجات قليلة',
                value: lowStockCount.toString(),
                color: AppColors.warning,
                valueColor: AppColors.textPrimary, // نص عادي
              ),
            ),
            const SizedBox(width: 12),

            // 3. قيمة المخزون
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.attach_money,
                title: 'قيمة المخزون',
                value: _formatCurrency(inventoryValue),
                color: AppColors.success,
                valueColor: AppColors.textPrimary, // نص عادي
              ),
            ),
            const SizedBox(width: 12),

            // 4. إجمالي التكلفة
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.shopping_cart,
                title: 'إجمالي التكلفة',
                value: _formatCurrency(totalCost),
                color: AppColors.error,
                valueColor: AppColors.textPrimary, // نص عادي (مش أحمر!)
              ),
            ),
            const SizedBox(width: 12),

            // 5. الربح المتوقع (أحمر إذا سالب)
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.trending_up,
                title: 'الربح المتوقع',
                value: _formatCurrency(expectedProfit),
                color: expectedProfit < 0
                    ? AppColors.error
                    : const Color(0xFF4CAF50),
                valueColor: expectedProfit < 0
                    ? AppColors.error
                    : const Color(0xFF4CAF50), // الوحيد اللي يتلون!
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M د.ع';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K د.ع';
    }
    return '${value.toStringAsFixed(0)} د.ع';
  }

  // ✅ كارت صغير - يملأ كامل الارتفاع
  Widget _buildSmallStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    Color? valueColor, // اختياري - لون النص
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الأيقونة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),

          // العنوان
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // القيمة (لون ديناميكي يطابق لون الكارت)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ??
                    AppColors
                        .textPrimary, // استخدام valueColor أو اللون الافتراضي
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
