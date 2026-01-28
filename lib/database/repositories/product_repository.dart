import 'dart:async';
import 'dart:developer' as developer;
import '../daos/product_dao.dart';
import '../../models/product.dart';

/// Repository للتعامل مع عمليات المنتجات
/// يستخدم ProductDAO للتفاعل مع قاعدة البيانات
class ProductRepository {
  final ProductDAO _dao = ProductDAO();

  // ==================== جلب جميع المنتجات ====================
  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    try {
      return await _dao.findAll(activeOnly: activeOnly);
    } catch (e) {
      developer.log('❌ خطأ في getAllProducts: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  // ==================== البحث في المنتجات ====================
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllProducts();
      }
      return await _dao.search(query);
    } catch (e) {
      developer.log('❌ خطأ في searchProducts: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  // ==================== إضافة منتج جديد ====================
  Future<String> insertProduct(Product product, {Duration? timeout}) async {
    try {
      developer.log('📦 بدء إدراج منتج: ${product.name}',
          name: 'ProductRepository');

      final productId = await _dao.insert(product);

      developer.log('✅ تم إدراج المنتج بنجاح: $productId',
          name: 'ProductRepository');

      return productId;
    } catch (e) {
      developer.log('❌ خطأ في insertProduct: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  // ==================== تحديث منتج ====================
  Future<bool> updateProduct(Product product, {Duration? timeout}) async {
    try {
      developer.log('🔄 بدء تحديث منتج: ${product.name}',
          name: 'ProductRepository');

      final success = await _dao.update(product);

      developer.log(
          success ? '✅ تم تحديث المنتج' : '❌ لم يتم العثور على المنتج للتحديث',
          name: 'ProductRepository');

      return success;
    } catch (e) {
      developer.log('❌ خطأ في updateProduct: $e', name: 'ProductRepository');
      return false;
    }
  }

  // ==================== حذف منتج (soft delete) ====================
  Future<bool> deleteProduct(String id, {Duration? timeout}) async {
    try {
      await _dao.delete(id);

      developer.log('✅ تم حذف المنتج: $id', name: 'ProductRepository');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في deleteProduct: $e', name: 'ProductRepository');
      return false;
    }
  }

  // ==================== جلب المنتجات منخفضة المخزون ====================
  Future<List<Product>> getLowStockProducts() async {
    try {
      return await _dao.findLowStock();
    } catch (e) {
      developer.log('❌ خطأ في getLowStockProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  // ==================== تحديث المخزون ====================
  Future<bool> updateStock(String productId, double newStock,
      {Duration? timeout}) async {
    try {
      return await _dao.updateStock(productId, newStock);
    } catch (e) {
      developer.log('❌ خطأ في updateStock: $e', name: 'ProductRepository');
      return false;
    }
  }

  // ==================== التحقق من وجود باركود ====================
  Future<bool> checkBarcodeExists(String barcode,
      {String? excludeProductId}) async {
    try {
      return await _dao.isBarcodeExists(
        barcode,
        excludeProductId: excludeProductId,
      );
    } catch (e) {
      developer.log('❌ خطأ في checkBarcodeExists: $e',
          name: 'ProductRepository');
      return false;
    }
  }

  // ==================== جلب منتج بواسطة ID ====================
  Future<Product?> getProductById(String id) async {
    try {
      return await _dao.findById(id);
    } catch (e) {
      developer.log('❌ خطأ في getProductById: $e', name: 'ProductRepository');
      return null;
    }
  }

  // ==================== جلب منتج بواسطة الباركود ====================
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _dao.findByBarcode(barcode);
    } catch (e) {
      developer.log('❌ خطأ في getProductByBarcode: $e',
          name: 'ProductRepository');
      return null;
    }
  }

  // ==================== جلب المنتجات القريبة من انتهاء الصلاحية ====================
  Future<List<Product>> getExpiringProducts({int daysThreshold = 30}) async {
    try {
      return await _dao.findExpiringSoon(daysThreshold: daysThreshold);
    } catch (e) {
      developer.log('❌ خطأ في getExpiringProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  // ==================== إحصائيات المنتجات ====================
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      return await _dao.getStatistics();
    } catch (e) {
      developer.log('❌ خطأ في getProductStatistics: $e',
          name: 'ProductRepository');
      return {
        'total': 0,
        'lowStock': 0,
        'outOfStock': 0,
        'expiringSoon': 0,
      };
    }
  }
}
