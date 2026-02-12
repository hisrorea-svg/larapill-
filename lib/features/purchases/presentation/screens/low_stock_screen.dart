import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/database/drift/daos/product_drift_dao.dart';
import '../providers/daily_purchase_provider.dart';
import '../widgets/shared_header_widgets.dart';

/// نموذج منتج ناقص
class LowStockProduct {
  final String id;
  final String name;
  final String? company;
  final String? category;
  final String baseUnit;
  final double currentStock;
  final double minStockLevel;
  final double deficit; // الفرق بين الحد الأدنى والمخزون الحالي

  const LowStockProduct({
    required this.id,
    required this.name,
    this.company,
    this.category,
    required this.baseUnit,
    required this.currentStock,
    required this.minStockLevel,
    required this.deficit,
  });

  factory LowStockProduct.fromMap(Map<String, dynamic> map) {
    final currentStock = (map['current_stock'] as num?)?.toDouble() ?? 0;
    final minStockLevel = (map['min_stock_level'] as num?)?.toDouble() ?? 0;
    return LowStockProduct(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      company: map['company'] as String?,
      category: map['category'] as String?,
      baseUnit: map['base_unit'] as String? ?? 'قطعة',
      currentStock: currentStock,
      minStockLevel: minStockLevel,
      deficit: minStockLevel - currentStock,
    );
  }
}

/// Provider للمنتجات الناقصة
final lowStockProductsProvider =
    FutureProvider.autoDispose<List<LowStockProduct>>((ref) async {
  final productDao = ref.watch(productDriftDaoProvider);
  final lowStockProducts = await productDao.findLowStock();

  return lowStockProducts
      .map((p) => LowStockProduct(
            id: p.id,
            name: p.name,
            company: p.company,
            category: p.category,
            baseUnit: p.baseUnit,
            currentStock: p.currentStock,
            minStockLevel: p.minStockLevel,
            deficit: p.minStockLevel - p.currentStock,
          ))
      .toList();
});

