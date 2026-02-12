/// Product Repository - Clean Drift-based Implementation
///
/// This repository replaces the legacy sqflite-based implementation.
/// Uses ProductDriftDao for all database operations.
library product_repository;

import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/product_drift_dao.dart';
import '../../../../core/database/drift/mappers/product_mapper.dart';
import '../../../../core/models/shared/product.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Repository for Product operations using Drift
class ProductRepository {
  final ProductDriftDao _dao;

  ProductRepository(this._dao);

  // ═══════════════════════════════════════════════════════════════════════════
  // 📖 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🚀 OPTIMIZED: Get all products with units (Single Query)
  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    try {
      final productsWithUnits =
          await _dao.findAllWithUnitsOptimized(activeOnly: activeOnly);
      developer.log(
          '📦 تم جلب ${productsWithUnits.length} منتج/منتجات (استعلام واحد محسّن)',
          name: 'ProductRepository');

      // Mapping سريع بدون async/await
      return productsWithUnits
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    } catch (e, stackTrace) {
      developer.log('❌ خطأ في getAllProducts: $e',
          name: 'ProductRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 🚀 OPTIMIZED: Watch all products (Single Query Stream)
  Stream<List<Product>> watchAllProducts({bool activeOnly = true}) {
    // ⚠️ مهم: map بدلاً من asyncMap للحفاظ على الأداء
    return _dao.watchAllWithUnits(activeOnly: activeOnly).map((pwuList) {
      return pwuList
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    });
  }

  /// 🚀 OPTIMIZED: Search products (Single Query)
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllProducts();
      }
      final results = await _dao.searchWithUnits(query);
      return results
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    } catch (e) {
      developer.log('❌ خطأ في searchProducts: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  /// 🚀 OPTIMIZED: Watch search results (Single Query Stream)
  Stream<List<Product>> watchSearchProducts(String query) {
    if (query.trim().isEmpty) {
      return watchAllProducts();
    }
    // ⚠️ مهم: map بدلاً من asyncMap للحفاظ على الأداء
    return _dao.watchSearchWithUnits(query).map((pwuList) {
      return pwuList
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    });
  }

  /// Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final entry = await _dao.findById(id);
      if (entry == null) return null;
      return _mapEntryWithUnits(entry);
    } catch (e) {
      developer.log('❌ خطأ في getProductById: $e', name: 'ProductRepository');
      return null;
    }
  }

