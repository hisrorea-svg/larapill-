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

/// Repository for Product operations using Drift
class ProductRepository {
  final ProductDriftDao _dao;

  ProductRepository(this._dao);

  // ═══════════════════════════════════════════════════════════════════════════
  // 📖 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all products
  Future<List<Product>> getAllProducts({bool activeOnly = true}) async {
    try {
      final entries = await _dao.findAll(activeOnly: activeOnly);
      return _mapEntriesWithUnits(entries);
    } catch (e) {
      developer.log('❌ خطأ في getAllProducts: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  /// Watch all products (reactive stream)
  Stream<List<Product>> watchAllProducts({bool activeOnly = true}) {
    return _dao.watchAll(activeOnly: activeOnly).asyncMap((entries) async {
      return _mapEntriesWithUnits(entries);
    });
  }

  /// Search products by query
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllProducts();
      }
      final entries = await _dao.search(query);
      return _mapEntriesWithUnits(entries);
    } catch (e) {
      developer.log('❌ خطأ في searchProducts: $e', name: 'ProductRepository');
      rethrow;
    }
  }

  /// Watch search results (reactive)
  Stream<List<Product>> watchSearchProducts(String query) {
    if (query.trim().isEmpty) {
      return watchAllProducts();
    }
    return _dao.watchSearch(query).asyncMap((entries) async {
      return _mapEntriesWithUnits(entries);
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

  /// Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final entries = await _dao.findLowStock();
      return _mapEntriesWithUnits(entries);
    } catch (e) {
      developer.log('❌ خطأ في getLowStockProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  /// Watch low stock products (reactive)
  Stream<List<Product>> watchLowStockProducts() {
    return _dao.watchLowStock().asyncMap((entries) async {
      return _mapEntriesWithUnits(entries);
    });
  }

  /// Get products expiring soon
  Future<List<Product>> getExpiringProducts({int daysThreshold = 30}) async {
    try {
      final entries = await _dao.findExpiringSoon(daysThreshold: daysThreshold);
      return _mapEntriesWithUnits(entries);
    } catch (e) {
      developer.log('❌ خطأ في getExpiringProducts: $e',
          name: 'ProductRepository');
      rethrow;
    }
  }

  /// Watch expiring products (reactive)
  Stream<List<Product>> watchExpiringProducts({int daysThreshold = 30}) {
    return _dao
        .watchExpiringSoon(daysThreshold: daysThreshold)
        .asyncMap((entries) async {
      return _mapEntriesWithUnits(entries);
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

  /// Insert a new product with its units
  Future<String> insertProduct(Product product) async {
    try {
      developer.log('📦 بدء إدراج منتج: ${product.name}',
          name: 'ProductRepository');

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

  /// Update stock quantity
  Future<bool> updateStock(String productId, double newStock) async {
    try {
      await _dao.updateStock(productId, newStock);
      return true;
    } catch (e) {
      developer.log('❌ خطأ في updateStock: $e', name: 'ProductRepository');
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Map a single entry with its units
  Future<Product> _mapEntryWithUnits(ProductEntry entry) async {
    final units = await _dao.getProductUnits(entry.id);
    return ProductMapper.fromEntry(entry, units);
  }

  /// Map multiple entries with their units
  Future<List<Product>> _mapEntriesWithUnits(List<ProductEntry> entries) async {
    final products = <Product>[];
    for (final entry in entries) {
      final units = await _dao.getProductUnits(entry.id);
      products.add(ProductMapper.fromEntry(entry, units));
    }
    return products;
  }
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
