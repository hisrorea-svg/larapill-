import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/top_product.dart';

/// قائمة أفضل المنتجات مبيعاً
class TopProductsList extends StatelessWidget {
  final List<TopProduct> products;
  final bool showViewAll;
  final VoidCallback? onViewAll;

  const TopProductsList({
    super.key,
    required this.products,
    this.showViewAll = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        ...products.take(5).map((product) => _buildProductTile(product)),
        if (showViewAll && onViewAll != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'عرض جميع المنتجات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد مبيعات في هذه الفترة',
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

  Widget _buildProductTile(TopProduct product) {
    final formatter = NumberFormat('#,###', 'en_US');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: product.rank <= 3
            ? _getRankColor(product.rank).withValues(alpha: 0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: product.rank <= 3
              ? _getRankColor(product.rank).withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // شارة الترتيب
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(product.rank).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: product.rank <= 3
                  ? Text(
                      product.rankBadge,
                      style: const TextStyle(fontSize: 16),
                    )
                  : Text(
                      '${product.rank}',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getRankColor(product.rank),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // اسم المنتج
          Expanded(
            flex: 3,
            child: Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // الكمية المباعة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${product.quantitySold} وحدة',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // إجمالي المبيعات
          SizedBox(
            width: 120,
            child: Text(
              '${formatter.format(product.totalSales.toInt())} د.ع',
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // ذهبي
      case 2:
        return const Color(0xFFC0C0C0); // فضي
      case 3:
        return const Color(0xFFCD7F32); // برونزي
      default:
        return AppColors.textSecondary;
    }
  }
}
