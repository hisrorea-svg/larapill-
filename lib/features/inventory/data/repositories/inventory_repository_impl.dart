import 'dart:async';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/add_product_params.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/inventory_stats.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/failures/inventory_failure.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../infrastructure/inventory_sync_interface.dart';
import '../mappers/product_mapper.dart';
import '../../../../core/database/drift/daos/daos.dart';
import '../../../../core/database/drift/app_database.dart';

/// Repository implementation with offline-first strategy using Drift DAO directly
///
/// Architecture: Repository → DAO → Database
/// ```
/// UI → Controller → Repository → ProductDriftDao → Database
/// ```
class InventoryRepositoryImpl implements InventoryRepository {
  final ProductDriftDao _dao;
  final InventorySyncApi? _syncApi;
  final Uuid _uuid = const Uuid();

  InventoryRepositoryImpl(
    this._dao, [
    this._syncApi,
  ]);

  // ============ CRUD Operations ============

  @override
  Future<Either<InventoryFailure, ProductEntity>> addProduct(
      AddProductParams params) async {
    try {
      final newId = _uuid.v4();
      final now = DateTime.now();

      // ✅ تحديد الوحدة الأساسية بناءً على التعبئة
      final hasBox = params.unitsPerBox > 1;
      const baseUnitName = 'piece'; // الوحدة الأساسية دائماً piece

      // Insert product using DAO
      await _dao.insertProduct(ProductsCompanion(
        id: Value(newId),
        name: Value(params.name),
        company: Value(params.company),
        category: const Value('medicalSupplies'),
        barcode: Value(params.barcode.trim()),
        baseUnit: const Value(baseUnitName),
        currentStock: Value(params.quantity.toDouble()),
        minStockLevel: const Value(5.0),
        expiryDate: Value(params.expiryDate),
        createdAt: Value(now),
        updatedAt: Value(now),
        isActive: const Value(true),
      ));

      // Insert base unit (piece/وحدة)
      await _dao.insertProductUnit(ProductUnitsCompanion(
        id: Value(_uuid.v4()),
        productId: Value(newId),
        unit: const Value('piece'),
        sellingPrice: Value(params.price),
        costPrice: Value(params.cost),
        conversionToBase: const Value(1.0),
        description: const Value('وحدة'),
        quantity: Value(params.quantity),
      ));

      // ✅ إذا المنتج له تعبئة (علبة + وحدات) → أضف وحدة العلبة
      if (hasBox) {
        await _dao.insertProductUnit(ProductUnitsCompanion(
          id: Value(_uuid.v4()),
          productId: Value(newId),
          unit: const Value('box'),
          sellingPrice: Value(params.boxPrice),
          costPrice: Value(params.boxCost),
          conversionToBase: Value(params.unitsPerBox.toDouble()),
          description: const Value('علبة'),
          quantity: Value(params.boxCount),
        ));
      }

      final savedEntity = ProductEntity(
        id: newId, // ✅ String UUID directly
        name: params.name,
        company: params.company,
        category: 'medicalSupplies',
        barcode: params.barcode,
        quantity: params.quantity,
        price: params.price,
        costPrice: params.cost,
        expiryDate: params.expiryDate,
        createdAt: now,
        updatedAt: now,
        isSynced: true,
      );

      developer.log('✅ Added product: ${savedEntity.name} (hasBox: $hasBox)',
          name: 'InventoryRepository');
      return Either.right(savedEntity);
    } catch (e) {
      developer.log('❌ Error adding product: $e', name: 'InventoryRepository');

      // ✅ تحويل أخطاء SQLite لرسائل مفهومة
      final errorMsg = _getFriendlyErrorMessage(e.toString());
      return Either.left(DatabaseFailure(errorMsg));
    }
  }

  /// تحويل أخطاء SQLite لرسائل عربية واضحة
  String _getFriendlyErrorMessage(String error) {
    if (error.contains('2067') || error.contains('UNIQUE constraint failed')) {
      if (error.contains('barcode')) {
        return 'هذا الباركود مسجل مسبقاً لمنتج آخر';
      }
      return 'هذا المنتج موجود مسبقاً';
    }
    if (error.contains('NOT NULL constraint failed')) {
      if (error.contains('barcode')) {
        return 'يجب إدخال الباركود';
      }
      if (error.contains('name')) {
        return 'يجب إدخال اسم المنتج';
      }
      return 'يوجد حقل مطلوب فارغ';
    }
    if (error.contains('FOREIGN KEY constraint failed')) {
      return 'خطأ في ربط البيانات';
    }
    return 'فشل إضافة المنتج - يرجى المحاولة مرة أخرى';
  }

