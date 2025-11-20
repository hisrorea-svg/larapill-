import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/repositories/product_repository.dart';
import '../../../database/daos/product_dao.dart';
import '../../../database/daos/sale_dao.dart';
import '../../../models/product.dart';
import '../../../models/medicine_unit.dart';
import '../models/sale.dart';
import '../../../services/sales_service.dart';

// ✅ Provider لجلب جميع المنتجات من قاعدة البيانات
// ✅ Provider لجلب جميع المنتجات من قاعدة البيانات (AutoDispose لضمان التحديث)
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ProductRepository();
  return await repository.getAllProducts(activeOnly: true);
});

// ✅ Provider للبحث
final searchQueryProvider = StateProvider<String>((ref) => '');

// ✅ Provider للفئة المختارة (ProductCategory enum)
final selectedCategoryProvider = StateProvider<ProductCategory?>((ref) => null);

// ✅ Provider للمنتجات المفلترة والبحث
final searchedProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return productsAsync.when(
    data: (products) {
      var filtered = products;

      // فلترة حسب الفئة (ProductCategory enum)
      if (selectedCategory != null) {
        filtered =
            filtered.where((p) => p.category == selectedCategory).toList();
      }

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

// ✅ CartProvider المحسّن مع Stock Validation
final cartProvider = ChangeNotifierProvider((ref) => CartProvider(ref));

class CartProvider extends ChangeNotifier {
  final Ref ref;

  CartProvider(this.ref);

  final List<SaleItem> _items = [];

  List<SaleItem> get items => _items;
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal;
  int get itemCount => _items.length;

  // ✅ إضافة منتج مع Stock Validation
  Future<void> addItemWithUnit(
      Product product, MedicineUnit selectedUnit) async {
    final unitInfo = product.unitInfo[selectedUnit];
    if (unitInfo == null) {
      throw Exception('معلومات الوحدة غير موجودة');
    }

    // ✅ جلب آخر حالة للمنتج من قاعدة البيانات
    final productDao = ProductDAO();
    final latestProduct = await productDao.findById(product.id);

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

    // ✅ جلب المنتج الحالي
    final productDao = ProductDAO();
    final product = await productDao.findById(item.productId);

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

  // ✅ معالجة البيع (استخدام SalesService) مع دعم الدفع الجزئي
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

    // 🆕 توليد رقم فاتورة احترافي
    final saleDao = SaleDAO();
    final saleId = await saleDao.generateSaleId();

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

    // ✅ حفظ البيع وتحديث المخزون
    await SalesService.instance.saveSale(sale);

    // ✅ تنظيف السلة
    clearCart();

    // ✅ تحديث قائمة المنتجات
    ref.invalidate(productsProvider);

    return sale;
  }
}
