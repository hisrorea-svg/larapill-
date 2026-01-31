import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../core/utils/input_sanitizer.dart';
import '../../../../core/models/barcode_type.dart';
import '../../../../core/models/barcode_label_size.dart';
import '../../../../core/validators/barcode_validator.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_filters.dart';
import '../widgets/professional_edit_product_dialog.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/inventory_stats_widget.dart';
import '../widgets/barcode_preview_widget.dart';
import '../../../../core/services/pharmacy_settings_service.dart';
import '../../domain/entities/product_entity.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    // تحديث البيانات تلقائياً عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Reset filters and refresh data
        ref.read(currentPageProvider.notifier).state = 0;
        ref.invalidate(paginatedProductsResultProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the Controller directly
    final productsState = ref.watch(inventoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            SizedBox(
              height: 140, // ✅ نفس الارتفاع للكل
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. كارت "إدارة المخزون"
                  Expanded(
                    flex: 2, // ✅ تصغير شوي (كان 3)
                    child: _buildHeader(context, ref),
                  ),
                  const SizedBox(width: 16),

                  // 2. الكارتات الخمسة
                  const Expanded(
                    flex: 5, // ✅ مساحة أكبر للكارتات
                    child: InventoryStatsWidget(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Filters
            InventoryFilters(
              onSearchChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
                ref.read(currentPageProvider.notifier).state = 0;
              },
              onAdvancedFilterChanged: (filter) {
                ref.read(advancedFilterProvider.notifier).state = filter;
                ref.read(currentPageProvider.notifier).state = 0;
              },
            ),

            const SizedBox(height: 16),

            // Table
            Expanded(
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
                child: productsState.when(
                  data: (data) {
                    if (data.items.isEmpty) {
                      return _buildEmptyState(context, ref);
                    }
                    return Column(
                      children: [
                        // ✅ DataTable2 داخل Expanded
                        Expanded(
                          child: _buildDataTable(context, ref, data.items),
                        ),
                        const SizedBox(height: 12),
                        if (data.totalPages > 1)
                          _buildPaginationControls(ref, data.currentPage,
                              data.totalPages, data.totalCount),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('خطأ في تحميل البيانات\n$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Tajawal', color: AppColors.error)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        // ✅ استخدم Stack لإضافة الخطوط فوق المحتوى
        children: [
          // ✅ الخطوط المنحنية في الخلفية
          Positioned.fill(
            child: CustomPaint(
              painter: DecorativeCurvesPainter(),
            ),
          ),

          // المحتوى الأصلي
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    // إعادة تحميل المنتجات
                    // Force refresh the specific controller provider
                    ref.invalidate(inventoryControllerProvider);
                    ref.read(currentPageProvider.notifier).state = 0;

                    // Also refresh summary stats if needed (productsProvider was used for that maybe?)
                    // But sticking to controller logic

                    // Feedback صغير
                    if (ScaffoldMessenger.maybeOf(context) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث البيانات',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                              )),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                const Icon(Icons.inventory_2, color: Colors.white),
                const SizedBox(width: 8),
                const Text('إدارة المخزون',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
              ]),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('اضافة منتج جديد',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('لا توجد منتجات بعد',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول منتج'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }

  // DataTable
  Widget _buildDataTable(
      BuildContext context, WidgetRef ref, List<ProductEntity> products) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 1000, // ✅ زيادة شوية عشان التكلفة
      headingRowHeight: 52,
      dataRowHeight: 45,
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      headingRowColor: WidgetStateProperty.all(
        AppColors.primary.withValues(alpha: 0.1),
      ),
      dataRowColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.1);
          }
          return null;
        },
      ),
      columns: const [
        DataColumn2(
          label: Center(
            child: Text(
              'ت',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          fixedWidth: 35,
        ),
        DataColumn2(
          label: Center(
            child: Text(
              'اسم المنتج',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Center(
            child: Text(
              'الشركة',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          size: ColumnSize.S,
        ),

        DataColumn2(
          label: Center(
            child: Text(
              'الكمية',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          fixedWidth: 70,
        ),
        // ✅ عمود التكلفة (جديد)
        DataColumn2(
          label: Center(
            child: Text(
              'التكلفة',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          fixedWidth: 100,
        ),
        DataColumn2(
          label: Center(
            child: Text(
              'السعر',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          fixedWidth: 100,
        ),
        DataColumn2(
          label: Center(
            child: Text(
              'الصلاحية',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          fixedWidth: 100,
        ),
        DataColumn2(
          label: Center(
            child: Text(
              'الإجراءات',
              style:
                  TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
          fixedWidth: 100,
        ),
      ],
      rows: products.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final product = entry.value;

        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.grey.shade50 : Colors.white,
          ),
          cells: [
            DataCell(
              Center(
                child: Text(
                  index.toString(),
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                ),
              ),
            ),

            // ✅ اسم المنتج - مصغّر
            DataCell(
              Center(
                child: SizedBox(
                  width: 190, // ✅ تصغير من 250 إلى 180
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13, // ✅ تصغير من 14 إلى 13
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            DataCell(
              Center(
                child: Text(
                  product.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            DataCell(
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.quantity > 10
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.quantity.toString(),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: product.quantity > 10 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ✅ التكلفة (جديد)
            DataCell(
              Center(
                child: Text(
                  product.costPrice != null
                      ? '${product.costPrice!.toStringAsFixed(0)} د.ع'
                      : 'غير محدد',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: product.costPrice != null
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // السعر
            DataCell(
              Center(
                child: Text(
                  '${product.price.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            DataCell(
              Center(
                child: Text(
                  product.expiryDate != null
                      ? '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}'
                      : 'غير محدد',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            DataCell(
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'تعديل',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 25, minHeight: 32),
                      icon: const Icon(Icons.edit,
                          color: Colors.blueAccent, size: 15),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => ProfessionalEditProductDialog(
                            productId: product.id.toString(),
                            onProductUpdated: () {
                              ref.invalidate(inventoryControllerProvider);
                            },
                          ),
                        );
                        // Ensure refresh
                        ref.invalidate(inventoryControllerProvider);
                      },
                    ),
                    IconButton(
                      tooltip: 'طباعة باركود',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 25, minHeight: 32),
                      icon: const Icon(Icons.print,
                          color: Colors.blueGrey, size: 15),
                      onPressed: () => _showPrintBarcodeDialog(
                        context,
                        product,
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 25, minHeight: 32),
                      icon: const Icon(Icons.delete,
                          color: Colors.redAccent, size: 15),
                      onPressed: () =>
                          _confirmDeleteDialog(context, ref, product),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPaginationControls(
      WidgetRef ref, int currentPage, int totalPages, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: currentPage > 0
                ? () => ref.read(currentPageProvider.notifier).state--
                : null,
            icon: const Icon(Icons.chevron_left)),
        Text('صفحة ${currentPage + 1} من $totalPages'),
        IconButton(
            onPressed: currentPage < totalPages - 1
                ? () => ref.read(currentPageProvider.notifier).state++
                : null,
            icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const SimpleAddProductDialog(),
    ).then((_) {
      // Invalidate the controller to refresh data after add
      ref.invalidate(inventoryControllerProvider);
    });
  }

  /// حوار تأكيد الحذف: هل تريد حذف المنتج؟ نعم/لا
  Future<void> _confirmDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هل تريد حذف المنتج؟',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: Text(product.name,
            style: const TextStyle(
              fontFamily: 'Tajawal',
            )),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر الإلغاء ( Cancel)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                ),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'لا',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ),

              // زر الموافقة )
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'نعم',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );

    if (confirm == true) {
      try {
        // ✅ Use Controller for deletion (Reactive)
        await ref
            .read(inventoryControllerProvider.notifier)
            .deleteProduct(product.id);

        // No manual invalidation needed here if controller handles it (invalidateSelf)

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المنتج بنجاح',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف المنتج: $e',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                )),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// عرض حوار طباعة الباركود الاحترافي
  void _showPrintBarcodeDialog(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (_) => _PrintBarcodeDialog(product: product),
    );
  }
}

/// حوار طباعة باركود احترافي
class _PrintBarcodeDialog extends StatefulWidget {
  final ProductEntity product;

  const _PrintBarcodeDialog({required this.product});

  @override
  State<_PrintBarcodeDialog> createState() => _PrintBarcodeDialogState();
}

class _PrintBarcodeDialogState extends State<_PrintBarcodeDialog> {
  late BarcodeType _selectedBarcodeType;
  late BarcodeLabelSize _selectedLabelSize;
  late String _sanitizedBarcode;
  int _copies = 1;
  bool _includePrice = false;
  ValidationResult? _validationResult;
  String? _pharmacyName;

  @override
  void initState() {
    super.initState();
    _sanitizedBarcode = InputSanitizer.sanitizeBarcode(widget.product.barcode);
    _selectedBarcodeType = BarcodeValidator.suggestType(_sanitizedBarcode);
    _selectedLabelSize = BarcodeLabelSize.standard;
    _validateBarcode();
    _loadPharmacyName();
  }

  Future<void> _loadPharmacyName() async {
    try {
      final name = await PharmacySettingsService.instance.getPharmacyNameAr();
      if (mounted) {
        setState(() {
          _pharmacyName = name;
        });
      }
    } catch (_) {
      // ignore errors, leave pharmacy name null
    }
  }

  void _validateBarcode() {
    setState(() {
      _validationResult =
          BarcodeValidator.validate(_sanitizedBarcode, _selectedBarcodeType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasValidBarcode = _sanitizedBarcode.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات المنتج
                    _buildProductInfo(),
                    const SizedBox(height: 20),

                    // نوع الباركود
                    _buildBarcodeTypeDropdown(),
                    const SizedBox(height: 16),

                    // حجم الملصق
                    _buildLabelSizeDropdown(),
                    const SizedBox(height: 16),

                    // خيارات إضافية
                    _buildAdditionalOptions(),
                    const SizedBox(height: 16),

                    // عدد النسخ
                    _buildCopiesField(),
                    const SizedBox(height: 20),

                    // تحذير validation
                    if (_validationResult != null &&
                        !_validationResult!.isValid)
                      _buildValidationWarning(),

                    // معاينة الباركود - فقط إذا كان الباركود صحيح
                    if (hasValidBarcode &&
                        (_validationResult == null ||
                            _validationResult!.isValid)) ...[
                      const SizedBox(height: 20),
                      _buildBarcodePreview(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(hasValidBarcode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.print, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'طباعة باركود',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'الباركود: ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _sanitizedBarcode.isEmpty ? 'غير متوفر' : _sanitizedBarcode,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _sanitizedBarcode.isEmpty
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (widget.product.price > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'السعر: ',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${widget.product.price.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarcodeTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع الباركود',
          style: TextStyle(
              fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<BarcodeType>(
          initialValue: _selectedBarcodeType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          selectedItemBuilder: (context) {
            return BarcodeType.values.map((type) {
              return Text(
                type.displayName,
                style: const TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              );
            }).toList();
          },
          items: BarcodeType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.displayName,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    type.description,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedBarcodeType = value;
                _sanitizedBarcode =
                    BarcodeValidator.sanitize(widget.product.barcode, value);
                _validateBarcode();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLabelSizeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حجم الملصق',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<BarcodeLabelSize>(
          initialValue: _selectedLabelSize,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          selectedItemBuilder: (context) {
            return BarcodeLabelSize.values.map((size) {
              return Text(
                size.displayName,
                style: const TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              );
            }).toList();
          },
          items: BarcodeLabelSize.values.map((size) {
            return DropdownMenuItem(
              value: size,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    size.displayName,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    size.description,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLabelSize = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'خيارات إضافية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text(
            'إضافة السعر على الملصق',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          ),
          subtitle: widget.product.price > 0
              ? Text(
                  '${widget.product.price.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                )
              : null,
          value: _includePrice,
          onChanged: widget.product.price > 0
              ? (value) {
                  setState(() {
                    _includePrice = value ?? false;
                  });
                }
              : null,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildCopiesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'عدد النسخ',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _copies.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: 'أدخل عدد النسخ',
          ),
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n > 0 && n <= 100) {
              setState(() {
                _copies = n;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildValidationWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _validationResult!.message,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'معاينة الملصق',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: BarcodePreviewWidget(
            barcode: _sanitizedBarcode,
            barcodeType: _selectedBarcodeType,
            productName: widget.product.name,
            price: widget.product.price,
            pharmacyName: _pharmacyName,
            includePrice: _includePrice,
            width: 250,
            height: 150,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool hasValidBarcode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: (hasValidBarcode &&
                    (_validationResult == null || _validationResult!.isValid))
                ? _printBarcode
                : null,
            icon: const Icon(Icons.print, size: 18),
            label: const Text(
              'طباعة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printBarcode() async {
    // حفظ navigator قبل العملية async
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    navigator.pop();

    try {
      await PrinterService.printProductBarcode(
        barcode: _sanitizedBarcode,
        barcodeType: _selectedBarcodeType,
        productName: widget.product.name,
        price: widget.product.price,
        labelSize: _selectedLabelSize,
        includePrice: _includePrice,
        copies: _copies,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال $_copies نسخة للطباعة',
              style: const TextStyle(
                fontFamily: 'Tajawal',
              ),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'فشل في الطباعة: $e',
              style: const TextStyle(
                fontFamily: 'Tajawal',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ✅ الـ Painter للخطوط المنحنية
class DecorativeCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15) // شفافية خفيفة
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // خط رفيع

    // ✅ رسم 3 خطوط منحنية
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final yOffset = size.height * 0.3 * i; // توزيع عمودي

      path.moveTo(0, size.height * 0.2 + yOffset);

      // منحنى بيزيه (Bezier Curve)
      path.quadraticBezierTo(
        size.width * 0.25, // نقطة التحكم X
        size.height * 0.1 + yOffset, // نقطة التحكم Y
        size.width * 0.5, // النقطة النهائية X
        size.height * 0.25 + yOffset, // النقطة النهائية Y
      );

      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.4 + yOffset,
        size.width,
        size.height * 0.3 + yOffset,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
