/// Product Drift DAO - Type-safe database access for products
///
/// This DAO provides all product-related database operations using Drift.
/// It replaces the legacy ProductDAO with type-safe queries and reactive streams.
library product_drift_dao;

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

  // ═══════════════════════════════════════════════════════════════════════════
  // 📖 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all products (optionally filter by active status)
  Future<List<ProductEntry>> findAll({bool activeOnly = true}) {
    final query = select(products);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    return query.get();
  }

  /// Watch all products (reactive stream)
  Stream<List<ProductEntry>> watchAll({bool activeOnly = true}) {
    final query = select(products);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    return query.watch();
  }

  /// Find product by ID
  Future<ProductEntry?> findById(String id) {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Find product by barcode
  Future<ProductEntry?> findByBarcode(String barcode) {
    return (select(products)..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Check if barcode exists (for validation)
  Future<bool> isBarcodeExists(String barcode, {String? excludeProductId}) {
    var query = select(products)..where((p) => p.barcode.equals(barcode));
    if (excludeProductId != null) {
      query = query..where((p) => p.id.equals(excludeProductId).not());
    }
    return query.getSingleOrNull().then((result) => result != null);
  }

  /// Search products by name, scientific name, company, or barcode
  Future<List<ProductEntry>> search(String query) {
    final searchTerm = '%$query%';
    return (select(products)
          ..where((p) =>
              p.name.like(searchTerm) |
              p.scientificName.like(searchTerm) |
              p.company.like(searchTerm) |
              p.barcode.like(searchTerm))
          ..where((p) => p.isActive.equals(true)))
        .get();
  }

  /// Watch search results (reactive)
  Stream<List<ProductEntry>> watchSearch(String query) {
    final searchTerm = '%$query%';
    return (select(products)
          ..where((p) =>
              p.name.like(searchTerm) |
              p.scientificName.like(searchTerm) |
              p.company.like(searchTerm) |
              p.barcode.like(searchTerm))
          ..where((p) => p.isActive.equals(true)))
        .watch();
  }

  /// Find products with low stock
  Future<List<ProductEntry>> findLowStock() {
    return customSelect(
      'SELECT * FROM products WHERE current_stock <= min_stock_level AND is_active = 1',
      readsFrom: {products},
    ).map((row) => products.map(row.data)).get();
  }

  /// Watch low stock products (reactive)
  Stream<List<ProductEntry>> watchLowStock() {
    return customSelect(
      'SELECT * FROM products WHERE current_stock <= min_stock_level AND is_active = 1',
      readsFrom: {products},
    ).map((row) => products.map(row.data)).watch();
  }

  /// Find products expiring soon
  Future<List<ProductEntry>> findExpiringSoon({int daysThreshold = 30}) {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    return (select(products)
          ..where((p) => p.expiryDate.isSmallerOrEqualValue(thresholdDate))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.expiryDate)]))
        .get();
  }

  /// Watch expiring products
  Stream<List<ProductEntry>> watchExpiringSoon({int daysThreshold = 30}) {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
    return (select(products)
          ..where((p) => p.expiryDate.isSmallerOrEqualValue(thresholdDate))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.expiryDate)]))
        .watch();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✏️ WRITE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Insert a new product
  Future<void> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  /// Update an existing product
  Future<bool> updateProduct(ProductEntry product) {
    return update(products).replace(product);
  }

  /// Update specific fields of a product
  Future<int> updateProductFields(String productId, ProductsCompanion updates) {
    return (update(products)..where((p) => p.id.equals(productId)))
        .write(updates);
  }

  /// Update stock quantity
  Future<int> updateStock(String productId, double newStock) {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        currentStock: Value(newStock),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete (set isActive to false)
  Future<int> softDelete(String productId) {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard delete a product
  Future<int> deleteProduct(String productId) {
    return (delete(products)..where((p) => p.id.equals(productId))).go();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get product statistics
  Future<ProductStatistics> getStatistics() async {
    final totalCount = await (selectOnly(products)
          ..addColumns([products.id.count()])
          ..where(products.isActive.equals(true)))
        .map((row) => row.read(products.id.count()))
        .getSingle();

    final lowStockCount = await customSelect(
      'SELECT COUNT(*) as count FROM products WHERE current_stock <= min_stock_level AND is_active = 1',
      readsFrom: {products},
    ).map((row) => row.read<int>('count')).getSingle();

    final expiredCount = await (selectOnly(products)
          ..addColumns([products.id.count()])
          ..where(products.expiryDate.isSmallerOrEqualValue(DateTime.now()))
          ..where(products.isActive.equals(true)))
        .map((row) => row.read(products.id.count()))
        .getSingle();

    return ProductStatistics(
      totalProducts: totalCount ?? 0,
      lowStockProducts: lowStockCount,
      expiredProducts: expiredCount ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 PRODUCT UNITS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get units for a product
  Future<List<ProductUnitEntry>> getProductUnits(String productId) {
    return (select(productUnits)..where((u) => u.productId.equals(productId)))
        .get();
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

// ═══════════════════════════════════════════════════════════════════════════
// 🔌 RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for ProductDriftDao
final productDriftDaoProvider = Provider<ProductDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductDriftDao(db);
});

/// Stream provider for all active products
final allProductsStreamProvider = StreamProvider<List<ProductEntry>>((ref) {
  final dao = ref.watch(productDriftDaoProvider);
  return dao.watchAll();
});

/// Stream provider for low stock products
final lowStockProductsStreamProvider =
    StreamProvider<List<ProductEntry>>((ref) {
  final dao = ref.watch(productDriftDaoProvider);
  return dao.watchLowStock();
});

/// Stream provider for expiring products
final expiringProductsStreamProvider =
    StreamProvider.family<List<ProductEntry>, int>((ref, daysThreshold) {
  final dao = ref.watch(productDriftDaoProvider);
  return dao.watchExpiringSoon(daysThreshold: daysThreshold);
});

/// Future provider for product statistics
final productStatisticsProvider = FutureProvider<ProductStatistics>((ref) {
  final dao = ref.watch(productDriftDaoProvider);
  return dao.getStatistics();
});