/// شاشة النواقص
class LowStockScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final String? searchQuery;

  const LowStockScreen({super.key, this.embedded = false, this.searchQuery});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  final Set<String> _selectedProducts = {};
  bool _selectAll = false;
  String? _internalSearchQuery;
  final TextEditingController _searchController = TextEditingController();

  // ✅ تحويل اسم الوحدة للعربية
  String _getArabicUnitName(String unit) {
    switch (unit.toLowerCase()) {
      case 'piece':
        return 'وحدة';
      case 'box':
        return 'علبة';
      case 'strip':
        return 'شريط';
      case 'bottle':
        return 'زجاجة';
      case 'tube':
        return 'أنبوب';
      case 'vial':
        return 'قارورة';
      case 'ampule':
        return 'أمبول';
      case 'sachet':
        return 'كيس';
      default:
        return unit;
    }
  }

  // Memoization for filtered products
  List<LowStockProduct>? _cachedFilteredProducts;
  String? _cachedSearchQuery;

  String get _searchQuery => widget.embedded
      ? (widget.searchQuery ?? '')
      : (_internalSearchQuery ?? '');

  /// Get filtered products with memoization
  List<LowStockProduct> _getFilteredProducts(List<LowStockProduct> products) {
    final query = _searchQuery;

    // Return cached result if query hasn't changed
    if (_cachedSearchQuery == query && _cachedFilteredProducts != null) {
      return _cachedFilteredProducts!;
    }

    // Update cache
    _cachedSearchQuery = query;
    _cachedFilteredProducts = query.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                (p.company?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();

    return _cachedFilteredProducts!;
  }

  /// Clear cache when products change
  void _clearFilterCache() {
    _cachedFilteredProducts = null;
    _cachedSearchQuery = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('النواقص',
                  style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                  onPressed: () {
                    ref.invalidate(lowStockProductsProvider);
                    _clearFilterCache();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  tooltip: 'تصدير PDF',
                  onPressed: () => _exportToPdf(productsAsync),
                ),
                if (_selectedProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _addSelectedToOrder(productsAsync),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text(
                        'إضافة (${_selectedProducts.length})',
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
      body: Column(
        children: [
          _buildSearchAndActions(productsAsync),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = _getFilteredProducts(products);

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildProductsList(filteredProducts);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions(
      AsyncValue<List<LowStockProduct>> productsAsync) {
    // عند التضمين، لا نعرض شريط البحث هنا لأنه سيكون في الهيدر الرئيسي
    if (widget.embedded) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // شريط البحث
          Expanded(
            flex: 3,
            child: UnifiedSearchBar(
              controller: _searchController,
              hintText: 'البحث...',
              onChanged: (value) {
                setState(() {
                  _internalSearchQuery = value;
                  _clearFilterCache();
                });
              },
              onClear: () {
                setState(() {
                  _internalSearchQuery = '';
                  _clearFilterCache();
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // تحديد الكل
          productsAsync.whenOrNull(
                data: (products) => products.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _selectAll,
                              onChanged: (value) {
                                setState(() {
                                  _selectAll = value ?? false;
                                  if (_selectAll) {
                                    _selectedProducts
                                        .addAll(products.map((p) => p.id));
                                  } else {
                                    _selectedProducts.clear();
                                  }
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('الكل',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 12)),
                        ],
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          const SizedBox(width: 12),

          // إحصائيات مضغوطة
          productsAsync.whenOrNull(
                data: (products) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniStat(
                      '${products.length}',
                      'ناقص',
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      '${_selectedProducts.length}',
                      'محدد',
                      AppColors.primary,
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
          const SizedBox(width: 12),

          // زر إضافة الكل
          productsAsync.whenOrNull(
                data: (products) => products.isNotEmpty
                    ? ElevatedButton.icon(
                        onPressed: () => _addAllToOrder(products),
                        icon: const Icon(Icons.playlist_add, size: 18),
                        label: const Text(
                          'إضافة الكل',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<LowStockProduct> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = _selectedProducts.contains(product.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedProducts.remove(product.id);
                } else {
                  _selectedProducts.add(product.id);
                }
                _selectAll = _selectedProducts.length == products.length;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedProducts.add(product.id);
                        } else {
                          _selectedProducts.remove(product.id);
                        }
                        _selectAll =
                            _selectedProducts.length == products.length;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  // معلومات المنتج
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (product.company != null)
                          Text(
                            product.company ?? '-',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // المخزون الحالي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'المخزون: ',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${product.currentStock.toInt()}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: product.currentStock <= 0
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'الحد الأدنى: ',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${product.minStockLevel.toInt()}',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // النقص
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '-${product.deficit.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          _getArabicUnitName(product.baseUnit),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            color: Colors.red.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر إضافة سريعة
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    color: AppColors.primary,
                    tooltip: 'إضافة للطلبية',
                    onPressed: () => _addSingleToOrder(product),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد نواقص!',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'جميع المنتجات متوفرة بكميات كافية',
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ في تحميل النواقص',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.invalidate(lowStockProductsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  // ============ Actions ============

  Future<void> _addSingleToOrder(LowStockProduct product) async {
    try {
      await ref.read(dailyPurchaseNotifierProvider.notifier).addManualRequest(
            productId: product.id,
            productName: product.name,
            quantity: product.deficit > 0 ? product.deficit : 1,
            unit: product.baseUnit,
          );

      if (!mounted) return;
      AppToast.success(context, 'تمت إضافة "${product.name}" للطلبية');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _addSelectedToOrder(
      AsyncValue<List<LowStockProduct>> productsAsync) async {
    final products = productsAsync.valueOrNull;
    if (products == null) return;

    final selectedProducts =
        products.where((p) => _selectedProducts.contains(p.id)).toList();

    int addedCount = 0;
    int skippedCount = 0;

    for (final product in selectedProducts) {
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

    setState(() {
      _selectedProducts.clear();
      _selectAll = false;
    });

    if (!mounted) return;
    AppToast.success(context,
        'تمت إضافة $addedCount منتج للطلبية${skippedCount > 0 ? ' (تم تخطي $skippedCount موجود مسبقاً)' : ''}');
  }

  Future<void> _addAllToOrder(List<LowStockProduct> products) async {
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

  Future<void> _exportToPdf(
      AsyncValue<List<LowStockProduct>> productsAsync) async {
    final products = productsAsync.valueOrNull;
    if (products == null || products.isEmpty) {
      AppToast.warning(context, 'لا توجد نواقص للتصدير');
      return;
    }

    try {
      final pdf = pw.Document();

      // تحميل الخط العربي
      final arabicFont =
          await fontFromAssetBundle('assets/fonts/Tajawal-Regular.ttf');
      final arabicFontBold =
          await fontFromAssetBundle('assets/fonts/Tajawal-Bold.ttf');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFontBold,
          ),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'تقرير النواقص',
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontSize: 24,
                    ),
                  ),
                  pw.Text(
                    _formatDate(DateTime.now()),
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'إجمالي المنتجات الناقصة: ${products.length}',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildPdfCell('#', arabicFontBold, isHeader: true),
                    _buildPdfCell('اسم المنتج', arabicFontBold, isHeader: true),
                    _buildPdfCell('الشركة', arabicFontBold, isHeader: true),
                    _buildPdfCell('المخزون', arabicFontBold, isHeader: true),
                    _buildPdfCell('الحد الأدنى', arabicFontBold,
                        isHeader: true),
                    _buildPdfCell('النقص', arabicFontBold, isHeader: true),
                  ],
                ),
                // Data rows
                ...products.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index.isEven ? PdfColors.white : PdfColors.grey50,
                    ),
                    children: [
                      _buildPdfCell('${index + 1}', arabicFont),
                      _buildPdfCell(product.name, arabicFont),
                      _buildPdfCell(product.company ?? '-', arabicFont),
                      _buildPdfCell(
                          '${product.currentStock.toInt()}', arabicFont),
                      _buildPdfCell(
                          '${product.minStockLevel.toInt()}', arabicFont),
                      _buildPdfCell(
                        '-${product.deficit.toInt()}',
                        arabicFontBold,
                        textColor: PdfColors.red,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'تقرير_النواقص_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'خطأ في إنشاء PDF: $e');
    }
  }

  pw.Widget _buildPdfCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          color: textColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
