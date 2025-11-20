import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../database/repositories/product_repository.dart';
import '../../models/product.dart';

class GlobalSearchDelegate extends SearchDelegate<String> {
  final ProductRepository _productRepository = ProductRepository();

  @override
  String get searchFieldLabel => 'بحث عن دواء أو اسم تجاري...';

  @override
  TextStyle get searchFieldStyle => GoogleFonts.tajawal(
        fontSize: 16,
        color: AppColors.textPrimary,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.tajawal(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Product>>(
      future: _searchItems(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'خطأ في البحث',
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد نتائج للبحث',
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'جرب البحث بكلمات أخرى',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            return _buildSearchResultItem(context, product);
          },
        );
      },
    );
  }

  Widget _buildSearchResultItem(BuildContext context, Product product) {
    // الحصول على معلومات الوحدة الأساسية
    final baseUnitInfo = product.unitInfo[product.baseUnit];
    final sellingPrice = baseUnitInfo?.sellingPrice ?? 0.0;
    final stock = product.currentStock;

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.medication,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        product.name,
        style: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الباركود: ${product.barcode}',
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (product.company.isNotEmpty)
            Text(
              'الشركة: ${product.company}',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          Row(
            children: [
              Text(
                '${sellingPrice.toStringAsFixed(0)} د.ع',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'مخزون: ${stock.toInt()} ${product.baseUnit.arabicName}',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: stock > product.minStockLevel
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _showItemDetails(context, product),
            icon: const Icon(Icons.info_outline),
            tooltip: 'التفاصيل',
          ),
          IconButton(
            onPressed: () => _addToCart(context, product),
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'إضافة للسلة',
          ),
        ],
      ),
      onTap: () {
        _saveRecentSearch(product.name);
        close(context, product.name);
      },
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'اقتراحات البحث',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.trending_up, color: AppColors.primary),
          title: Text('باراسيتامول', style: GoogleFonts.tajawal()),
          onTap: () => query = 'باراسيتامول',
        ),
        ListTile(
          leading: const Icon(Icons.trending_up, color: AppColors.primary),
          title: Text('أموكسيسيلين', style: GoogleFonts.tajawal()),
          onTap: () => query = 'أموكسيسيلين',
        ),
        ListTile(
          leading: const Icon(Icons.trending_up, color: AppColors.primary),
          title: Text('فيتامين د', style: GoogleFonts.tajawal()),
          onTap: () => query = 'فيتامين د',
        ),
        ListTile(
          leading: const Icon(Icons.trending_up, color: AppColors.primary),
          title: Text('شراب السعال', style: GoogleFonts.tajawal()),
          onTap: () => query = 'شراب السعال',
        ),
      ],
    );
  }

  Future<List<Product>> _searchItems(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return await _productRepository.getAllProducts();
      }
      return await _productRepository.searchProducts(searchQuery);
    } catch (e) {
      // في حالة الخطأ، نرجع قائمة فارغة
      return [];
    }
  }

  void _showItemDetails(BuildContext context, Product product) {
    final baseUnitInfo = product.unitInfo[product.baseUnit];
    final sellingPrice = baseUnitInfo?.sellingPrice ?? 0.0;
    final costPrice = baseUnitInfo?.costPrice ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name, style: GoogleFonts.tajawal()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('الباركود', product.barcode),
              _buildDetailRow('الشركة', product.company),
              _buildDetailRow('التصنيف', product.category.arabicName),
              const Divider(),
              _buildDetailRow(
                  'سعر البيع', '${sellingPrice.toStringAsFixed(0)} د.ع'),
              _buildDetailRow(
                  'سعر الشراء', '${costPrice.toStringAsFixed(0)} د.ع'),
              const Divider(),
              _buildDetailRow('المخزون الحالي',
                  '${product.currentStock.toInt()} ${product.baseUnit.arabicName}'),
              _buildDetailRow('الحد الأدنى',
                  '${product.minStockLevel.toInt()} ${product.baseUnit.arabicName}'),
              if (product.expiryDate != null)
                _buildDetailRow(
                  'تاريخ انتهاء الصلاحية',
                  '${product.expiryDate!.year}-${product.expiryDate!.month}-${product.expiryDate!.day}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إضافة ${product.name} إلى السلة',
          style: GoogleFonts.tajawal(),
        ),
        backgroundColor: AppColors.success,
      ),
    );
    close(context, product.name);
  }

  void _saveRecentSearch(String searchTerm) {
    // حفظ البحث الأخير
  }
}
