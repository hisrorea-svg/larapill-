import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../debts/data/datasources/local/customer_debt_dao.dart';

class DebtsReportCard extends ConsumerWidget {
  final String period;

  const DebtsReportCard({super.key, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDebtsStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0.0, 'count': 0, 'paid': 0.0};

        return _buildCard(
          context,
          title: 'تقرير الديون',
          icon: Icons.account_balance_wallet,
          color: AppColors.error,
          stats: [
            _StatItem(
                'إجمالي الديون', '${stats['total']} د.ع', Icons.attach_money),
            _StatItem('عدد المدينين', '${stats['count']}', Icons.people),
            _StatItem(
                'المبالغ المحصلة', '${stats['paid']} د.ع', Icons.check_circle),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDebtsStats() async {
    try {
      final dao = CustomerDebtDAO();
      final debts = await dao.getAllDebts();

      final totalDebts =
          debts.fold(0.0, (sum, debt) => sum + debt.remainingDebt);
      final totalPaid = debts.fold(0.0, (sum, debt) => sum + debt.totalPaid);

      return {
        'total': totalDebts.toInt(),
        'count': debts.length,
        'paid': totalPaid.toInt(),
      };
    } catch (e) {
      return {'total': 0, 'count': 0, 'paid': 0};
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
