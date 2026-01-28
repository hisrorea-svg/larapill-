import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/printer_service.dart';
import '../providers/daily_purchase_provider.dart';
import '../widgets/add_product_dialog_purchase.dart';
import '../widgets/purchase_requests_table.dart';

class DailyPurchaseRequestsScreen extends ConsumerStatefulWidget {
  const DailyPurchaseRequestsScreen({super.key});

  @override
  ConsumerState<DailyPurchaseRequestsScreen> createState() =>
      _DailyPurchaseRequestsScreenState();
}

class _DailyPurchaseRequestsScreenState
    extends ConsumerState<DailyPurchaseRequestsScreen> {
  final TextEditingController _supplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تحديث البيانات تلقائياً عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(dailyPurchaseNotifierProvider);
      }
    });
  }

  @override
  void dispose() {
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(dailyPurchaseNotifierProvider);
    final statsAsync = ref.watch(purchaseRequestsStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header مع الإحصائيات في صف واحد
          _buildModernHeader(statsAsync),

          // القائمة
          Expanded(
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dailyPurchaseNotifierProvider);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // ✅ نغلف الجدول بـ Expanded ليأخذ مساحة صحيحة داخل Column
                          Expanded(
                            child: PurchaseRequestsTable(requests: requests),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان والأزرار
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلبية اليوم',
                          style: GoogleFonts.tajawal(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _formatArabicDate(DateTime.now()),
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 22),
                    onPressed: () {
                      ref.invalidate(dailyPurchaseNotifierProvider);
                      ref.invalidate(purchaseRequestsStatsProvider);
                    },
                    tooltip: 'تحديث',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep,
                        color: Colors.white, size: 22),
                    onPressed: _showClearConfirmation,
                    tooltip: 'مسح الكل',
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.print, color: Colors.white, size: 22),
                    onPressed: _printOrder,
                    tooltip: 'طباعة',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // الإحصائيات وزر الإضافة في صف واحد
              Row(
                children: [
                  // الإحصائيات
                  Expanded(
                    child: statsAsync.when(
                      data: (stats) => _buildCompactStats(stats),
                      loading: () => const SizedBox(height: 50),
                      error: (_, __) => const SizedBox(height: 50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر الإضافة الكبير
                  _buildAddButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _showAddProductDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 8),
              Text(
                'إضافة',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStats(Map<String, dynamic> stats) {
    final totalItems = stats['totalItems'] ?? 0;
    final totalQuantity = (stats['totalQuantity'] ?? 0.0).toInt();

    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            totalItems.toString(),
            'الأصناف',
            Icons.shopping_cart_outlined,
            Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            totalQuantity.toString(),
            'الكميات',
            Icons.numbers,
            Colors.green.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.85),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد طلبيات لليوم',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر + لإضافة منتجات',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل الطلبيات',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseProductDialog(),
    );
  }

  void _printOrder() async {
    final requestsAsync = ref.read(dailyPurchaseNotifierProvider);

    await requestsAsync.whenOrNull(
      data: (requests) async {
        if (requests.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا توجد منتجات للطباعة',
                style: GoogleFonts.tajawal(),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        if (!mounted) return;

        // عرض dialog لإدخال اسم المورد
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.print, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Text(
                  'طباعة الطلبية',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسم المورد (اختياري)',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _supplierController,
                  decoration: InputDecoration(
                    hintText: 'أدخل اسم المورد...',
                    hintStyle: GoogleFonts.tajawal(),
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.tajawal(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('إلغاء', style: GoogleFonts.tajawal()),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    // استخدام المعاينة بدلاً من الطباعة المباشرة
                    await PrinterService.instance.previewDailyPurchaseRequests(
                      requests: requests,
                      supplierName: _supplierController.text.trim().isEmpty
                          ? null
                          : _supplierController.text.trim(),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'خطأ في المعاينة: $e',
                            style: GoogleFonts.tajawal(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.preview),
                label: Text('معاينة وطباعة', style: GoogleFonts.tajawal()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(
              'تأكيد المسح',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل تريد مسح جميع طلبيات اليوم؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(dailyPurchaseNotifierProvider.notifier).clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم مسح جميع الطلبيات',
                      style: GoogleFonts.tajawal(),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'مسح الكل',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatArabicDate(DateTime date) {
    const arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    const arabicDays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];

    final dayName = arabicDays[date.weekday - 1];
    final monthName = arabicMonths[date.month - 1];

    return '$dayName، ${date.day} $monthName ${date.year}';
  }
}
