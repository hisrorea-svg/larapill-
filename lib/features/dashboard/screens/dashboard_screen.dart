import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sale.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/sales_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/sales_chart.dart';
import '../widgets/products_pie_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Key _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // تحديث البيانات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _refreshKey = UniqueKey();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'en_US');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اللوحة الرئيسية',
            style: GoogleFonts.tajawal(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // ✅ البيانات الحقيقية من قاعدة البيانات
          FutureBuilder<Map<String, dynamic>>(
            key: _refreshKey,
            future: DashboardService().getDashboardStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Loading State - 5 كروت
                return Row(
                  children: List.generate(
                    5, // ✅ 5 كروت
                    (index) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < 4 ? 12 : 0),
                        height: 135, // ✅ ارتفاع مصغّر
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'خطأ في تحميل البيانات: ${snapshot.error}',
                    style: GoogleFonts.tajawal(color: AppColors.error),
                  ),
                );
              }

              final stats = snapshot.data ?? {};
              final salesCount = stats['sales_count'] ?? 0;
              final averageInvoice = stats['average_invoice'] ?? 0.0;
              final inventoryValue = stats['inventory_value'] ?? 0.0;
              final lowStockCount = stats['low_stock_count'] ?? 0;
              final expiringSoonCount =
                  stats['expiring_soon_count'] ?? 0; // ✅ جديد!
              final totalSalesToday = stats['total_sales_today'] ?? 0.0;
              final percentageChange = stats['percentage_change'] ?? 0.0;

              return IntrinsicHeight(
                  // ✅ أضفناها هنا
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ مهم جداً!
                children: [
                  Expanded(
                    child: DashboardCard(
                      title: 'عدد الفواتير (اليوم)',
                      value: '$salesCount',
                      subtitle:
                          'متوسط: ${formatter.format(averageInvoice.toInt())} د.ع',
                      icon: Icons.receipt_long,
                      color: AppColors.secondary,
                      progress: salesCount > 0
                          ? (salesCount / 100).clamp(0.0, 1.0)
                          : null,
                      onTap: () {
                        // 📊 عرض تفاصيل المبيعات اليوم
                        _showTodaySalesDialog(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12), // ✅ spacing مصغّر

                  // 2️⃣ قيمة المخزون
                  Expanded(
                    child: DashboardCard(
                      title: 'قيمة المخزون',
                      value: '${formatter.format(inventoryValue.toInt())} د.ع',
                      subtitle: 'إجمالي قيمة المخزون',
                      icon: Icons.inventory_2,
                      color: AppColors.primary,
                      progress: 0.75,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 3️⃣ أدوية على وشك النفاذ
                  Expanded(
                    child: DashboardCard(
                      title: 'أدوية على وشك النفاذ',
                      value: '$lowStockCount',
                      subtitle:
                          lowStockCount > 0 ? 'تحتاج طلب فوري' : 'الوضع ممتاز',
                      icon: Icons.warning_amber,
                      color: lowStockCount > 0
                          ? AppColors.warning
                          : AppColors.success,
                      progress: lowStockCount > 0
                          ? (lowStockCount / 50).clamp(0.0, 1.0)
                          : null,
                      onTap: () {
                        // ⚠️ المخزون المنخفض
                        _navigateToLowStock(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ✅ 4️⃣ أدوية قريبة الانتهاء (جديد!)
                  Expanded(
                    child: DashboardCard(
                      title: 'قريبة الانتهاء',
                      value: '$expiringSoonCount',
                      subtitle: expiringSoonCount > 0
                          ? 'خلال 90 يوم'
                          : "لا توجد أدوية ذات اكسباير قريب",
                      icon: Icons.schedule,
                      color: expiringSoonCount > 0
                          ? const Color(0xFFFF6B35)
                          : AppColors.success,
                      progress: expiringSoonCount > 0
                          ? (expiringSoonCount / 30).clamp(0.0, 1.0)
                          : null,
                      onTap: () {
                        // 📅 الأدوية قريبة الانتهاء
                        _navigateToExpiring(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 5️⃣ إجمالي المبيعات
                  Expanded(
                    child: DashboardCard(
                      title: 'إجمالي المبيعات (اليوم)',
                      value: '${formatter.format(totalSalesToday.toInt())} د.ع',
                      subtitle: percentageChange >= 0
                          ? '↑ ${percentageChange.toStringAsFixed(1)}% عن الأمس'
                          : '↓ ${percentageChange.abs().toStringAsFixed(1)}% عن الأمس',
                      icon: Icons.attach_money,
                      color: percentageChange >= 0
                          ? AppColors.success
                          : AppColors.error,
                      progress: 0.6,
                    ),
                  ),
                ],
              ));
            },
          ),

          const SizedBox(height: 32),

          // Charts
          const Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SalesChart(),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ProductsPieChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== Navigation Methods ==========

  void _showTodaySalesDialog(BuildContext context) async {
    // جلب جميع المبيعات المكتملة
    final allSales = await SalesService().getAllSales();
    final completedSales =
        allSales.where((sale) => sale.status == SaleStatus.completed).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => _SalesListDialog(sales: completedSales),
    );
  }

  void _navigateToLowStock(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('اضغط على "إدارة المخزون" ثم فلتر "مخزون منخفض"'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToExpiring(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('اضغط على "إدارة المخزون" ثم فلتر "قريبة الانتهاء"'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ========== Sales List Dialog Widget ==========
class _SalesListDialog extends StatefulWidget {
  final List<Sale> sales;

  const _SalesListDialog({required this.sales});

  @override
  State<_SalesListDialog> createState() => _SalesListDialogState();
}

class _SalesListDialogState extends State<_SalesListDialog> {
  DateTime? _selectedDate;
  List<Sale> _filteredSales = [];

  @override
  void initState() {
    super.initState();
    _filteredSales = widget.sales;
  }

  void _filterByDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
      if (date == null) {
        _filteredSales = widget.sales;
      } else {
        _filteredSales = widget.sales.where((sale) {
          return sale.date.year == date.year &&
              sale.date.month == date.month &&
              sale.date.day == date.day;
        }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePickerDialog(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      minDate: DateTime(2020),
      maxDate: DateTime.now(),
      width: 350,
      height: 400,
      currentDate: DateTime.now(),
      selectedDate: _selectedDate ?? DateTime.now(),
      currentDateDecoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      currentDateTextStyle: const TextStyle(color: Colors.white),
      daysOfTheWeekTextStyle: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w600,
      ),
      enabledCellsTextStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w400,
      ),
      enabledCellsDecoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      selectedCellDecoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      selectedCellTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    if (picked != null) {
      _filterByDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayCount = widget.sales.where((sale) {
      return sale.date.year == today.year &&
          sale.date.month == today.month &&
          sale.date.day == today.day;
    }).length;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDate == null
                      ? 'جميع الفواتير (${_filteredSales.length})'
                      : 'فواتير ${DateFormat('yyyy/MM/dd').format(_selectedDate!)} (${_filteredSales.length})',
                  style: const TextStyle(fontSize: 18),
                ),
                if (_selectedDate == null)
                  Text(
                    'اليوم: $todayCount فاتورة',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 500,
        child: Column(
          children: [
            // ========== Date Filter Row ==========
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _selectedDate == null
                          ? 'اختر تاريخ للفلترة'
                          : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _filterByDate(null),
                    icon: const Icon(Icons.clear),
                    tooltip: 'إزالة الفلتر',
                    color: AppColors.error,
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    final today = DateTime.now();
                    _filterByDate(today);
                  },
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('اليوم'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ========== Sales List ==========
            Expanded(
              child: _filteredSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _selectedDate == null
                                ? 'لا توجد فواتير'
                                : 'لا توجد فواتير في هذا التاريخ',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = _filteredSales[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppColors.secondary.withValues(alpha: 0.1),
                              child: Text(
                                sale.paymentMethod.arabicName[0],
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  sale.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${sale.items.length} منتج',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('yyyy/MM/dd').format(sale.date),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('hh:mm a').format(sale.date),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.payment,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    sale.paymentMethod.arabicName,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${NumberFormat('#,##0').format(sale.total.toInt())} د.ع',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                if (sale.discount > 0)
                                  Text(
                                    'خصم: ${NumberFormat('#,##0').format(sale.discount.toInt())}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('إغلاق'),
        ),
      ],
    );
  }
}
