import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/report_export_service.dart';
import '../../../database/daos/sale_dao.dart';
import '../../../database/daos/customer_debt_dao.dart';
import '../../inventory/providers/inventory_providers.dart';
import '../widgets/sales_report_card.dart';
import '../widgets/inventory_report_card.dart';
import '../widgets/financial_report_card.dart';
import '../widgets/debts_report_card.dart';

class ModernReportsScreen extends ConsumerStatefulWidget {
  const ModernReportsScreen({super.key});

  @override
  ConsumerState<ModernReportsScreen> createState() =>
      _ModernReportsScreenState();
}

class _ModernReportsScreenState extends ConsumerState<ModernReportsScreen> {
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    // تحديث البيانات تلقائياً عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(productsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildReportsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.assessment, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التقارير والإحصائيات',
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تحليل شامل لأداء الصيدلية',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            onPressed: () => _showExportDialog(),
            icon: const Icon(Icons.file_download, color: AppColors.primary),
            tooltip: 'تصدير التقارير',
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildPeriodButton('اليوم', 'today', Icons.today),
          _buildPeriodButton('الأسبوع', 'week', Icons.date_range),
          _buildPeriodButton('الشهر', 'month', Icons.calendar_month),
          _buildPeriodButton('السنة', 'year', Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 3.0,
      children: [
        SalesReportCard(period: _selectedPeriod),
        InventoryReportCard(period: _selectedPeriod),
        FinancialReportCard(period: _selectedPeriod),
        DebtsReportCard(period: _selectedPeriod),
      ],
    );
  }

  void _showExportDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.file_download,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text('تصدير التقارير',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر صيغة التصدير المناسبة',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption('PDF', Icons.picture_as_pdf, Colors.red,
                'مناسب للطباعة والأرشفة'),
            const SizedBox(height: 12),
            _buildExportOption('Excel', Icons.table_chart, Colors.green,
                'مناسب للتحليل والمعالجة'),
            const SizedBox(height: 12),
            _buildExportOption('CSV', Icons.text_snippet, Colors.blue,
                'ملف نصي قابل للاستيراد'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
      String label, IconData icon, Color color, String description) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);

        // عرض مؤشر التحميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تصدير التقرير...',
                    style: GoogleFonts.tajawal(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );

        try {
          // تجهيز البيانات للتصدير
          final salesData = await _getSalesData();
          final inventoryData = await _getInventoryData();
          final financialData = await _getFinancialData();
          final debtsData = await _getDebtsData();

          String filePath;

          // التصدير حسب النوع
          if (label == 'PDF') {
            filePath = await ReportExportService.exportToPDF(
              period: _selectedPeriod,
              salesData: salesData,
              inventoryData: inventoryData,
              financialData: financialData,
              debtsData: debtsData,
            );
          } else if (label == 'Excel') {
            filePath = await ReportExportService.exportToExcel(
              period: _selectedPeriod,
              salesData: salesData,
              inventoryData: inventoryData,
              financialData: financialData,
              debtsData: debtsData,
            );
          } else {
            filePath = await ReportExportService.exportToCSV(
              period: _selectedPeriod,
              salesData: salesData,
              inventoryData: inventoryData,
              financialData: financialData,
              debtsData: debtsData,
            );
          }

          if (!mounted) return;
          Navigator.pop(context);

          // عرض رسالة النجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تم التصدير بنجاح!',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'تم حفظ التقرير بصيغة $label',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'فتح',
                textColor: Colors.white,
                onPressed: () async {
                  await ReportExportService.openFile(filePath);
                },
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ في التصدير: ${e.toString()}',
                style: GoogleFonts.tajawal(),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تصدير كـ $label',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // دوال جمع البيانات للتصدير
  Future<Map<String, dynamic>> _getSalesData() async {
    try {
      final dao = SaleDAO();
      final sales = await dao.getAllSales();

      final now = DateTime.now();
      final filteredSales = sales.where((sale) {
        switch (_selectedPeriod) {
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

  Future<Map<String, dynamic>> _getInventoryData() async {
    try {
      final products = await ref.read(productsProvider.future);

      final lowStock =
          products.where((p) => p.quantity < 20 && p.quantity > 0).length;
      final outOfStock = products.where((p) => p.quantity == 0).length;

      return {
        'total': products.length,
        'lowStock': lowStock,
        'outOfStock': outOfStock,
      };
    } catch (e) {
      return {
        'total': 0,
        'lowStock': 0,
        'outOfStock': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getFinancialData() async {
    try {
      final salesData = await _getSalesData();

      return {
        'revenue': salesData['total'],
        'profit': salesData['profit'],
        'expenses': 0.0, // يمكن إضافة منطق المصروفات لاحقاً
      };
    } catch (e) {
      return {
        'revenue': 0.0,
        'profit': 0.0,
        'expenses': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getDebtsData() async {
    try {
      final dao = CustomerDebtDAO();
      final debts = await dao.getAllDebts();

      final total = debts.fold(0.0, (sum, debt) => sum + debt.remainingDebt);
      final paid = debts.fold(0.0, (sum, debt) => sum + debt.totalPaid);

      return {
        'total': total.toInt(),
        'count': debts.length,
        'paid': paid.toInt(),
      };
    } catch (e) {
      return {
        'total': 0.0,
        'count': 0,
        'paid': 0.0,
      };
    }
  }
}
