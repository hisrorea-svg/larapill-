import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../models/medicine_unit.dart';
import '../providers/pos_providers.dart';

class ProductGrid extends ConsumerStatefulWidget {
  const ProductGrid({super.key});

  @override
  ConsumerState<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<ProductGrid> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // ✅ تركيز تلقائي على مربع البحث
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    // ✅ استماع للتغييرات
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(searchedProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Column(
      children: [
        // ✅ مربع بحث واحد - للباركود والاسم
        _buildUnifiedSearchField(),
        const SizedBox(height: 16),

        // Category Filter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'الفئة:',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<ProductCategory?>(
                  value: selectedCategory,
                  hint: Text('كل الفئات', style: GoogleFonts.tajawal()),
                  underline: const SizedBox(),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<ProductCategory?>(
                      value: null,
                      child: Text('كل الفئات', style: GoogleFonts.tajawal()),
                    ),
                    ...ProductCategory.values.map((category) {
                      return DropdownMenuItem<ProductCategory?>(
                        value: category,
                        child: Text(
                          category.arabicName,
                          style: GoogleFonts.tajawal(),
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    ref.read(selectedCategoryProvider.notifier).state = value;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Products Grid
        Expanded(
          child: products.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
        ),
      ],
    );
  }

  // ✅ مربع بحث واحد موحّد
  Widget _buildUnifiedSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو امسح الباركود...',
                hintStyle: GoogleFonts.tajawal(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _handleSearchSubmit(query.trim());
                }
              },
            ),
          ),

          // ✅ زر Clear
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                _searchFocusNode.requestFocus();
              },
              icon: const Icon(Icons.clear, color: AppColors.error),
              tooltip: 'مسح',
            ),
        ],
      ),
    );
  }

  // ✅ معالجة البحث عند الضغط على Enter
  void _handleSearchSubmit(String query) {
    final productsAsync = ref.read(productsProvider);

    productsAsync.when(
      data: (allProducts) {
        // ✅ البحث بالباركود أولاً (دقيق)
        final exactBarcodeMatch = allProducts
            .where(
              (p) => p.barcode == query,
            )
            .toList();

        if (exactBarcodeMatch.isNotEmpty) {
          // ✅ وُجد منتج بالباركود → إضافة فورية للسلة بالوحدة الأساسية
          final product = exactBarcodeMatch.first;

          // ✅ استخدام الوحدة الأساسية مباشرة
          final baseUnit = product.baseUnit;

          _addToCartDirectly(product, baseUnit);
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).state = '';
          Future.delayed(const Duration(milliseconds: 200), () {
            _searchFocusNode.requestFocus();
          });
        } else {
          // ✅ لم يُعثر بالباركود - البحث يستمر بالاسم تلقائياً
          // (المنتجات تظهر في الـ Grid حسب searchedProductsProvider)
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'البحث عن: $query',
                style: GoogleFonts.tajawal(),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب تغيير البحث أو الفئة',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final hasStock = product.currentStock > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: hasStock
            ? () {
                // ✅ إضافة مباشرة للسلة بالوحدة الأساسية
                _addToCartDirectly(product, product.baseUnit);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الاسم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),

                  // المخزون
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasStock
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasStock ? product.getStockDisplay() : 'نفذ',
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: hasStock ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // السعر
                  if (product.unitInfo.isNotEmpty)
                    Text(
                      _formatPrice(
                          product.unitInfo.values.first.sellingPrice.toInt()),
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            if (!hasStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ إضافة مباشرة للسلة (وحدة واحدة فقط)
  Future<void> _addToCartDirectly(Product product, MedicineUnit unit) async {
    try {
      await ref.read(cartProvider).addItemWithUnit(product, unit);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة ${product.name} للسلة ✓',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );

      Future.delayed(const Duration(milliseconds: 200), () {
        _searchFocusNode.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatPrice(int price) {
    final formattedPrice = price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formattedPrice د.ع';
  }
}
