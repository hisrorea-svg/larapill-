import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/services/product_velocity_analyzer.dart';
import '../widgets/shared_header_widgets.dart';

/// شاشة الإعدادات الذكية للحد الأدنى (متناسقة مع باقي التطبيق)
class SmartStockSettingsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const SmartStockSettingsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<SmartStockSettingsScreen> createState() =>
      _SmartStockSettingsScreenState();
}

class _SmartStockSettingsScreenState
    extends ConsumerState<SmartStockSettingsScreen> {
  bool _isAnalyzing = false;
  bool _isApplying = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsVelocityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productsAsync.when(
        data: (products) {
          final filteredProducts = _searchQuery.isEmpty
              ? products
              : products
                  .where((p) => p.productName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          final needsUpdateCount =
              products.where((p) => p.needsAdjustment).length;
          final fastMovingCount = products
              .where((p) =>
                  p.velocityCategory == 'fast' ||
                  p.velocityCategory == 'very_fast')
              .length;

          return Column(
            children: [
              // Header موحد صف واحد
              _buildModernHeader(
                  products.length, needsUpdateCount, fastMovingCount),

              // الجدول
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                Expanded(
                                    child:
                                        _buildProductsTable(filteredProducts)),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildModernHeader(int total, int needsUpdate, int fastMoving) {
    return UnifiedEmbeddedHeader(
      stats: [
        UnifiedStatBadge(
          value: '$total',
          label: 'الكل',
          color: Colors.blue,
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(width: 8),
        UnifiedStatBadge(
          value: '$needsUpdate',
          label: 'مراجعة',
          color: Colors.orange,
          icon: Icons.sync_problem,
        ),
        const SizedBox(width: 8),
        UnifiedStatBadge(
          value: '$fastMoving',
          label: 'سريعة',
          color: Colors.red,
          icon: Icons.local_fire_department_outlined,
        ),
      ],
      searchBar: UnifiedSearchBar(
        controller: _searchController,
        hintText: 'بحث سريع...',
        onChanged: (val) => setState(() => _searchQuery = val),
        onClear: () => setState(() => _searchQuery = ''),
      ),
      actions: [
        UnifiedActionButton(
          icon: Icons.refresh,
          tooltip: 'تحديث',
          isLoading: _isAnalyzing,
          onPressed: _analyzeAllProducts,
        ),
        const SizedBox(width: 8),
        UnifiedPrimaryButton(
          icon: Icons.auto_fix_high,
          label: 'تطبيق الكل',
          isLoading: _isApplying,
          onPressed: _applySmartSettings,
        ),
      ],
    );
  }

  Widget _buildProductsTable(List<ProductVelocityData> products) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 60,
            columnSpacing: 24,
            horizontalMargin: 24,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(
                  label: Text('المنتج',
                      style: TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('التصنيف',
                      style: TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('الحالي',
                      style: TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                  numeric: true),
              DataColumn(
                  label: Text('المقترح',
                      style: TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                  numeric: true),
              DataColumn(
                  label: Text('الفرق',
                      style: TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('إجراء',
                      style: TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
            ],
            rows: products.map((p) => _buildProductRow(p)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildProductRow(ProductVelocityData product) {
    final diff =
        (product.recommendedMinStock - product.currentMinStock).toInt();
    final isIdeal = diff == 0;

    return DataRow(
      cells: [
        // Name
        DataCell(
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(product.productName,
                    style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                Text('مبيعات: ${product.avgDailySales.toStringAsFixed(1)} /يوم',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
        // Velocity Badge
        DataCell(_VelocityBadge(
            category: product.velocityCategory, label: product.velocityLabel)),
        // Current
        DataCell(Text('${product.currentMinStock.toInt()}',
            style: const TextStyle(fontFamily: 'Tajawal'))),
        // Recommended
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isIdeal
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${product.recommendedMinStock.toInt()}',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: isIdeal ? Colors.black87 : AppColors.primary)),
        )),
        // Difference
        DataCell(isIdeal
            ? const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16, color: diff > 0 ? Colors.blue : Colors.orange),
                  const SizedBox(width: 4),
                  Text('${diff.abs()}',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: diff > 0 ? Colors.blue : Colors.orange)),
                ],
              )),
        // Action
        DataCell(
          product.needsAdjustment
              ? IconButton(
                  icon:
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  tooltip: 'تطبيق التعديل',
                  onPressed: () => _applySingleProduct(product.productId),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Actions
  Future<void> _analyzeAllProducts() async {
    setState(() => _isAnalyzing = true);
    try {
      ref.invalidate(allProductsVelocityProvider);
      if (mounted) AppToast.success(context, 'تم تحديث التحليل');
    } catch (e) {
      if (mounted) AppToast.error(context, 'خطأ: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _applySmartSettings() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('تأكيد التطبيق',
                  style: TextStyle(fontFamily: 'Tajawal')),
              content: const Text(
                  'سيتم تحديث الحد الأدنى للمخزون لجميع المنتجات.\nهل أنت متأكد؟',
                  style: TextStyle(fontFamily: 'Tajawal')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('إلغاء')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('نعم، تطبيق')),
              ],
            ));
    if (confirm != true) return;

    setState(() => _isApplying = true);
    try {
      final analyzer = ref.read(productVelocityAnalyzerProvider);
      final result = await analyzer.applySmartMinStockToAll(autoApply: true);
      if (mounted) {
        AppToast.success(context, 'تم تحديث ${result['updated']} منتج');
      }
      ref.invalidate(allProductsVelocityProvider);
    } catch (e) {
      if (mounted) AppToast.error(context, 'خطأ: $e');
    } finally {
      setState(() => _isApplying = false);
    }
  }

  Future<void> _applySingleProduct(String id) async {
    try {
      final analyzer = ref.read(productVelocityAnalyzerProvider);
      await analyzer.applySmartMinStock(id, autoApply: true);
      if (mounted) AppToast.success(context, 'تم التحديث');
      ref.invalidate(allProductsVelocityProvider);
    } catch (e) {
      if (mounted) AppToast.error(context, 'خطأ: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text('لا توجد منتجات',
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey))
    ]));
  }

  Widget _buildErrorState(String e) => Center(child: Text('خطأ: $e'));
}

class _VelocityBadge extends StatelessWidget {
  final String category;
  final String label;
  const _VelocityBadge({required this.category, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color = category == 'fast' || category == 'very_fast'
        ? Colors.red
        : (category == 'medium' ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'Tajawal',
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}
