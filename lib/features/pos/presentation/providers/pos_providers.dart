import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/inventory/data/datasources/local/product_dao.dart';
import '../../../../core/models/shared/product.dart';
import '../../../../core/models/shared/medicine_unit.dart';
import '../../domain/entities/sale.dart';
import '../../../../core/network/sync_aware_dao.dart';
import '../../../../core/network/sync_aware_sales_service.dart';
import '../../../../features/purchases/presentation/providers/daily_purchase_provider.dart';
import '../../../../features/notifications/presentation/providers/notification_providers.dart';

// ============================================================================
// 📦 POS PROVIDERS - مزودات نقطة البيع
// ============================================================================
// ✨ يدعم المزامنة التلقائية (Sync-Aware) للعمل في بيئة متعددة الأجهزة
// ✨ يتحقق من المخزون قبل كل عملية
// ✨ يدعم الدفع الجزئي والآجل
// ============================================================================

/// مدة الانتظار لمعالجة النواقص التلقائية بعد البيع
const _kAutoReorderDelay = Duration(milliseconds: 300);

// ────────────────────────────────────────────────────────────────────────────
// 🎯 POS Controller - جلب المنتجات
// ────────────────────────────────────────────────────────────────────────────

/// Controller تفاعلي لإدارة منتجات نقطة البيع
/// - يستخدم Sync-Aware DAO للعمل مع قاعدة بيانات محلية أو عن بعد
/// - يتحدث تلقائياً عند تغيير حالة الاتصال
final posControllerProvider =
    AsyncNotifierProvider.autoDispose<POSController, List<Product>>(
        POSController.new);

class POSController extends AutoDisposeAsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    try {
      // ✨ محاولة استخدام Sync-Aware DAO
      final syncDao = ref.watch(syncAwareProductDaoProvider);
      return await syncDao.findAll(activeOnly: true);
    } catch (e) {
      // ⚠️ Fallback: استخدام DAO المحلي مباشرة
      debugPrint('⚠️ SyncAwareDAO failed, using local: $e');
      final localDao = ProductDAO();
      return await localDao.findAll(activeOnly: true);
    }
  }

  /// تحديث القائمة (يُستدعى بعد البيع)
  void refresh() => ref.invalidateSelf();
}

