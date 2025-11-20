import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/medicine_unit.dart';

class InventoryFilters extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(ProductCategory?) onCategoryChanged;
  final Function(String?)? onAdvancedFilterChanged;

  const InventoryFilters({
    super.key,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    this.onAdvancedFilterChanged,
  });

  @override
  State<InventoryFilters> createState() => _InventoryFiltersState();
}

class _InventoryFiltersState extends State<InventoryFilters> {
  final TextEditingController _searchController = TextEditingController();
  ProductCategory? _selectedCategory;
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Field
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            style: GoogleFonts.tajawal(),
            decoration: InputDecoration(
              hintText: 'البحث عن منتج...',
              hintStyle: GoogleFonts.tajawal(color: AppColors.textPrimary),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textPrimary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardShadow),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardShadow),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.border,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Category Filter
        Expanded(
          child: DropdownButtonFormField<ProductCategory>(
            initialValue: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              widget.onCategoryChanged(value);
            },
            style: GoogleFonts.tajawal(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'جميع الفئات',
              hintStyle: GoogleFonts.tajawal(color: AppColors.textSecondary),
              prefixIcon:
                  const Icon(Icons.category, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.border,
            ),
            items: [
              // خيار "الكل" في البداية
              DropdownMenuItem<ProductCategory>(
                value: null,
                child: Row(
                  children: [
                    const Icon(Icons.select_all,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('جميع الفئات', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              // باقي الفئات
              ...ProductCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 18,
                        color: category.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.arabicName,
                        style: GoogleFonts.tajawal(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Advanced Filter Dropdown
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value;
              });
              widget.onAdvancedFilterChanged?.call(value);
            },
            style: GoogleFonts.tajawal(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'فلترة حسب',
              hintStyle: GoogleFonts.tajawal(color: AppColors.textSecondary),
              prefixIcon: Icon(
                Icons.filter_list,
                color: _selectedFilter != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.border,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('الكل', style: GoogleFonts.tajawal()),
              ),
              DropdownMenuItem<String>(
                value: 'low_stock',
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('كمية منخفضة', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'critical_stock',
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('قريبة من النفاد', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'expired',
                child: Row(
                  children: [
                    const Icon(Icons.event_busy,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('منتهية الصلاحية', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'expiring_soon',
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('قريبة من الانتهاء', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'high_price',
                child: Row(
                  children: [
                    const Icon(Icons.trending_up,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text('الأعلى سعراً', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'low_price',
                child: Row(
                  children: [
                    const Icon(Icons.trending_down,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text('الأقل سعراً', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'best_selling',
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('الأكثر مبيعاً', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'recently_added',
                child: Row(
                  children: [
                    const Icon(Icons.fiber_new,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('المضافة حديثاً', style: GoogleFonts.tajawal()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Clear Button
        ElevatedButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear, size: 18),
          label: Text('مسح الكل', style: GoogleFonts.tajawal(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 253, 133, 133),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedFilter = null;
    });
    widget.onSearchChanged('');
    widget.onCategoryChanged(null);
    widget.onAdvancedFilterChanged?.call(null);
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.tablets:
        return Icons.medication;
      case ProductCategory.syrups:
        return Icons.local_drink;
      case ProductCategory.injections:
        return Icons.vaccines;
      case ProductCategory.creams:
        return Icons.colorize;
      case ProductCategory.suppositories:
        return Icons.rectangle;
      case ProductCategory.drops:
        return Icons.water_drop;
      case ProductCategory.sprays:
        return Icons.air;
      case ProductCategory.medicalSupplies:
        return Icons.medical_services;
      case ProductCategory.bandages:
        return Icons.healing;
      case ProductCategory.syringes:
        return Icons.science;
      case ProductCategory.gloves:
        return Icons.back_hand;
      case ProductCategory.masks:
        return Icons.masks;
      case ProductCategory.antiseptics:
        return Icons.clean_hands;
      case ProductCategory.cosmetics:
        return Icons.face;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
