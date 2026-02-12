import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/reports_providers.dart';
import 'recent_transactions_log.dart';

/// لوحة الإجراءات السريعة للتقارير
class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: Icons.refresh,
            label: 'تحديث البيانات',
            color: const Color(0xFFE3F2FD),
            iconColor: AppColors.info,
            onTap: () => _refreshData(ref, context),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.picture_as_pdf,
            label: 'تصدير PDF',
            color: const Color(0xFFFFEBEE),
            iconColor: AppColors.error,
            onTap: () => _exportPDF(context),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.table_chart,
            label: 'تصدير Excel',
            color: const Color(0xFFE8F5E9),
            iconColor: AppColors.success,
            onTap: () => _exportExcel(context),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.print,
            label: 'طباعة التقرير',
            color: const Color(0xFFFFF3CD),
            iconColor: AppColors.warning,
            onTap: () => _printReport(context),
          ),
        ],
      ),
    );
  }

  /// تحديث بيانات التقارير
  void _refreshData(WidgetRef ref, BuildContext context) {
    debugPrint('🔄 تحديث بيانات التقارير...');

    // تحديث جميع الـ Providers
    ref.invalidate(financialReportProvider);
    ref.invalidate(debtsReportProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(recentTransactionsProvider);

    AppToast.success(context, 'تم تحديث البيانات بنجاح');
  }

  /// تصدير PDF
  void _exportPDF(BuildContext context) {
    debugPrint('📄 تصدير PDF...');
    _showComingSoonDialog(context, 'تصدير PDF');
  }

  /// تصدير Excel
  void _exportExcel(BuildContext context) {
    debugPrint('📊 تصدير Excel...');
    _showComingSoonDialog(context, 'تصدير Excel');
  }

  /// طباعة التقرير
  void _printReport(BuildContext context) {
    debugPrint('🖨️ طباعة التقرير...');
    _showComingSoonDialog(context, 'طباعة التقرير');
  }

  /// عرض رسالة "قريباً"
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'قريباً',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'الميزة "$feature" قيد التطوير وسيتم إطلاقها قريباً',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر الإجراء السريع
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
