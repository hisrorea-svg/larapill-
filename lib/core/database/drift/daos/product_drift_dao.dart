/// Product Drift DAO - Type-safe database access for products
library product_drift_dao;

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/database_provider.dart';

part 'product_drift_dao.g.dart';

/// DAO for Products table with type-safe queries
@DriftAccessor(tables: [Products, ProductUnits])
class ProductDriftDao extends DatabaseAccessor<AppDatabase>
    with _$ProductDriftDaoMixin {
  ProductDriftDao(super.db);

  // 📖 READ OPERATIONS

  /// Get all products (optionally filter by active status and soft delete)
  Future<List<ProductEntry>> findAll(
      {bool activeOnly = true, bool includeDeleted = false}) {
    final query = select(products);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    if (!includeDeleted) {
      query.where((p) => p.isDeleted.equals(false));
    }
    return query.get();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚀 OPTIMIZED METHODS WITH JOIN - للتخلص من N+1 Problem
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all products with units in SINGLE QUERY using JOIN (Optimized)
  Future<List<ProductWithUnits>> findAllWithUnitsOptimized(
      {bool activeOnly = true, bool includeDeleted = false}) async {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ]);

    if (activeOnly) {
      query.where(products.isActive.equals(true));
    }
    if (!includeDeleted) {
      query.where(products.isDeleted.equals(false));
    }

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// Watch all products with units in SINGLE QUERY using JOIN (Reactive & Optimized)
  Stream<List<ProductWithUnits>> watchAllWithUnits(
      {bool activeOnly = true, bool includeDeleted = false}) {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ]);

    if (activeOnly) {
      query.where(products.isActive.equals(true));
    }
    if (!includeDeleted) {
      query.where(products.isDeleted.equals(false));
    }

    return query.watch().map((rows) => _groupJoinedResults(rows));
  }

  /// Search products with units in SINGLE QUERY (excludes soft deleted)
  Future<List<ProductWithUnits>> searchWithUnits(String queryStr) async {
    if (queryStr.trim().isEmpty) {
      return findAllWithUnitsOptimized();
    }

    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.name.contains(queryStr) |
          products.scientificName.contains(queryStr) |
          products.barcode.equals(queryStr))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false));

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// Watch search with units in SINGLE QUERY (excludes soft deleted)
  Stream<List<ProductWithUnits>> watchSearchWithUnits(String queryStr) {
    if (queryStr.trim().isEmpty) {
      return watchAllWithUnits();
    }

    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.name.contains(queryStr) |
          products.scientificName.contains(queryStr) |
          products.barcode.equals(queryStr))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false));

    return query.watch().map((rows) => _groupJoinedResults(rows));
  }

  /// 🔧 Helper: Group JOIN results into ProductWithUnits
  List<ProductWithUnits> _groupJoinedResults(List<TypedResult> rows) {
    final productMap = <String, ProductWithUnits>{};

    for (final row in rows) {
      final product = row.readTable(products);
      final unit = row.readTableOrNull(productUnits);

      if (!productMap.containsKey(product.id)) {
        productMap[product.id] = ProductWithUnits(
          product: product,
          units: [],
        );
      }

      if (unit != null) {
        productMap[product.id]!.units.add(unit);
      }
    }

    return productMap.values.toList();
  }

  /// Watch all products (reactive, excludes soft deleted by default)
  Stream<List<ProductEntry>> watchAll(
      {bool activeOnly = true, bool includeDeleted = false}) {
    final query = select(products);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    if (!includeDeleted) {
      query.where((p) => p.isDeleted.equals(false));
    }
    return query.watch();
  }

  /// Get product by ID
  Future<ProductEntry?> findById(String id) {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Find product by barcode (active and not soft deleted)
  Future<ProductEntry?> findByBarcode(String barcode) {
    return (select(products)
          ..where((p) => p.barcode.equals(barcode))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Check if barcode exists (optionally excluding a specific product, active and not soft deleted)
  Future<bool> isBarcodeExists(String barcode,
      {String? excludeProductId}) async {
    final query = select(products)
      ..where((p) => p.barcode.equals(barcode))
      ..where((p) => p.isActive.equals(true))
      ..where((p) => p.isDeleted.equals(false));
    if (excludeProductId != null) {
      query.where((p) => p.id.equals(excludeProductId).not());
    }
    final product = await query.getSingleOrNull();
    return product != null;
  }

  /// Search products by name or barcode (active and not soft deleted)
  Future<List<ProductEntry>> search(String query) {
    return (select(products)
          ..where((p) =>
              p.name.contains(query) |
              p.scientificName.contains(query) |
              p.barcode.equals(query))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .get();
  }

  /// Watch search results (active and not soft deleted)
  Stream<List<ProductEntry>> watchSearch(String query) {
    return (select(products)
          ..where((p) =>
              p.name.contains(query) |
              p.scientificName.contains(query) |
              p.barcode.equals(query))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .watch();
  }

  /// Find low stock products (excludes soft deleted)
  Future<List<ProductEntry>> findLowStock() {
    return (select(products)
          ..where((p) => p.currentStock.isSmallerOrEqual(p.minStockLevel))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .get();
  }

  /// Watch low stock products (excludes soft deleted)
  Stream<List<ProductEntry>> watchLowStock() {
    return (select(products)
          ..where((p) => p.currentStock.isSmallerOrEqual(p.minStockLevel))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .watch();
  }

  /// 🚀 OPTIMIZED: Find low stock products with prices (JOIN, excludes soft deleted)
  Future<List<ProductWithUnits>> findLowStockWithUnits() async {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.currentStock.isSmallerOrEqual(products.minStockLevel))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false));

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// 🚀 OPTIMIZED: Watch low stock products with prices (JOIN, excludes soft deleted)
  Stream<List<ProductWithUnits>> watchLowStockWithUnits() {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.currentStock.isSmallerOrEqual(products.minStockLevel))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false));

    return query.watch().map((rows) => _groupJoinedResults(rows));
  }

  /// Find expiring soon (excludes soft deleted)
  Future<List<ProductEntry>> findExpiringSoon({int daysThreshold = 30}) {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    return (select(products)
          ..where((p) => p.expiryDate.isSmallerOrEqualValue(thresholdDate))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .get();
  }

  /// Watch expiring soon (excludes soft deleted)
  Stream<List<ProductEntry>> watchExpiringSoon({int daysThreshold = 30}) {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    return (select(products)
          ..where((p) => p.expiryDate.isSmallerOrEqualValue(thresholdDate))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false)))
        .watch();
  }

  /// 🚀 OPTIMIZED: Find expiring soon products with prices (JOIN, excludes soft deleted)
  Future<List<ProductWithUnits>> findExpiringSoonWithUnits(
      {int daysThreshold = 30}) async {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.expiryDate.isSmallerOrEqualValue(thresholdDate))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false));

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// 🚀 OPTIMIZED: Watch expiring soon products with prices (JOIN, excludes soft deleted)
  Stream<List<ProductWithUnits>> watchExpiringSoonWithUnits(
      {int daysThreshold = 30}) {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.expiryDate.isSmallerOrEqualValue(thresholdDate))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false));

    return query.watch().map((rows) => _groupJoinedResults(rows));
  }

  /// 🚀 OPTIMIZED: Find expired products with prices (JOIN, excludes soft deleted)
  Future<List<ProductWithUnits>> findExpiredWithUnits() async {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.expiryDate.isSmallerThanValue(DateTime.now()))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false))
      ..orderBy([OrderingTerm.asc(products.expiryDate)]);

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// 🚀 OPTIMIZED: Watch expired products with prices (JOIN, excludes soft deleted)
  Stream<List<ProductWithUnits>> watchExpiredWithUnits() {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.expiryDate.isSmallerThanValue(DateTime.now()))
      ..where(products.isActive.equals(true))
      ..where(products.isDeleted.equals(false))
      ..orderBy([OrderingTerm.asc(products.expiryDate)]);

    return query.watch().map((rows) => _groupJoinedResults(rows));
  }

  // 📝 WRITE OPERATIONS

  /// Insert a product
  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  /// Update product fields
  Future<bool> updateProductFields(
      String id, ProductsCompanion companion) async {
    final affectedRows = await (update(products)..where((p) => p.id.equals(id)))
        .write(companion);
    return affectedRows > 0;
  }

  /// Soft delete a product (mark as deleted, not permanent removal)
  /// This preserves the product data while hiding it from normal queries
  Future<int> softDelete(String productId, {String? deletedBy}) async {
    debugPrint('🗑️ DAO: Starting SOFT delete for product ID: $productId');

    // First, check if product exists
    final product = await findById(productId);
    if (product == null) {
      debugPrint('❌ DAO: Product not found with ID: $productId');
      return 0;
    }

    debugPrint('📋 DAO: Found product: ${product.name}');

    // Update product to mark as deleted
    final result =
        await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        updatedBy: Value(deletedBy),
        updatedAt: Value(DateTime.now()),
      ),
    );

    debugPrint('🗑️ DAO: Soft deleted product. Rows affected: $result');
    return result;
  }

  /// Hard delete a product (permanent removal)
  /// ⚠️ WARNING: This permanently deletes the product and cannot be undone
  Future<int> hardDelete(String productId) async {
    debugPrint(
        '🗑️ DAO: Starting PERMANENT (hard) delete for product ID: $productId');

    // First, check if product exists
    final product = await findById(productId);
    if (product == null) {
      debugPrint('❌ DAO: Product not found with ID: $productId');
      return 0;
    }

    debugPrint('📋 DAO: Found product: ${product.name}');

    // Delete units first (child records), then product (parent)
    await customStatement(
        "DELETE FROM product_units WHERE product_id = '$productId'");
    debugPrint('🗑️ DAO: Deleted associated units');

    await customStatement("DELETE FROM products WHERE id = '$productId'");
    debugPrint('🗑️ DAO: Deleted product permanently');

    // Verify deletion
    final remainingCount = await customSelect(
      'SELECT COUNT(*) as cnt FROM products',
    ).getSingle();

    final remaining = remainingCount.read<int>('cnt');
    debugPrint(
        '🔍 DAO: PERMANENT DELETE done. Remaining products in DB: $remaining');

    return 1;
  }

  // 📊 STATISTICS

  /// Get product statistics
  Future<ProductStatistics> getStatistics() async {
    final totalCountQueryResult = await (selectOnly(products)
          ..addColumns([products.id.count()])
          ..where(products.isActive.equals(true)))
        .map((row) => row.read(products.id.count()))
        .getSingle();
    final totalCount = totalCountQueryResult ?? 0;

    final lowStockCount = await countLowStock();

    final expiredCountQueryResult = await (selectOnly(products)
          ..addColumns([products.id.count()])
          ..where(products.expiryDate.isSmallerOrEqualValue(DateTime.now()))
          ..where(products.isActive.equals(true)))
        .map((row) => row.read(products.id.count()))
        .getSingle();
    final expiredCount = expiredCountQueryResult ?? 0;

    return ProductStatistics(
      totalProducts: totalCount,
      lowStockProducts: lowStockCount,
      expiredProducts: expiredCount,
    );
  }

  /// 📊 Count low stock products (exclude soft-deleted)
  Future<int> countLowStock() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE current_stock <= min_stock_level AND is_active = 1 AND is_deleted = 0',
      readsFrom: {products},
    ).map((row) => row.read<int>('count')).getSingle();
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADDITIONAL QUERY METHODS (for Repository direct access)
  // ─────────────────────────────────────────────────────────────────────────

  /// Find products by category (excludes soft deleted)
  Future<List<ProductEntry>> findByCategory(String category) {
    return (select(products)
          ..where((p) => p.category.equals(category))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Find expired products (excludes soft deleted)
  Future<List<ProductEntry>> findExpired() {
    return (select(products)
          ..where((p) => p.expiryDate.isSmallerThanValue(DateTime.now()))
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.expiryDate)]))
        .get();
  }

  /// Watch a single product by ID
  Stream<ProductEntry?> watchById(String id) {
    return (select(products)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  /// 🚀 CORE: Get filtered products with robust JOIN for prices
  Future<(List<ProductWithUnits>, int)> getProductsFiltered({
    String? searchQuery,
    String? category,
    String? stockFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    // 1. Build base query for counting and fetching, applying filters
    final baseQuery = select(products);

    // ✅ FIX: Only show active products (exclude soft-deleted)
    baseQuery.where((p) => p.isActive.equals(true));
    baseQuery.where((p) => p.isDeleted.equals(false));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      baseQuery.where((p) =>
          p.name.contains(searchQuery) |
          p.barcode.equals(searchQuery) |
          p.company.contains(searchQuery));
    }

    if (category != null && category != 'all') {
      baseQuery.where((p) => p.category.equals(category));
    }

    if (stockFilter != null) {
      switch (stockFilter) {
        case 'low_stock':
          baseQuery.where((p) =>
              p.currentStock.isSmallerOrEqual(p.minStockLevel) &
              p.currentStock.isBiggerThanValue(0));
          break;
        case 'critical_stock':
          // Using 10 as critical threshold from Entity
          baseQuery.where((p) =>
              p.currentStock.isSmallerOrEqualValue(10) &
              p.currentStock.isBiggerThanValue(0));
          break;
        case 'out_of_stock':
          baseQuery.where((p) => p.currentStock.isSmallerOrEqualValue(0));
          break;
        case 'expired':
          baseQuery
              .where((p) => p.expiryDate.isSmallerThanValue(DateTime.now()));
          break;
        case 'expiring_soon':
          final now = DateTime.now();
          final threeMonthsLater = now.add(const Duration(days: 90));
          baseQuery.where((p) =>
              p.expiryDate.isBiggerOrEqualValue(now) &
              p.expiryDate.isSmallerOrEqualValue(threeMonthsLater));
          break;
      }
    }

    // 2. Get total count
    final totalCountLength = await baseQuery.get();
    final totalCount = totalCountLength.length;

    // 3. Apply Ordering and Pagination
    baseQuery.orderBy([(p) => OrderingTerm.asc(p.name)]);
    baseQuery.limit(limit, offset: offset);

    // 4. Perform the JOIN
    final joinedQuery = baseQuery.join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ]);

    final results = await joinedQuery.get();

    // 5. Group results
    return (_groupJoinedResults(results), totalCount);
  }

  /// Get full inventory statistics
  Future<FullInventoryStatistics> getFullStatistics() async {
    final now = DateTime.now();
    final threeMonthsLater = now.add(const Duration(days: 90));

    // Total products (exclude soft-deleted)
    final totalResult = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND is_deleted = 0',
      readsFrom: {products},
    ).getSingle();
    final totalProducts = totalResult.read<int>('count');

    // Low stock (exclude soft-deleted)
    final lowStockResult = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND is_deleted = 0 AND current_stock > 0 AND current_stock <= min_stock_level',
      readsFrom: {products},
    ).getSingle();
    final lowStockCount = lowStockResult.read<int>('count');

    // Critical stock (exclude soft-deleted)
    final criticalResult = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND is_deleted = 0 AND current_stock > 0 AND current_stock < 10',
      readsFrom: {products},
    ).getSingle();
    final criticalStockCount = criticalResult.read<int>('count');

    // Out of stock (exclude soft-deleted)
    final outOfStockResult = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND is_deleted = 0 AND current_stock <= 0',
      readsFrom: {products},
    ).getSingle();
    final outOfStockCount = outOfStockResult.read<int>('count');

    // Expired (exclude soft-deleted)
    final expiredResult = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND is_deleted = 0 AND expiry_date IS NOT NULL AND expiry_date < ?',
      variables: [Variable.withString(now.toIso8601String())],
      readsFrom: {products},
    ).getSingle();
    final expiredCount = expiredResult.read<int>('count');

    // Expiring soon (exclude soft-deleted)
    final expiringSoonResult = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND is_deleted = 0 AND expiry_date IS NOT NULL AND expiry_date >= ? AND expiry_date <= ?',
      variables: [
        Variable.withString(now.toIso8601String()),
        Variable.withString(threeMonthsLater.toIso8601String()),
      ],
      readsFrom: {products},
    ).getSingle();
    final expiringSoonCount = expiringSoonResult.read<int>('count');

    // Inventory value (requires join with product_units, exclude soft-deleted)
    final valueResult = await customSelect(
      '''
    SELECT SUM(p.current_stock * COALESCE(pu.selling_price, 0)) as total 
    FROM products p
    LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
    WHERE p.is_active = 1 AND p.is_deleted = 0
    ''',
      readsFrom: {products, productUnits},
    ).getSingle();
    final inventoryValue = valueResult.readNullable<double>('total') ?? 0.0;

    // Total cost (exclude soft-deleted)
    final costResult = await customSelect(
      '''
    SELECT SUM(p.current_stock * COALESCE(pu.cost_price, 0)) as total 
    FROM products p
    LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.unit = p.base_unit
    WHERE p.is_active = 1 AND p.is_deleted = 0
    ''',
      readsFrom: {products, productUnits},
    ).getSingle();
    final totalCost = costResult.readNullable<double>('total') ?? 0.0;

    return FullInventoryStatistics(
      totalProducts: totalProducts,
      lowStockCount: lowStockCount,
      criticalStockCount: criticalStockCount,
      outOfStockCount: outOfStockCount,
      expiredCount: expiredCount,
      expiringSoonCount: expiringSoonCount,
      inventoryValue: inventoryValue,
      totalCost: totalCost,
      expectedProfit: inventoryValue - totalCost,
    );
  }

  // 📦 PRODUCT UNITS

  /// Get all units for a product
  Future<List<ProductUnitEntry>> getProductUnits(String productId) {
    return (select(productUnits)..where((u) => u.productId.equals(productId)))
        .get();
  }

  /// Get a specific unit for a product by name
  Future<ProductUnitEntry?> getUnit(String productId, String unitName) {
    return (select(productUnits)
          ..where(
              (u) => u.productId.equals(productId) & u.unit.equals(unitName)))
        .getSingleOrNull();
  }

  /// Watch product units (reactive)
  Stream<List<ProductUnitEntry>> watchProductUnits(String productId) {
    return (select(productUnits)..where((u) => u.productId.equals(productId)))
        .watch();
  }

  /// Insert a product unit
  Future<void> insertProductUnit(ProductUnitsCompanion unit) {
    return into(productUnits).insert(unit);
  }

  /// Update a product unit
  Future<bool> updateProductUnit(ProductUnitEntry unit) {
    return update(productUnits).replace(unit);
  }

  /// Delete a product unit
  Future<int> deleteProductUnit(String unitId) {
    return (delete(productUnits)..where((u) => u.id.equals(unitId))).go();
  }

  /// Delete all units for a product
  Future<int> deleteProductUnits(String productId) {
    return (delete(productUnits)..where((u) => u.productId.equals(productId)))
        .go();
  }

  /// 🛠️ DATA FIX: Recover inactive products that have stock
  Future<int> restoreStockedProducts() async {
    // UPDATE products SET is_active = 1 WHERE current_stock > 0 AND is_active = 0
    final query = update(products)
      ..where((p) =>
          p.currentStock.isBiggerThanValue(0) & p.isActive.equals(false));

    return query.write(const ProductsCompanion(isActive: Value(true)));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🗑️ INACTIVE PRODUCTS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🚀 OPTIMIZED: Get all inactive products with units (Single JOIN Query)
  Future<List<ProductWithUnits>> findInactiveWithUnits() async {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.isActive.equals(false))
      ..orderBy([OrderingTerm.desc(products.updatedAt)]);

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// 🚀 OPTIMIZED: Watch inactive products with units (Reactive & Optimized)
  Stream<List<ProductWithUnits>> watchInactiveWithUnits() {
    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.isActive.equals(false))
      ..orderBy([OrderingTerm.desc(products.updatedAt)]);

    return query.watch().map((rows) => _groupJoinedResults(rows));
  }

  /// Search inactive products with units in SINGLE QUERY
  Future<List<ProductWithUnits>> searchInactiveWithUnits(
      String queryStr) async {
    if (queryStr.trim().isEmpty) {
      return findInactiveWithUnits();
    }

    final query = select(products).join([
      leftOuterJoin(
        productUnits,
        productUnits.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.name.contains(queryStr) |
          products.scientificName.contains(queryStr) |
          products.barcode.equals(queryStr))
      ..where(products.isActive.equals(false))
      ..orderBy([OrderingTerm.desc(products.updatedAt)]);

    final results = await query.get();
    return _groupJoinedResults(results);
  }

  /// Count inactive products
  Future<int> countInactive() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE is_active = 0',
      readsFrom: {products},
    ).map((row) => row.read<int>('count')).getSingle();
    return result;
  }

  /// Hard delete all inactive products (permanent batch deletion)
  /// This will delete all inactive products and their units
  /// Returns the number of affected products
  Future<int> hardDeleteAllInactive() async {
    return transaction(() async {
      // Get all inactive product IDs
      final inactiveProducts = await (select(products)
            ..where((p) => p.isActive.equals(false)))
          .get();

      final productIds = inactiveProducts.map((p) => p.id).toList();

      // Delete all units for inactive products
      for (final id in productIds) {
        await deleteProductUnits(id);
      }

      // Delete all inactive products
      return (delete(products)..where((p) => p.isActive.equals(false))).go();
    });
  }

  /// Activate (restore) a product
  Future<bool> activateProduct(String id) async {
    final affectedRows = await (update(products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(
      isActive: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
    return affectedRows > 0;
  }
}

/// Product statistics model
class ProductStatistics {
  final int totalProducts;
  final int lowStockProducts;
  final int expiredProducts;

  const ProductStatistics({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.expiredProducts,
  });
}

/// Full inventory statistics model
class FullInventoryStatistics {
  final int totalProducts;
  final int lowStockCount;
  final int criticalStockCount;
  final int outOfStockCount;
  final int expiredCount;
  final int expiringSoonCount;
  final double inventoryValue;
  final double totalCost;
  final double expectedProfit;

  const FullInventoryStatistics({
    required this.totalProducts,
    required this.lowStockCount,
    required this.criticalStockCount,
    required this.outOfStockCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.inventoryValue,
    required this.totalCost,
    required this.expectedProfit,
  });
}

/// Product with its related units for sync
class ProductWithUnits {
  final ProductEntry product;
  final List<ProductUnitEntry> units;

  ProductWithUnits({required this.product, required this.units});

  Map<String, dynamic> toMap() {
    return {
      'id': product.id,
      'name': product.name,
      'scientificName': product.scientificName,
      'barcode': product.barcode,
      'currentStock': product.currentStock,
      'minStockLevel': product.minStockLevel,
      'expiryDate': product.expiryDate?.toIso8601String(),
      'isActive': product.isActive,
      'createdAt': product.createdAt.toIso8601String(),
      'updatedAt': product.updatedAt.toIso8601String(),
      'units': units
          .map((u) => {
                'id': u.id,
                'unit': u.unit,
                'sellingPrice': u.sellingPrice,
                'costPrice': u.costPrice,
                'conversionToBase': u.conversionToBase,
              })
          .toList(),
    };
  }
}

/// Product entry with prices from JOIN query (for inventory display)
class ProductEntryWithPrices {
  final String id;
  final String name;
  final String? scientificName;
  final String company;
  final String category;
  final String barcode;
  final String baseUnit;
  final double currentStock;
  final double minStockLevel;
  final DateTime? expiryDate;
  final DateTime? productionDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double sellingPrice;
  final double? costPrice;

  const ProductEntryWithPrices({
    required this.id,
    required this.name,
    this.scientificName,
    required this.company,
    required this.category,
    required this.barcode,
    required this.baseUnit,
    required this.currentStock,
    required this.minStockLevel,
    this.expiryDate,
    this.productionDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.sellingPrice,
    this.costPrice,
  });
}

/// Provider for ProductDriftDao
final productDriftDaoProvider = Provider<ProductDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductDriftDao(db);
});
