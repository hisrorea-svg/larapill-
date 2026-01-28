import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../pos/data/datasources/local/sale_dao.dart';

class SalesReportCard extends ConsumerWidget {
  final String period;

  const SalesReportCard({super.key, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSalesStats(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'count': 0, 'total': 0.0, 'profit': 0.0};

        return _buildCard(
          context,
          title: 'تقرير المبيعات',
          icon: Icons.point_of_sale,
          color: AppColors.primary,
          stats: [
            _StatItem('عدد الفواتير', '${stats['count']}', Icons.receipt_long),
            _StatItem(
                'إجمالي المبيعات', '${stats['total']} د.ع', Icons.attach_money),
            _StatItem(
                'الربح المتوقع', '${stats['profit']} د.ع', Icons.trending_up),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getSalesStats() async {
    try {
      final dao = SaleDAO();
      final sales = await dao.getAllSales();

      final now = DateTime.now();
      final filteredSales = sales.where((sale) {
        switch (period) {
          case 'today':
            return sale.date.year == now.year &&
                sale.date.month == now.month &&
                sale.date.day == now.day;
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return sale.date.isAfter(weekAgo);
          case 'month':
            return sale.date.year == now.year && sale.date.month == now.month;
          case 'year':
            return sale.date.year == now.year;
          default:
            return true;
        }
      }).toList();

      final total = filteredSales.fold(0.0, (sum, sale) => sum + sale.total);
      final profit = total * 0.25; // تقدير الربح 25%

      return {
        'count': filteredSales.length,
        'total': total.toInt(),
        'profit': profit.toInt(),
      };
    } catch (e) {
      return {'count': 0, 'total': 0, 'profit': 0};
    }
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_StatItem> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(stat.icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      stat.label,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stat.value,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  _StatItem(this.label, this.value, this.icon);
}