// ✅ Provider للبحث
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// ✅ Provider للمنتجات المفلترة والبحث
final searchedProductsProvider = Provider.autoDispose<List<Product>>((ref) {
  final productsAsync = ref.watch(posControllerProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return productsAsync.when(
    data: (products) {
      var filtered = products;

      // فلترة حسب البحث
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((product) {
          final name = product.name.toLowerCase();
          final scientific = product.scientificName?.toLowerCase() ?? '';
          final barcode = product.barcode;
          final query = searchQuery.toLowerCase();

          return name.contains(query) ||
              scientific.contains(query) ||
              barcode.contains(query);
        }).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ────────────────────────────────────────────────────────────────────────────
// 🛒 Cart Provider - إدارة السلة
// ────────────────────────────────────────────────────────────────────────────

/// مزود السلة مع Stock Validation ودعم الوحدات المتعددة
final cartProvider = ChangeNotifierProvider((ref) => CartProvider(ref));

class CartProvider extends ChangeNotifier {
  final Ref ref;

  CartProvider(this.ref);

  final List<SaleItem> _items = [];

  List<SaleItem> get items => _items;
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal;
  int get itemCount => _items.length;

  // ✨ Helper: جلب المنتج مع Fallback
  Future<Product?> _getProduct(String productId) async {
    try {
      final syncDao = ref.read(syncAwareProductDaoProvider);
      return await syncDao.findById(productId);
    } catch (e) {
      // Fallback to local DAO
      final localDao = ProductDAO();
      return await localDao.findById(productId);
    }
  }

  // ✅ إضافة منتج مع Stock Validation
  Future<void> addItemWithUnit(
      Product product, MedicineUnit selectedUnit) async {
    final unitInfo = product.unitInfo[selectedUnit];
    if (unitInfo == null) {
      throw Exception('معلومات الوحدة غير موجودة');
    }

    // ✨ جلب آخر حالة للمنتج (with fallback)
    final latestProduct = await _getProduct(product.id);

    if (latestProduct == null) {
      throw Exception('المنتج غير موجود');
    }

    // ✅ حساب الكمية المطلوبة بالوحدة الأساسية
    final requiredStock = unitInfo.conversionToBase;

    // ✅ Check if already in cart
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id && item.unit == selectedUnit,
    );

    if (existingIndex != -1) {
      // Update existing item
      final currentQuantity = _items[existingIndex].quantity;
      final totalNeeded = (currentQuantity + 1) * requiredStock;

      if (latestProduct.currentStock < totalNeeded) {
        throw Exception(
          'المخزون غير كافي! المتوفر: ${(latestProduct.currentStock / requiredStock).floor()} ${selectedUnit.arabicName}',
        );
      }

      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: currentQuantity + 1,
        total: (currentQuantity + 1) * unitInfo.sellingPrice,
      );
    } else {
      // Add new item
      if (latestProduct.currentStock < requiredStock) {
        throw Exception(
          'المخزون غير كافي! المتوفر: ${(latestProduct.currentStock / requiredStock).floor()} ${selectedUnit.arabicName}',
        );
      }

      final cartItem = SaleItem(
        id: '${product.id}_${selectedUnit.name}_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        unit: selectedUnit,
        unitPrice: unitInfo.sellingPrice,
        quantity: 1.0,
        total: unitInfo.sellingPrice,
      );

      _items.add(cartItem);
    }

    notifyListeners();
  }

  // ✅ تحديث الكمية مع Validation
  Future<void> updateQuantity(int index, double newQuantity) async {
    if (index < 0 || index >= _items.length) return;

    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final item = _items[index];

    // ✨ جلب المنتج الحالي (with fallback)
    final product = await _getProduct(item.productId);

    if (product == null) {
      throw Exception('المنتج غير موجود');
    }

    // ✅ الحصول على معلومات الوحدة
    final unitInfo = product.unitInfo[item.unit];
    if (unitInfo == null) {
      throw Exception('معلومات الوحدة غير موجودة');
    }

    final totalNeeded = newQuantity * unitInfo.conversionToBase;

    if (product.currentStock < totalNeeded) {
      throw Exception(
        'الكمية المطلوبة (${newQuantity.toInt()}) تتجاوز المخزون المتوفر (${(product.currentStock / unitInfo.conversionToBase).floor()})',
      );
    }

    _items[index] = item.copyWith(
      quantity: newQuantity,
      total: newQuantity * item.unitPrice,
    );

    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // ✅ معالجة البيع (مع دعم المزامنة) مع دعم الدفع الجزئي
  Future<Sale> completeSale({
    required String cashierId,
    required String cashierName,
    required PaymentMethod paymentMethod,
    String? customerName,
    String? customerPhone,
    double discount = 0.0,
    double? paidAmount, // 💰 المبلغ المدفوع (اختياري)
  }) async {
    if (_items.isEmpty) {
      throw Exception('السلة فارغة');
    }

    // 🆕 توليد رقم فاتورة احترافي (عبر Sync-Aware DAO)
    final syncSaleDao = ref.read(syncAwareSaleDaoProvider);
    final saleId = await syncSaleDao.generateSaleId();

    final totalAmount = subtotal - discount;
    final actualPaidAmount = paidAmount ?? totalAmount;
    final remainingAmount = totalAmount - actualPaidAmount;

    // تحديد حالة الدفع
    PaymentStatus paymentStatus;
    if (remainingAmount <= 0) {
      paymentStatus = PaymentStatus.paid;
    } else if (actualPaidAmount > 0) {
      paymentStatus = PaymentStatus.partiallyPaid;
    } else {
      paymentStatus = PaymentStatus.unpaid;
    }

    final sale = Sale(
      id: saleId, // مثال: FK-7PS
      date: DateTime.now(),
      items: List.from(_items),
      subtotal: subtotal,
      discount: discount,
      tax: 0.0,
      total: totalAmount,
      paidAmount: actualPaidAmount,
      remainingAmount: remainingAmount > 0 ? remainingAmount : 0,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerPhone: customerPhone,
      cashierId: cashierId,
      cashierName: cashierName,
      status: SaleStatus.completed,
      createdAt: DateTime.now(),
    );

    // ✅ حفظ البيع (يدعم المزامنة التلقائية والـ Offline Queue)
    final syncSalesService = ref.read(syncAwareSalesServiceProvider);
    await syncSalesService.saveSale(sale,
        userId: cashierId, userName: cashierName);

    // ✅ تنظيف السلة
    clearCart();

    // ✅ تحديث قائمة المنتجات باستخدام Controller الجديد
    ref.read(posControllerProvider.notifier).refresh();

    // ✨ انتظار لمعالجة النواقص التلقائية (تعمل بشكل غير متزامن في SyncAwareSalesService)
    await Future.delayed(_kAutoReorderDelay);

    // ✅ تحديث قائمة طلبيات اليوم (للنواقص التلقائية)
    ref.invalidate(todayPurchaseRequestsProvider);
    ref.invalidate(outOfStockCountProvider);
    ref.invalidate(purchaseRequestsStatsProvider);
    // ✅ تحديث واجهة الطلبيات (StateNotifier) لضمان ظهور النواقص فوراً
    ref.invalidate(dailyPurchaseNotifierProvider);

    // 🔔 فحص المخزون المنخفض وإنشاء إشعارات (الأشياء المهمة فقط)
    _checkLowStockNotifications(sale.items);

    return sale;
  }

  /// 🔔 فحص المخزون المنخفض وانتهاء الصلاحية بعد البيع
  Future<void> _checkLowStockNotifications(List<SaleItem> items) async {
    try {
      final createLowStockNotification =
          ref.read(createLowStockNotificationUseCaseProvider);
      final createNearExpiryNotification =
          ref.read(createNearExpiryNotificationUseCaseProvider);

      for (final item in items) {
        final product = await _getProduct(item.productId);
        if (product == null) continue;

        // ⚠️ إشعار إذا المخزون أقل من 20 وحدة
        if (product.currentStock < 20 && product.currentStock > 0) {
          await createLowStockNotification(
            productName: product.name,
            currentStock: product.currentStock.toInt(),
            productId: product.id,
          );
        }

        // 📅 إشعار إذا الصلاحية خلال 90 يوم
        if (product.expiryDate != null) {
          final daysUntilExpiry =
              product.expiryDate!.difference(DateTime.now()).inDays;
          if (daysUntilExpiry > 0 && daysUntilExpiry <= 90) {
            await createNearExpiryNotification(
              productName: product.name,
              expiryDate: product.expiryDate!,
              productId: product.id,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ فشل فحص التنبيهات: $e');
    }
  }
}
