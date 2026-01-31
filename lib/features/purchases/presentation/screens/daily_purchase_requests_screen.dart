import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/services/printer_service.dart';
import '../providers/daily_purchase_provider.dart';
import '../widgets/add_product_dialog_purchase.dart';
import '../widgets/purchase_requests_table.dart';
import '../widgets/shared_header_widgets.dart';

class DailyPurchaseRequestsScreen extends ConsumerStatefulWidget {
  const DailyPurchaseRequestsScreen({super.key});

  @override
  ConsumerState<DailyPurchaseRequestsScreen> createState() =>
      _DailyPurchaseRequestsScreenState();
}

class _DailyPurchaseRequestsScreenState
    extends ConsumerState<DailyPurchaseRequestsScreen> {
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(dailyPurchaseNotifierProvider);
      }
    });
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _searchController.dispose();
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
          _buildModernHeader(statsAsync),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + Actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'طلبية اليوم',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatArabicDate(DateTime.now()),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.refresh,
                    tooltip: 'تحديث',
                    onPressed: () {
                      ref.invalidate(dailyPurchaseNotifierProvider);
                      ref.invalidate(purchaseRequestsStatsProvider);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete_sweep,
                    tooltip: 'مسح الكل',
                    color: AppColors.error,
                    onPressed: _showClearConfirmation,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.print,
                    tooltip: 'طباعة',
                    color: AppColors.secondary,
                    onPressed: _printOrder,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.table_chart_outlined,
                    tooltip: 'تصدير Excel',
                    color: Colors.green,
                    onPressed: _exportToExcel,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.share,
                    tooltip: 'إرسال',
                    color: const Color(0xFF25D366),
                    onPressed: _shareViaWhatsApp,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row 2: Stats + Search + Add Button
              Row(
                children: [
                  statsAsync.when(
                    data: (stats) => _buildCompactStats(stats),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 12),
                  _buildAddButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final btnColor = color ?? AppColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: btnColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: btnColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: btnColor, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return UnifiedSearchBar(
      controller: _searchController,
      hintText: 'بحث في المنتجات...',
    );
  }

  Widget _buildAddButton() {
    return UnifiedPrimaryButton(
      icon: Icons.add,
      label: 'إضافة منتج',
      onPressed: _showAddProductDialog,
    );
  }

  Widget _buildCompactStats(Map<String, dynamic> stats) {
    final totalItems = stats['totalItems'] ?? 0;
    final totalQuantity = (stats['totalQuantity'] ?? 0.0).toInt();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatBadge('$totalItems', 'صنف', Colors.blue),
        const SizedBox(width: 8),
        _buildStatBadge('$totalQuantity', 'كمية', Colors.green),
      ],
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '# $value',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: color),
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
          const Text(
            'لا توجد طلبيات لليوم',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على زر + لإضافة منتجات',
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

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل الطلبيات',
            style: TextStyle(
              fontFamily: 'Tajawal',
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
          AppToast.warning(context, 'لا توجد منتجات للطباعة');
          return;
        }

        if (!mounted) return;

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
                const Text(
                  'طباعة الطلبية',
                  style: TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اسم المورد (اختياري)',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _supplierController,
                  decoration: InputDecoration(
                    hintText: 'أدخل اسم المورد...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Tajawal',
                    ),
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                    )),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await PrinterService.instance.previewDailyPurchaseRequests(
                      requests: requests,
                      supplierName: _supplierController.text.trim().isEmpty
                          ? null
                          : _supplierController.text.trim(),
                    );
                  } catch (e) {
                    if (mounted) {
                      AppToast.error(context, 'خطأ في المعاينة: $e');
                    }
                  }
                },
                icon: const Icon(Icons.preview),
                label: const Text('معاينة وطباعة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                    )),
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: 8),
            Text(
              'تأكيد المسح',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'هل تريد مسح جميع طلبيات اليوم؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(
            fontFamily: 'Tajawal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(dailyPurchaseNotifierProvider.notifier).clearAll();
              if (mounted) {
                AppToast.success(context, 'تم مسح جميع الطلبيات');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'مسح الكل',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _exportToExcel() async {
    final requestsAsync = ref.read(dailyPurchaseNotifierProvider);

    await requestsAsync.whenOrNull(
      data: (requests) async {
        if (requests.isEmpty) {
          if (!mounted) return;
          AppToast.warning(context, 'لا توجد منتجات للتصدير');
          return;
        }

        try {
          final StringBuffer csv = StringBuffer();
          csv.writeln('اسم المنتج,الوحدة,الكمية');

          for (final request in requests) {
            csv.writeln(
                '${request.productName},${request.unit ?? ""},${request.requestedQuantity}');
          }

          await Clipboard.setData(ClipboardData(text: csv.toString()));

          if (mounted) {
            AppToast.success(context, 'تم نسخ البيانات إلى الحافظة بتنسيق CSV');
          }
        } catch (e) {
          if (mounted) {
            AppToast.error(context, 'خطأ في التصدير: $e');
          }
        }
      },
    );
  }

  void _shareViaWhatsApp() async {
    final requestsAsync = ref.read(dailyPurchaseNotifierProvider);

    await requestsAsync.whenOrNull(
      data: (requests) async {
        if (requests.isEmpty) {
          if (!mounted) return;
          AppToast.warning(context, 'لا توجد منتجات للإرسال');
          return;
        }

        final StringBuffer message = StringBuffer();
        message.writeln('📋 *طلبية اليوم*');
        message.writeln('📅 ${_formatArabicDate(DateTime.now())}');
        message.writeln('─────────────');

        for (int i = 0; i < requests.length; i++) {
          final request = requests[i];
          message.writeln(
              '${i + 1}. ${request.productName} - ${request.requestedQuantity.toInt()} ${request.unit ?? ""}');
        }

        message.writeln('─────────────');
        message.writeln('📦 إجمالي الأصناف: ${requests.length}');

        await Clipboard.setData(ClipboardData(text: message.toString()));

        if (mounted) {
          AppToast.success(context, 'تم نسخ الرسالة! افتح WhatsApp والصقها');
        }
      },
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