  @override
  Future<Either<InventoryFailure, ProductEntity>> updateProduct(
      ProductEntity product) async {
    try {
      final now = DateTime.now();
      final productId = product.id.toString();

      // 1. Update basic product fields
      await _dao.updateProductFields(
        productId,
        ProductsCompanion(
          name: Value(product.name),
          company: Value(product.company),
          category: Value(product.category),
          barcode: Value(product.barcode),
          currentStock: Value(product.quantity.toDouble()),
          expiryDate: Value(product.expiryDate),
          updatedAt: Value(now),
        ),
      );

      // 2. Update prices in product_units
      // For safety and simplicity, we delete and re-insert units
      // This ensures we don't have orphaned units if the unit structure changes
      await _dao.deleteProductUnits(productId);

      // Insert piece unit (always base)
      await _dao.insertProductUnit(ProductUnitsCompanion(
        id: Value(_uuid.v4()),
        productId: Value(productId),
        unit: const Value('piece'),
        sellingPrice: Value(product.price),
        costPrice: Value(product.costPrice ?? 0.0),
        conversionToBase: const Value(1.0),
        description: const Value('وحدة'),
        quantity: Value(product.quantity),
      ));

      // Note: If you want to support specialized units from Inventory module,
      // it would require adding those to ProductEntity or a specialized Params object.
      // Currently, InventoryRepositoryImpl seems to focus on the 'piece' (base) level.

      developer.log('✅ Updated product and prices: ${product.name}',
          name: 'InventoryRepository');
      return Either.right(product.copyWith(updatedAt: now));
    } catch (e) {
      developer.log('❌ Error updating product: $e',
          name: 'InventoryRepository');
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, Unit>> deleteProduct(String id) async {
    try {
      developer.log('🗑️ Repository: Deleting product ID: $id',
          name: 'InventoryRepository');

      final affectedRows = await _dao.softDelete(id);

      if (affectedRows == 0) {
        developer.log('⚠️ Repository: No product found to delete with ID: $id',
            name: 'InventoryRepository');
        return Either.left(ProductNotFoundFailure(id));
      }

      developer.log('✅ Repository: Soft deleted product ID: $id (affected: $affectedRows)',
          name: 'InventoryRepository');
      return const Either.right(Unit.unit);
    } catch (e, stackTrace) {
      developer.log('❌ Repository: Error deleting product: $e',
          name: 'InventoryRepository', error: e, stackTrace: stackTrace);
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, ProductEntity?>> getProductById(
      String id) async {
    try {
      final entry = await _dao.findById(id);
      if (entry == null) return const Either.right(null);
      return Either.right(ProductMapper.fromEntry(entry));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, ProductEntity?>> getProductByBarcode(
      String barcode) async {
    try {
      final entry = await _dao.findByBarcode(barcode);
      if (entry == null) return const Either.right(null);
      return Either.right(ProductMapper.fromEntry(entry));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  // ============ Query Operations ============

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getAllProducts() async {
    try {
      // 🚀 Use optimized JOIN method to get prices
      final entries = await _dao.findAllWithUnitsOptimized();
      final entities = entries
          .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
          .toList();
      return Either.right(entities);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> searchProducts(
      String query) async {
    try {
      // 🚀 Use optimized Search JOIN method to get prices
      final entries = await _dao.searchWithUnits(query);
      final entities = entries
          .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
          .toList();
      return Either.right(entities);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getProductsByCategory(
      String category) async {
    try {
      final entries = await _dao.findByCategory(category);
      final entities = ProductMapper.fromEntryList(entries);
      return Either.right(entities);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getLowStockProducts(
      {int threshold = 20}) async {
    try {
      // 🚀 Use optimized JOIN method
      final entries = await _dao.findLowStockWithUnits();
      final entities = entries
          .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
          .toList();
      return Either.right(entities);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>>
      getExpiredProducts() async {
    try {
      // 🚀 Use optimized JOIN method
      final entries = await _dao.findExpiredWithUnits();
      final entities = entries
          .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
          .toList();
      return Either.right(entities);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getExpiringSoonProducts(
      {int days = 90}) async {
    try {
      // 🚀 Use optimized JOIN method
      final entries = await _dao.findExpiringSoonWithUnits(daysThreshold: days);
      final entities = entries
          .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
          .toList();
      return Either.right(entities);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, PaginatedResult<ProductEntity>>>
      getProductsFiltered(InventoryFilterParams params) async {
    try {
      final (entries, totalCount) = await _dao.getProductsFiltered(
        searchQuery: params.searchQuery,
        category: params.categoryEnumName,
        stockFilter: params.stockFilter,
        limit: params.pageSize,
        offset: params.offset,
      );

      final entities = entries
          .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
          .toList();

      final result = PaginatedResult<ProductEntity>(
        items: entities,
        totalCount: totalCount,
        currentPage: params.page,
        pageSize: params.pageSize,
      );

      return Either.right(result);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  // ============ Statistics ============

  @override
  Future<Either<InventoryFailure, InventoryStatsEntity>>
      getInventoryStats() async {
    try {
      final stats = await _dao.getFullStatistics();

      final statsEntity = InventoryStatsEntity(
        totalProducts: stats.totalProducts,
        lowStockCount: stats.lowStockCount,
        criticalStockCount: stats.criticalStockCount,
        outOfStockCount: stats.outOfStockCount,
        expiredCount: stats.expiredCount,
        expiringSoonCount: stats.expiringSoonCount,
        inventoryValue: stats.inventoryValue,
        totalCost: stats.totalCost,
        expectedProfit: stats.expectedProfit,
        pendingSyncCount: 0,
      );

      return Either.right(statsEntity);
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  // ============ Sync Operations ============

  @override
  Future<Either<InventoryFailure, int>> syncPendingChanges() async {
    if (_syncApi == null) {
      return const Either.right(0);
    }
    // Sync logic would go here
    return const Either.right(0);
  }

  @override
  Future<Either<InventoryFailure, int>> getPendingSyncCount() async {
    return const Either.right(0);
  }

  // ============ Streams ============

  @override
  Stream<List<ProductEntity>> watchProducts() {
    // 🚀 Use optimized JOIN watch method
    return _dao.watchAllWithUnits().map((list) => list
        .map((pwu) => ProductMapper.fromWrappedEntry(pwu.product, pwu.units))
        .toList());
  }

  @override
  Stream<ProductEntity?> watchProduct(String id) {
    return _dao.watchById(id).map((entry) {
      if (entry == null) return null;
      return ProductMapper.fromEntry(entry);
    });
  }
}
