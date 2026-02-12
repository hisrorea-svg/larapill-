import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/services/printer_service.dart';
import '../providers/purchases_drift_providers.dart';
import '../providers/purchases_dashboard_provider.dart';
import '../providers/daily_purchase_provider.dart';
import '../widgets/add_product_dialog_purchase.dart';
import '../widgets/purchase_requests_table.dart';
import 'turbo_entry_screen.dart';
import 'supplier_returns_screen.dart';
import 'supplier_account_screen.dart';
import 'monthly_purchase_report_screen.dart';
import 'low_stock_screen.dart';
import 'smart_stock_settings_screen.dart';
import 'add_supplier_section.dart';

/// أنواع الأقسام المتاحة
enum _DashboardSection {
  todayOrder,
  lowStock,
  receiving,
  returns,
  debts,
  monthlyReport,
  smartSettings,
  addSupplier,
}

/// شاشة المشتريات - تصميم Master-Detail احترافي
class PurchasesDashboardScreen extends ConsumerStatefulWidget {
  const PurchasesDashboardScreen({super.key});

  @override
  ConsumerState<PurchasesDashboardScreen> createState() =>
      _PurchasesDashboardScreenState();
}

class _PurchasesDashboardScreenState
    extends ConsumerState<PurchasesDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _DashboardSection _selectedSection = _DashboardSection.todayOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(dailyPurchaseNotifierProvider);
        ref.invalidate(purchasesDashboardStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(purchasesDashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ============ الشريط الجانبي ============
          _buildSidebar(stats),

          // ============ المحتوى الرئيسي ============
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  /// الشريط الجانبي مع البطاقات
  Widget _buildSidebar(AsyncValue<DashboardStats> statsAsync) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // الهيدر
          _buildSidebarHeader(),

          // البطاقات
          Expanded(
            child: statsAsync.when(
              data: (stats) => _buildSidebarCards(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(fontFamily: 'Tajawal')),
              ),
            ),
          ),

          // الأزرار الإضافية
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  /// هيدر الشريط الجانبي
  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المشتريات',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'إدارة الطلبيات',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              color: AppColors.textSecondary,
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(purchasesDashboardStatsProvider);
                ref.invalidate(dailyPurchaseNotifierProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقات الشريط الجانبي
  Widget _buildSidebarCards(DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // طلبية اليوم
          _SidebarCard(
            title: 'طلبية اليوم',
            icon: Icons.shopping_cart_outlined,
            color: AppColors.primary,
            isSelected: _selectedSection == _DashboardSection.todayOrder,
            onTap: () =>
                setState(() => _selectedSection = _DashboardSection.todayOrder),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(height: 1),
          ),

          // النواقص
          _SidebarCard(
            title: 'النواقص',
            subtitle: 'بحاجة للطلب',
            value: stats.lowStockCount.toString(),
            icon: Icons.inventory_2_outlined,
            color: Colors.orange,
            isSelected: _selectedSection == _DashboardSection.lowStock,
            onTap: () =>
                setState(() => _selectedSection = _DashboardSection.lowStock),
          ),

          // الاستلام
          _SidebarCard(
            title: 'الاستلام',
            subtitle: 'بانتظار الجرد',
            value: stats.pendingInvoices.toString(),
            icon: Icons.receipt_long_outlined,
            color: Colors.blue,
            isSelected: _selectedSection == _DashboardSection.receiving,
            onTap: () =>
                setState(() => _selectedSection = _DashboardSection.receiving),
          ),

          // المرتجعات
          _SidebarCard(
            title: 'المرتجعات',
            subtitle: 'جاهزة للتسليم',
            value: _formatCurrency(stats.pendingReturnsAmount),
            icon: Icons.swap_horiz,
            color: Colors.purple,
            isSelected: _selectedSection == _DashboardSection.returns,
            onTap: () =>
                setState(() => _selectedSection = _DashboardSection.returns),
          ),

          // المستحقات
          _SidebarCard(
            title: 'مستحقات المذاخر',
            subtitle: _buildDebtSubtitle(stats),
            value: _formatCurrency(stats.totalDebt),
            icon: Icons.account_balance_wallet_outlined,
            color: stats.hasOverdueDebt ? Colors.red : Colors.green,
            isSelected: _selectedSection == _DashboardSection.debts,
            onTap: () =>
                setState(() => _selectedSection = _DashboardSection.debts),
          ),
        ],
      ),
    );
  }

  /// فوتر الشريط الجانبي
  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          _buildFooterButton(
            icon: Icons.person_add_alt_1_outlined,
            label: 'إضافة مورد جديد',
            onTap: () => setState(
                () => _selectedSection = _DashboardSection.addSupplier),
            active: _selectedSection == _DashboardSection.addSupplier,
          ),
          const SizedBox(height: 8),
          _buildFooterButton(
            icon: Icons.analytics_outlined,
            label: 'التقرير الشهري',
            onTap: () => setState(
                () => _selectedSection = _DashboardSection.monthlyReport),
            active: _selectedSection == _DashboardSection.monthlyReport,
          ),
          const SizedBox(height: 8),
          _buildFooterButton(
            icon: Icons.tune,
            label: 'إعدادات الحد الأدنى',
            onTap: () => setState(
                () => _selectedSection = _DashboardSection.smartSettings),
            active: _selectedSection == _DashboardSection.smartSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: active ? AppColors.primary : AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  /// المحتوى الرئيسي
  Widget _buildMainContent() {
    return Column(
      children: [
        // هيدر المحتوى - يتم إخفاؤه في قسم الاستلام (إدخال سريع) لتجنب التكرار
        if (_selectedSection != _DashboardSection.receiving)
          _buildContentHeader(),

        // المحتوى
        Expanded(
          child: _buildSectionContent(),
        ),
      ],
    );
  }

  /// هيدر المحتوى الرئيسي
  Widget _buildContentHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // عنوان القسم
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSectionIcon(),
                  color: _getSectionColor(),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _getSectionTitle(),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // شريط البحث للنواقص - يظهر بجانب العنوان
            // شريط البحث (يأخذ المساحة المتبقية)
            if (_selectedSection == _DashboardSection.lowStock ||
                _selectedSection == _DashboardSection.todayOrder) ...[
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: _selectedSection == _DashboardSection.lowStock
                          ? 'بحث في النواقص (الاسم، الشركة)...'
                          : 'البحث في المنتجات...',
                      hintStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // أدوات القسم (إحصائيات + أزرار)
              if (_selectedSection == _DashboardSection.lowStock)
                _buildLowStockActions()
              else
                _buildRequestsActions(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(height: 24, width: 1, color: AppColors.border),
              ),
            ] else ...[
              const Spacer(),
            ],

            // أزرار الهيدر حسب القسم
            _buildContentHeaderActions(),
          ],
        ),
      ),
    );
  }

  /// أدوات طلبية اليوم (إحصائيات + زر إضافة)
  Widget _buildRequestsActions() {
    final statsAsync = ref.watch(purchaseRequestsStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // إحصائية الأصناف
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${stats['totalItems'] ?? 0} صنف',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // إحصائية الكمية
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.numbers, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${(stats['totalQuantity'] ?? 0.0).toInt()} كمية',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // زر إضافة منتج
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'إضافة منتج',
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// أدوات النواقص (إحصائيات + أزرار)
  Widget _buildLowStockActions() {
    final productsAsync = ref.watch(lowStockProductsProvider);

    return productsAsync.when(
      data: (products) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // إحصائية العدد
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${products.length} ناقص',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // زر إضافة الكل
            if (products.isNotEmpty)
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _addAllLowStockToOrder(products),
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  label: const Text(
                    'إضافة الكل للطلبية',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// إضافة جميع النواقص للطلبية
  Future<void> _addAllLowStockToOrder(List<LowStockProduct> products) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الإضافة',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: Text(
          'هل تريد إضافة جميع النواقص (${products.length} منتج) للطلبية؟',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة الكل',
                style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int addedCount = 0;
    int skippedCount = 0;

    for (final product in products) {
      try {
        await ref.read(dailyPurchaseNotifierProvider.notifier).addManualRequest(
              productId: product.id,
              productName: product.name,
              quantity: product.deficit > 0 ? product.deficit : 1,
              unit: product.baseUnit,
            );
        addedCount++;
      } catch (e) {
        skippedCount++;
      }
    }

    if (!mounted) return;
    AppToast.success(context,
        'تمت إضافة $addedCount منتج للطلبية${skippedCount > 0 ? ' (تم تخطي $skippedCount موجود مسبقاً)' : ''}');
  }

  /// أزرار هيدر المحتوى
  Widget _buildContentHeaderActions() {
    return Row(
      children: [
        if (_selectedSection == _DashboardSection.todayOrder) ...[
          _buildHeaderIconButton(
            icon: Icons.delete_sweep,
            tooltip: 'مسح الكل',
            color: AppColors.error,
            onPressed: _showClearConfirmation,
          ),
          const SizedBox(width: 8),
          _buildHeaderIconButton(
            icon: Icons.print,
            tooltip: 'طباعة',
            onPressed: _printOrder,
          ),
          const SizedBox(width: 8),
          _buildHeaderIconButton(
            icon: Icons.table_chart_outlined,
            tooltip: 'تصدير Excel',
            color: Colors.green,
            onPressed: _exportToExcel,
          ),
          const SizedBox(width: 8),
          _buildHeaderIconButton(
            icon: Icons.share,
            tooltip: 'WhatsApp',
            color: const Color(0xFF25D366),
            onPressed: _shareViaWhatsApp,
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: (color ?? AppColors.textSecondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child:
                Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
          ),
        ),
      ),
    );
  }

  /// محتوى القسم المحدد
  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case _DashboardSection.todayOrder:
        return _buildTodayOrderContent();
      case _DashboardSection.lowStock:
        return _buildEmbeddedLowStock();
      case _DashboardSection.receiving:
        return _buildEmbeddedReceiving();
      case _DashboardSection.returns:
        return _buildEmbeddedReturns();
      case _DashboardSection.debts:
        return _buildEmbeddedDebts();
      case _DashboardSection.monthlyReport:
        return const MonthlyPurchaseReportScreen(isEmbedded: true);
      case _DashboardSection.smartSettings:
        return const SmartStockSettingsScreen(isEmbedded: true);
      case _DashboardSection.addSupplier:
        return const AddSupplierSection();
    }
  }

  /// محتوى طلبية اليوم
  Widget _buildTodayOrderContent() {
    final requestsAsync = ref.watch(dailyPurchaseNotifierProvider);

    return Column(
      children: [
        // الجدول
        Expanded(
          child: requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return _buildEmptyState();
              }
              final filteredRequests = _searchQuery.isEmpty
                  ? requests
                  : requests
                      .where((r) => r.productName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: PurchaseRequestsTable(requests: filteredRequests),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(error.toString()),
          ),
        ),
      ],
    );
  }

  /// محتوى النواقص مضمّن
  Widget _buildEmbeddedLowStock() {
    return LowStockScreen(embedded: true, searchQuery: _searchQuery);
  }

  /// محتوى الاستلام مضمّن
  Widget _buildEmbeddedReceiving() {
    return const TurboEntryScreen(embedded: true);
  }

  /// محتوى المرتجعات مضمّن
  Widget _buildEmbeddedReturns() {
    return const SupplierReturnsScreen(embedded: true);
  }

  /// محتوى المستحقات مضمّن
  Widget _buildEmbeddedDebts() {
    final suppliersAsync = ref.watch(activeSuppliersProvider);

    return suppliersAsync.when(
      data: (suppliers) {
        if (suppliers.isEmpty) {
          return const Center(
            child:
                Text('لا يوجد موردين', style: TextStyle(fontFamily: 'Tajawal')),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            final supplier = suppliers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    supplier.name.isNotEmpty ? supplier.name[0] : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontFamily: 'Tajawal'),
                  ),
                ),
                title: Text(supplier.name,
                    style: const TextStyle(
                        fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                subtitle: Text(supplier.paymentTypeLabel,
                    style:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupplierAccountScreen(
                      supplierId: supplier.id,
                      supplierName: supplier.name,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('خطأ في تحميل الموردين',
            style: TextStyle(fontFamily: 'Tajawal')),
      ),
    );
  }

  // ============ Helpers ============

  IconData _getSectionIcon() {
    switch (_selectedSection) {
      case _DashboardSection.todayOrder:
        return Icons.shopping_cart_outlined;
      case _DashboardSection.lowStock:
        return Icons.inventory_2_outlined;
      case _DashboardSection.receiving:
        return Icons.receipt_long_outlined;
      case _DashboardSection.returns:
        return Icons.swap_horiz;
      case _DashboardSection.debts:
        return Icons.account_balance_wallet_outlined;
      case _DashboardSection.monthlyReport:
        return Icons.analytics_outlined;
      case _DashboardSection.smartSettings:
        return Icons.tune;
      case _DashboardSection.addSupplier:
        return Icons.person_add_alt_1;
    }
  }

  Color _getSectionColor() {
    switch (_selectedSection) {
      case _DashboardSection.todayOrder:
        return AppColors.primary;
      case _DashboardSection.lowStock:
        return Colors.orange;
      case _DashboardSection.receiving:
        return Colors.blue;
      case _DashboardSection.returns:
        return Colors.purple;
      case _DashboardSection.debts:
        return Colors.green;
      case _DashboardSection.monthlyReport:
        return Colors.blue;
      case _DashboardSection.smartSettings:
        return Colors.purple;
      case _DashboardSection.addSupplier:
        return Colors.teal;
    }
  }

  String _getSectionTitle() {
    switch (_selectedSection) {
      case _DashboardSection.todayOrder:
        return 'طلبية اليوم';
      case _DashboardSection.lowStock:
        return 'النواقص';
      case _DashboardSection.receiving:
        return 'إدخال سريع';
      case _DashboardSection.returns:
        return 'المرتجعات';
      case _DashboardSection.debts:
        return 'كشف حساب الموردين';
      case _DashboardSection.monthlyReport:
        return 'التقرير الشهري';
      case _DashboardSection.smartSettings:
        return 'الحد الأدنى الذكي';
      case _DashboardSection.addSupplier:
        return 'إضافة مورد جديد';
    }
  }

  /// الحالة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبيات لليوم',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على "إضافة منتج" لبدء طلبية جديدة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// حالة الخطأ
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.invalidate(dailyPurchaseNotifierProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _buildDebtSubtitle(DashboardStats data) {
    final parts = <String>[];
    if (data.cashDebt > 0) {
      parts.add('نقد: ${_formatCurrency(data.cashDebt)}');
    }
    if (data.monthlyDebt > 0) {
      parts.add('شهري: ${_formatCurrency(data.monthlyDebt)}');
    }
    if (data.creditDebt > 0) {
      parts.add('آجل: ${_formatCurrency(data.creditDebt)}');
    }
    return parts.isEmpty ? 'لا توجد مستحقات' : parts.join(' | ');
  }

  // ============ Actions ============

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseProductDialog(),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد المسح',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من مسح جميع المنتجات؟',
            style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(dailyPurchaseNotifierProvider.notifier).clearAll();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child:
                const Text('مسح الكل', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
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
        await PrinterService.instance
            .printDailyPurchaseRequests(requests: requests);
      },
    );
  }

  void _exportToExcel() {
    AppToast.info(context, 'جاري التصدير...');
  }

  void _shareViaWhatsApp() async {
    final requestsAsync = ref.read(dailyPurchaseNotifierProvider);
    await requestsAsync.whenOrNull(
      data: (requests) async {
        if (requests.isEmpty) {
          if (!mounted) return;
          AppToast.warning(context, 'لا توجد منتجات للمشاركة');
          return;
        }
        final buffer = StringBuffer();
        buffer.writeln('📋 طلبية اليوم');
        buffer.writeln('━━━━━━━━━━━━━━');
        for (int i = 0; i < requests.length; i++) {
          final r = requests[i];
          buffer.writeln(
              '${i + 1}. ${r.productName} - ${r.requestedQuantity.toInt()} ${r.unit ?? ''}');
        }
        buffer.writeln('━━━━━━━━━━━━━━');
        buffer.writeln('📦 إجمالي: ${requests.length} صنف');
        await Clipboard.setData(ClipboardData(text: buffer.toString()));
        if (!mounted) return;
        if (!mounted) return;
        AppToast.success(context, 'تم نسخ الطلبية!');
      },
    );
  }
}

/// بطاقة الشريط الجانبي
class _SidebarCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarCard({
    required this.title,
    this.subtitle,
    this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarCard> createState() => _SidebarCardState();
}

class _SidebarCardState extends State<_SidebarCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || isHovered;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // الأيقونة
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: isActive ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: widget.isSelected
                            ? widget.color
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 9,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // الرقم
              if (widget.value != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.value!,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
