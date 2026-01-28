import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/database_helper.dart';
import '../models/product_model.dart';
import '../models/inventory_stats_model.dart';
import 'inventory_datasource_interface.dart';

/// Local data source implementation using SQLite
///
/// NOTE: This implementation matches the ACTUAL database schema:
/// - products table: id TEXT, current_stock REAL, etc.
/// - product_units table: selling_price, cost_price (joined)
class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  // Stream controller for reactive updates
  final _productsController = StreamController<List<ProductModel>>.broadcast();

  InventoryLocalDataSourceImpl(this._dbHelper);

  Future<Database> get _db async => await _dbHelper.database;

  /// Base query that joins products with product_units
  static const String _baseQuery = '''
    SELECT p.*, 
           pu.selling_price,
           pu.cost_price
    FROM products p
    LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
    WHERE p.is_active = 1
  ''';

  // ============ CRUD ============

  @override
  Future<ProductModel> insertProduct(ProductModel product) async {
    try {
      final db = await _db;
      final newId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        // Insert into products table
        await txn.insert('products', {
          'id': newId,
          'name': product.name,
          'scientific_name': product.scientificName,
          'company': product.company,
          'category': product.category,
          'barcode': product.barcode,
          'base_unit': product.baseUnit,
          'current_stock': product.currentStock,
          'min_stock_level': product.minStockLevel,
          'expiry_date': product.expiryDate,
          'production_date': product.productionDate,
          'created_at': now,
          'updated_at': now,
          'is_active': 1,
        });

        // Insert into product_units table
        await txn.insert('product_units', {
          'id': _uuid.v4(),
          'product_id': newId,
          'unit': product.baseUnit,
          'selling_price': product.sellingPrice ?? 0.0,
          'cost_price': product.costPrice ?? 0.0,
          'conversion_to_base': 1.0,
          'description': 'الوحدة الأساسية',
          'quantity': product.currentStock.toInt(),
        });
      });

      final inserted =
          product.copyWith(id: newId, createdAt: now, updatedAt: now);
      _notifyProductsChanged();
      return inserted;
    } catch (e) {
      throw CacheException('فشل في إضافة المنتج: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final db = await _db;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        // Update products table
        await txn.update(
          'products',
          {
            'name': product.name,
            'scientific_name': product.scientificName,
            'company': product.company,
            'category': product.category,
            'barcode': product.barcode,
            'base_unit': product.baseUnit,
            'current_stock': product.currentStock,
            'min_stock_level': product.minStockLevel,
            'expiry_date': product.expiryDate,
            'production_date': product.productionDate,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [product.id],
        );

        // Update product_units table
        await txn.update(
          'product_units',
          {
            'selling_price': product.sellingPrice ?? 0.0,
            'cost_price': product.costPrice ?? 0.0,
            'quantity': product.currentStock.toInt(),
          },
          where: 'product_id = ? AND unit = ?',
          whereArgs: [product.id, product.baseUnit],
        );
      });

      _notifyProductsChanged();
      return product.copyWith(updatedAt: now);
    } catch (e) {
      throw CacheException('فشل في تحديث المنتج: $e');
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final db = await _db;
      // Soft delete
      await db.update(
        'products',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id.toString()],
      );
      _notifyProductsChanged();
    } catch (e) {
      throw CacheException('فشل في حذف المنتج: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    try {
      final db = await _db;
      final results = await db.rawQuery('''
        $_baseQuery AND p.id = ?
      ''', [id.toString()]);

      if (results.isEmpty) return null;
      return ProductModel.fromSqlite(results.first);
    } catch (e) {
      throw CacheException('فشل في جلب المنتج: $e');
    }
  }

  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final db = await _db;
      final results = await db.rawQuery('''
        $_baseQuery AND p.barcode = ?
      ''', [barcode]);

      if (results.isEmpty) return null;
      return ProductModel.fromSqlite(results.first);
    } catch (e) {
      throw CacheException('فشل في البحث عن الباركود: $e');
    }
  }

  // ============ Queries ============

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final db = await _db;
      final results = await db.rawQuery('''
        $_baseQuery ORDER BY p.name ASC
      ''');
      return results.map((row) => ProductModel.fromSqlite(row)).toList();
    } catch (e) {
      throw CacheException('فشل في جلب المنتجات: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final db = await _db;
      final searchPattern = '%$query%';
      final results = await db.rawQuery('''
        $_baseQuery 
        AND (p.name LIKE ? OR p.company LIKE ? OR p.barcode LIKE ? OR p.category LIKE ?)
        ORDER BY p.name ASC
      ''', [searchPattern, searchPattern, searchPattern, searchPattern]);

      return results.map((row) => ProductModel.fromSqlite(row)).toList();
    } catch (e) {
      throw CacheException('فشل في البحث: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final db = await _db;
      final results = await db.rawQuery('''
        $_baseQuery AND p.category = ?
        ORDER BY p.name ASC
      ''', [category]);

      return results.map((row) => ProductModel.fromSqlite(row)).toList();
    } catch (e) {
      throw CacheException('فشل في جلب منتجات الفئة: $e');
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts(int threshold) async {
    try {
      final db = await _db;
      final results = await db.rawQuery('''
        $_baseQuery 
        AND p.current_stock > 0 AND p.current_stock <= p.min_stock_level
        ORDER BY p.current_stock ASC
      ''');

      return results.map((row) => ProductModel.fromSqlite(row)).toList();
    } catch (e) {
      throw CacheException('فشل في جلب منتجات الكمية المنخفضة: $e');
    }
  }

  @override
  Future<List<ProductModel>> getExpiredProducts() async {
    try {
      final db = await _db;
      final now = DateTime.now().toIso8601String();
      final results = await db.rawQuery('''
        $_baseQuery 
        AND p.expiry_date IS NOT NULL AND p.expiry_date < ?
        ORDER BY p.expiry_date ASC
      ''', [now]);

      return results.map((row) => ProductModel.fromSqlite(row)).toList();
    } catch (e) {
      throw CacheException('فشل في جلب المنتجات المنتهية: $e');
    }
  }

  @override
  Future<List<ProductModel>> getExpiringSoonProducts(int days) async {
    try {
      final db = await _db;
      final now = DateTime.now();
      final future = now.add(Duration(days: days));
      final results = await db.rawQuery('''
        $_baseQuery 
        AND p.expiry_date IS NOT NULL 
        AND p.expiry_date >= ? AND p.expiry_date <= ?
        ORDER BY p.expiry_date ASC
      ''', [now.toIso8601String(), future.toIso8601String()]);

      return results.map((row) => ProductModel.fromSqlite(row)).toList();
    } catch (e) {
      throw CacheException('فشل في جلب المنتجات قريبة الانتهاء: $e');
    }
  }

  @override
  Future<(List<ProductModel>, int)> getProductsFiltered({
    String? searchQuery,
    String? categoryEnumName,
    String? stockFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _db;
      final now = DateTime.now();
      final threeMonthsLater = now.add(const Duration(days: 90));

      // Build dynamic WHERE clauses
      final List<String> conditions = ['p.is_active = 1'];
      final List<dynamic> args = [];

      // Search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions
            .add('(p.name LIKE ? OR p.company LIKE ? OR p.barcode LIKE ?)');
        final pattern = '%$searchQuery%';
        args.addAll([pattern, pattern, pattern]);
      }

      // Category filter (enum name from database)
      if (categoryEnumName != null && categoryEnumName.isNotEmpty) {
        conditions.add('p.category = ?');
        args.add(categoryEnumName);
      }

      // Stock filters
      if (stockFilter != null && stockFilter.isNotEmpty) {
        switch (stockFilter) {
          case 'low_stock':
            conditions.add('p.current_stock > 0 AND p.current_stock < 20');
            break;
          case 'critical_stock':
            conditions.add('p.current_stock > 0 AND p.current_stock < 10');
            break;
          case 'out_of_stock':
            conditions.add('p.current_stock <= 0');
            break;
          case 'expired':
            conditions.add('p.expiry_date IS NOT NULL AND p.expiry_date < ?');
            args.add(now.toIso8601String());
            break;
          case 'expiring_soon':
            conditions.add(
                'p.expiry_date IS NOT NULL AND p.expiry_date >= ? AND p.expiry_date <= ?');
            args.add(now.toIso8601String());
            args.add(threeMonthsLater.toIso8601String());
            break;
        }
      }

      final whereClause = conditions.join(' AND ');

      // Get total count first (for pagination)
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as total FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
        WHERE $whereClause
      ''', args);
      final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      // Get paginated results
      final results = await db.rawQuery('''
        SELECT p.*, pu.selling_price, pu.cost_price
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
        WHERE $whereClause
        ORDER BY p.name ASC
        LIMIT ? OFFSET ?
      ''', [...args, limit, offset]);

      final products =
          results.map((row) => ProductModel.fromSqlite(row)).toList();
      return (products, totalCount);
    } catch (e) {
      throw CacheException('فشل في الفلترة: $e');
    }
  }

  // ============ Statistics ============

  @override
  Future<InventoryStatsModel> calculateStats() async {
    try {
      final db = await _db;
      final now = DateTime.now();
      final threeMonthsLater = now.add(const Duration(days: 90));

      // Total products
      final totalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM products WHERE is_active = 1');
      final totalProducts = Sqflite.firstIntValue(totalResult) ?? 0;

      // Low stock
      final lowStockResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND current_stock > 0 AND current_stock <= min_stock_level',
      );
      final lowStockCount = Sqflite.firstIntValue(lowStockResult) ?? 0;

      // Critical stock (< 10)
      final criticalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND current_stock > 0 AND current_stock < 10',
      );
      final criticalStockCount = Sqflite.firstIntValue(criticalResult) ?? 0;

      // Out of stock
      final outOfStockResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND current_stock <= 0',
      );
      final outOfStockCount = Sqflite.firstIntValue(outOfStockResult) ?? 0;

      // Expired
      final expiredResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND expiry_date IS NOT NULL AND expiry_date < ?',
        [now.toIso8601String()],
      );
      final expiredCount = Sqflite.firstIntValue(expiredResult) ?? 0;

      // Expiring soon
      final expiringSoonResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND expiry_date IS NOT NULL AND expiry_date >= ? AND expiry_date <= ?',
        [now.toIso8601String(), threeMonthsLater.toIso8601String()],
      );
      final expiringSoonCount = Sqflite.firstIntValue(expiringSoonResult) ?? 0;

      // Inventory value (current_stock * selling_price)
      final valueResult = await db.rawQuery('''
        SELECT SUM(p.current_stock * COALESCE(pu.selling_price, 0)) as total 
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
        WHERE p.is_active = 1
      ''');
      final inventoryValue =
          (valueResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Total cost (current_stock * cost_price)
      final costResult = await db.rawQuery('''
        SELECT SUM(p.current_stock * COALESCE(pu.cost_price, 0)) as total 
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
        WHERE p.is_active = 1
      ''');
      final totalCost = (costResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Pending sync count
      final pendingSyncCount = await getPendingSyncCount();

      return InventoryStatsModel(
        totalProducts: totalProducts,
        lowStockCount: lowStockCount,
        criticalStockCount: criticalStockCount,
        outOfStockCount: outOfStockCount,
        expiredCount: expiredCount,
        expiringSoonCount: expiringSoonCount,
        inventoryValue: inventoryValue,
        totalCost: totalCost,
        expectedProfit: inventoryValue - totalCost,
        pendingSyncCount: pendingSyncCount,
      );
    } catch (e) {
      throw CacheException('فشل في حساب الإحصائيات: $e');
    }
  }

  // ============ Sync Queue ============

  @override
  Future<void> markAsSynced(int productId) async {
    // Not used for local-only operations
  }

  @override
  Future<void> addToSyncQueue(int productId, SyncAction action) async {
    try {
      final db = await _db;
      await db.insert('sync_queue', {
        'product_id': productId.toString(),
        'action': action.name,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Table might not exist yet - that's okay for offline-first
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    try {
      final db = await _db;
      return await db.query('sync_queue', orderBy: 'created_at ASC');
    } catch (e) {
      return []; // Table might not exist
    }
  }

  @override
  Future<void> removeSyncOperation(int operationId) async {
    try {
      final db = await _db;
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [operationId]);
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Future<int> getPendingSyncCount() async {
    try {
      final db = await _db;
      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0; // Table might not exist
    }
  }

  // ============ Streams ============

  @override
  Stream<List<ProductModel>> watchProducts() {
    // Initial load
    getAllProducts().then((products) {
      if (!_productsController.isClosed) {
        _productsController.add(products);
      }
    });
    return _productsController.stream;
  }

  @override
  Stream<ProductModel?> watchProduct(int id) {
    return watchProducts().map((products) {
      try {
        return products.firstWhere((p) => p.id == id.toString());
      } catch (_) {
        return null;
      }
    });
  }

  void _notifyProductsChanged() {
    getAllProducts().then((products) {
      if (!_productsController.isClosed) {
        _productsController.add(products);
      }
    });
  }

  void dispose() {
    _productsController.close();
  }
}