  /// Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final entry = await _dao.findByBarcode(barcode);
      if (entry == null) return null;
      return _mapEntryWithUnits(entry);
    } catch (e) {
      developer.log('❌ خطأ في getProductByBarcode: $e',
          name: 'ProductRepository');
      return null;
    }
  }

  /// Check if barcode exists
  Future<bool> checkBarcodeExists(String barcode,
      {String? excludeProductId}) async {
    try {
      return await _dao.isBarcodeExists(barcode,
          excludeProductId: excludeProductId);
    } catch (e) {
      developer.log('❌ خطأ في checkBarcodeExists: $e',
          name: 'ProductRepository');
      return false;
    }
  }

  /// 🚀 OPTIMIZED: Get low stock products with prices (Single JOIN Query)
  Future<List<Product>> getLowStockProducts() async {
    try {
      final productsWithUnits = await _dao.findLowStockWithUnits();
      return productsWithUnits
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    } catch (e) {
      developer.log('❌ خطأ في getLowStockProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  /// 🚀 OPTIMIZED: Watch low stock products with prices (Single JOIN Query)
  Stream<List<Product>> watchLowStockProducts() {
    return _dao.watchLowStockWithUnits().map((pwuList) {
      return pwuList
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    });
  }

  /// 🚀 OPTIMIZED: Get products expiring soon with prices (Single JOIN Query)
  Future<List<Product>> getExpiringProducts({int daysThreshold = 30}) async {
    try {
      final productsWithUnits =
          await _dao.findExpiringSoonWithUnits(daysThreshold: daysThreshold);
      return productsWithUnits
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    } catch (e) {
      developer.log('❌ خطأ في getExpiringProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  /// 🚀 OPTIMIZED: Watch expiring products with prices (Single JOIN Query)
  Stream<List<Product>> watchExpiringProducts({int daysThreshold = 30}) {
    return _dao
        .watchExpiringSoonWithUnits(daysThreshold: daysThreshold)
        .map((pwuList) {
      return pwuList
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    });
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final stats = await _dao.getStatistics();
      return {
        'total': stats.totalProducts,
        'lowStock': stats.lowStockProducts,
        'expired': stats.expiredProducts,
      };
    } catch (e) {
      developer.log('❌ خطأ في getProductStatistics: $e',
          name: 'ProductRepository');
      return {'total': 0, 'lowStock': 0, 'expired': 0};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✏️ WRITE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate product prices - ensures no negative or zero prices
  void _validateProductPrices(Product product) {
    for (final entry in product.unitInfo.entries) {
      final unit = entry.key;
      final info = entry.value;

      if (info.sellingPrice <= 0) {
        throw ValidationException(
          'سعر البيع يجب أن يكون أكبر من صفر',
          fieldName: 'sellingPrice',
          userMessage:
              'سعر البيع لـ "${unit.arabicName}" يجب أن يكون أكبر من صفر',
        );
      }
      if (info.costPrice < 0) {
        throw ValidationException(
          'سعر التكلفة لا يمكن أن يكون سالباً',
          fieldName: 'costPrice',
          userMessage:
              'سعر التكلفة لـ "${unit.arabicName}" لا يمكن أن يكون سالباً',
        );
      }
    }
  }

  /// Insert a new product with its units
  Future<String> insertProduct(Product product) async {
    try {
      developer.log('📦 بدء إدراج منتج: ${product.name}',
          name: 'ProductRepository');

      // 🔥 Validate prices before insert
      _validateProductPrices(product);

      // Insert product
      final companion = ProductMapper.toCompanion(product);
      await _dao.insertProduct(companion);

      // Insert units
      final unitCompanions =
          ProductMapper.toUnitCompanions(product.id, product.unitInfo);
      for (final unit in unitCompanions) {
        await _dao.insertProductUnit(unit);
      }

      developer.log('✅ تم إدراج المنتج بنجاح: ${product.id}',
          name: 'ProductRepository');

      return product.id;
    } catch (e) {
      developer.log('❌ خطأ في insertProduct: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  /// Update an existing product
  Future<bool> updateProduct(Product product) async {
    try {
      developer.log('🔄 بدء تحديث منتج: ${product.name}',
          name: 'ProductRepository');

      // 🔥 Validate prices before update
      _validateProductPrices(product);

      // Update product
      final companion = ProductMapper.toCompanion(product);
      await _dao.updateProductFields(product.id, companion);

      // Update units (delete old, insert new)
      await _dao.deleteProductUnits(product.id);
      final unitCompanions =
          ProductMapper.toUnitCompanions(product.id, product.unitInfo);
      for (final unit in unitCompanions) {
        await _dao.insertProductUnit(unit);
      }

      developer.log('✅ تم تحديث المنتج', name: 'ProductRepository');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في updateProduct: $e', name: 'ProductRepository');
      return false;
    }
  }

  /// Soft delete a product
  Future<bool> deleteProduct(String id) async {
    try {
      await _dao.softDelete(id);
      developer.log('✅ تم حذف المنتج: $id', name: 'ProductRepository');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في deleteProduct: $e', name: 'ProductRepository');
      return false;
    }
  }

  /// 🛠️ DATA FIX: Recover inactive products that have stock
  Future<int> restoreStockedProducts() async {
    try {
      final count = await _dao.restoreStockedProducts();
      if (count > 0) {
        developer.log('✅ تم استعادة $count منتج كان محذوفاً ولديه مخزون',
            name: 'ProductRepository');
      }
      return count;
    } catch (e) {
      developer.log('❌ خطأ في restoreStockedProducts: $e',
          name: 'ProductRepository');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🗑️ INACTIVE PRODUCTS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🚀 OPTIMIZED: Get all inactive products with units (Single Query)
  Future<List<Product>> getInactiveProducts() async {
    try {
      final productsWithUnits = await _dao.findInactiveWithUnits();
      developer.log('📦 تم جلب ${productsWithUnits.length} منتج غير نشط',
          name: 'ProductRepository');
      return productsWithUnits
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    } catch (e, stackTrace) {
      developer.log('❌ خطأ في getInactiveProducts: $e',
          name: 'ProductRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 🚀 OPTIMIZED: Watch inactive products (Single Query Stream)
  Stream<List<Product>> watchInactiveProducts() {
    return _dao.watchInactiveWithUnits().map((pwuList) {
      return pwuList
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    });
  }

  /// 🚀 OPTIMIZED: Search inactive products (Single Query)
  Future<List<Product>> searchInactiveProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getInactiveProducts();
      }
      final results = await _dao.searchInactiveWithUnits(query);
      return results
          .map((pwu) => ProductMapper.fromEntry(pwu.product, pwu.units))
          .toList();
    } catch (e) {
      developer.log('❌ خطأ في searchInactiveProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  /// Count inactive products
  Future<int> countInactiveProducts() async {
    try {
      return await _dao.countInactive();
    } catch (e) {
      developer.log('❌ خطأ في countInactiveProducts: $e',
          name: 'ProductRepository');
      return 0;
    }
  }

  /// Hard delete a product (permanent deletion)
  Future<bool> hardDeleteProduct(String id) async {
    try {
      final affectedRows = await _dao.hardDelete(id);
      if (affectedRows > 0) {
        developer.log('✅ تم الحذف الدائم للمنتج: $id',
            name: 'ProductRepository');
        return true;
      } else {
        developer.log('⚠️ لم يتم العثور على المنتج للحذف: $id',
            name: 'ProductRepository');
        return false;
      }
    } catch (e) {
      developer.log('❌ خطأ في hardDeleteProduct: $e',
          name: 'ProductRepository');
      return false;
    }
  }

  /// Hard delete all inactive products (permanent batch deletion)
  Future<int> hardDeleteAllInactiveProducts() async {
    try {
      final count = await _dao.hardDeleteAllInactive();
      if (count > 0) {
        developer.log('✅ تم الحذف الدائم لـ $count منتج غير نشط',
            name: 'ProductRepository');
      } else {
        developer.log('⚠️ لا توجد منتجات غير نشطة للحذف',
            name: 'ProductRepository');
      }
      return count;
    } catch (e) {
      developer.log('❌ خطأ في hardDeleteAllInactiveProducts: $e',
          name: 'ProductRepository');
      return 0;
    }
  }

  /// Activate (restore) a product
  Future<bool> activateProduct(String id) async {
    try {
      final result = await _dao.activateProduct(id);
      if (result) {
        developer.log('✅ تم تفعيل المنتج: $id', name: 'ProductRepository');
      }
      return result;
    } catch (e) {
      developer.log('❌ خطأ في activateProduct: $e', name: 'ProductRepository');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Map a single entry with its units (OK for single item, N+1 not an issue)
  Future<Product> _mapEntryWithUnits(ProductEntry entry) async {
    final units = await _dao.getProductUnits(entry.id);
    return ProductMapper.fromEntry(entry, units);
  }

  // ⚠️ DEPRECATED: _mapEntriesWithUnits حُذفت لأنها كانت تسبب N+1 Problem
  // الآن نستخدم الـ JOIN-based methods في DAO مباشرة
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔌 RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dao = ref.watch(productDriftDaoProvider);
  return ProductRepository(dao);
});

/// Stream provider for all products
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchAllProducts();
});

/// Stream provider for low stock products
final lowStockProductsProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchLowStockProducts();
});

/// Stream provider for expiring products
final expiringProductsProvider =
    StreamProvider.family<List<Product>, int>((ref, days) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchExpiringProducts(daysThreshold: days);
});

/// Future provider for product statistics
final productStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductStatistics();
});

/// Stream provider for inactive products
final inactiveProductsProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchInactiveProducts();
});

/// Future provider for inactive products count
final inactiveProductsCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.countInactiveProducts();
});
