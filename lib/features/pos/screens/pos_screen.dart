import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/sale.dart';
import '../widgets/product_grid.dart';
import '../widgets/payment_dialog.dart';
import '../providers/pos_providers.dart';
import '../../../database/daos/product_dao.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // ✅ Left Side - Products Grid
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.point_of_sale,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نقطة البيع',
                              style: GoogleFonts.tajawal(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'اختر المنتجات وأضفها للسلة',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Refresh Button
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppColors.primary),
                          iconSize: 22,
                          tooltip: 'تحديث البيانات',
                          onPressed: () {
                            ref.invalidate(productsProvider);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Products Grid
                    const Expanded(
                      child: ProductGrid(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // ✅ Right Side - Cart (بالتخطيط الجديد)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🧺 قائمة السلة (تأخذ كامل الارتفاع)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: cart.items.isEmpty
                            ? _buildEmptyCart()
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: cart.items.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 24),
                                itemBuilder: (context, index) {
                                  return _buildCartItemCard(
                                    context,
                                    ref,
                                    cart.items[index],
                                    index,
                                  );
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 💰 المجموع + الأزرار
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // الإجمالي مع عدد المنتجات
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الإجمالي:',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cart.itemCount} منتج',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatPrice(cart.total.toInt()),
                                style: GoogleFonts.tajawal(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),

                          // 🔘 زرّان صغيران (إلغاء + إتمام البيع)
                          Row(
                            children: [
                              // زر الإلغاء
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: cart.items.isEmpty
                                      ? null
                                      : () {
                                          _showClearCartDialog(context, ref);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // زر إتمام البيع
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: cart.items.isEmpty
                                      ? null
                                      : () => _showPaymentDialog(
                                          context, ref, cart),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: Text(
                                    'إتمام البيع',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Empty Cart State
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'السلة فارغة',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة المنتجات',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Cart Item Card مع Error Handling
  Widget _buildCartItemCard(
    BuildContext context,
    WidgetRef ref,
    SaleItem item,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // ❌ حذف
          IconButton(
            onPressed: () {
              ref.read(cartProvider).removeItem(index);
            },
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.error,
            tooltip: 'حذف',
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 6),

          // اسم المنتج + الوحدات
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item.unit.arabicName,
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () =>
                          _showChangeUnitDialog(context, ref, item, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_horiz,
                              size: 11,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'تغيير',
                              style: GoogleFonts.tajawal(
                                fontSize: 10,
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // كمية
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(cartProvider)
                          .updateQuantity(index, item.quantity - 1);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                              style: GoogleFonts.tajawal(),
                            ),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.remove, size: 16),
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.quantity.toInt()}',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(cartProvider)
                          .updateQuantity(index, item.quantity + 1);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                              style: GoogleFonts.tajawal(),
                            ),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // السعر
          Text(
            _formatPrice(item.total.toInt()),
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Clear Cart Dialog
  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إفراغ السلة', style: GoogleFonts.tajawal()),
        content: Text(
          'هل أنت متأكد من إفراغ السلة؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider).clearCart();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('إفراغ', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  // ✅ تغيير وحدة المنتج في السلة
  void _showChangeUnitDialog(
    BuildContext context,
    WidgetRef ref,
    SaleItem item,
    int index,
  ) async {
    // جلب المنتج من قاعدة البيانات
    final productDao = ProductDAO();
    final product = await productDao.findById(item.productId);

    if (product == null || !context.mounted) return;

    final units = product.unitInfo.keys.toList();

    if (units.length == 1) {
      // منتج بوحدة واحدة فقط
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هذا المنتج له وحدة واحدة فقط',
            style: GoogleFonts.tajawal(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.swap_horiz, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تغيير وحدة البيع',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المخزون: ${product.getStockDisplay()}',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر الوحدة الجديدة:',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...units.map((unit) {
              final unitInfo = product.unitInfo[unit]!;
              final availableInUnit =
                  product.currentStock / unitInfo.conversionToBase;
              final isCurrentUnit = unit == item.unit;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: isCurrentUnit ? 3 : 1,
                color: isCurrentUnit
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentUnit
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCurrentUnit
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: isCurrentUnit ? AppColors.primary : AppColors.info,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        unit.arabicName,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          color: isCurrentUnit
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${unitInfo.sellingPrice.toInt()} د.ع',
                        style: GoogleFonts.tajawal(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'متوفر: ${availableInUnit.floor()} ${unit.arabicName}',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          color: availableInUnit >= 1
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (unitInfo.conversionToBase > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          'الواحد = ${unitInfo.conversionToBase.toInt()} ${product.baseUnit.arabicName}',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isCurrentUnit
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'الحالية',
                            style: GoogleFonts.tajawal(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.info),
                  onTap: isCurrentUnit || availableInUnit < 1
                      ? null
                      : () async {
                          try {
                            // حذف العنصر القديم
                            ref.read(cartProvider).removeItem(index);

                            // إضافة بالوحدة الجديدة
                            await ref
                                .read(cartProvider)
                                .addItemWithUnit(product, unit);

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم تغيير الوحدة إلى ${unit.arabicName} ✓',
                                  style: GoogleFonts.tajawal(),
                                ),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context);

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
                        },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Show Payment Dialog
  void _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    CartProvider cart,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        items: cart.items,
        onPaymentComplete: (sale) {
          // ✅ تم معالجة البيع بنجاح - رسالة محسنة مع النظام الجديد FK
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تم حفظ الفاتورة ${sale.id} بنجاح ✓',
                      style: GoogleFonts.tajawal(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ دالة تنسيق الأسعار بفاصلة
  String _formatPrice(int price) {
    final formattedPrice = price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formattedPrice د.ع';
  }
}
