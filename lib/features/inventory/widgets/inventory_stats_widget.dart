import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/dashboard_service.dart';

class InventoryStatsWidget extends StatelessWidget {
  const InventoryStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DashboardService().getDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};
        final inventoryValue = (stats['inventory_value'] as double?) ?? 0.0;
        final totalCost = (stats['total_cost'] as double?) ?? 0.0;
        final expectedProfit = (stats['expected_profit'] as double?) ?? 0.0;
        final lowStockCount = (stats['low_stock_count'] as int?) ?? 0;

        return Row(
          children: [
            // 1. إجمالي المنتجات
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.inventory_2,
                title: 'إجمالي المنتجات',
                value: '6',
                color: AppColors.primary,
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
              ),
            ),
            const SizedBox(width: 12),

            // 5. الربح المتوقع
            Expanded(
              child: _buildSmallStatCard(
                icon: Icons.trending_up,
                title: 'الربح المتوقع',
                value: _formatCurrency(expectedProfit),
                color: const Color(0xFF4CAF50),
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
  }) {
    return Container(
      // ✅ بدون height محدد - يأخذ ارتفاع الـ parent (140)
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ توزيع متساوي
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
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // القيمة
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
