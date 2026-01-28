import 'dart:async';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';

import '../../../../database/daos/product_dao.dart';
import '../../../../models/product.dart';
import '../../../../models/medicine_unit.dart';
import '../../domain/entities/add_product_params.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/inventory_stats.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/failures/inventory_failure.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_datasource_interface.dart';
import '../mappers/product_mapper.dart';
import '../mappers/inventory_stats_mapper.dart';

/// Repository implementation with offline-first strategy
/// 1. Always read from local first
/// 2. Write to local immediately
/// 3. Queue operations for remote sync
/// 4. Sync to remote in background when connected
///
/// TODO: Unit Tests - إضافة اختبارات وحدة للـ Repository و UseCases
/// TODO: Remote DataSource - تنفيذ InventoryRemoteDataSourceImpl عند توفر API
/// TODO: Sync Indicator - إضافة مؤشر مزامنة في واجهة المستخدم
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource _localDataSource;
  final InventoryRemoteDataSource? _remoteDataSource;
  final ProductDAO _productDao = ProductDAO();

  InventoryRepositoryImpl(
    this._localDataSource, [
    this._remoteDataSource,
  ]);

  // ============ CRUD Operations ============

  @override
  Future<Either<InventoryFailure, ProductEntity>> addProduct(
      AddProductParams params) async {
    try {
      // Generate UUID for the product
      final productId = const Uuid().v4();

      final product = Product(
        id: productId,
        name: params.name,
        company: params.company,
        barcode: params.barcode,
        baseUnit: MedicineUnit.strip,
        unitInfo: {
          MedicineUnit.strip: UnitInfo(
            sellingPrice: params.price,
            costPrice: params.cost,
            conversionToBase: 1,
            description: 'وحدة',
          ),
          MedicineUnit.box: UnitInfo(
            sellingPrice: params.boxPrice,
            costPrice: params.boxCost,
            conversionToBase: params.unitsPerBox.toDouble(),
            description: 'علبة',
          ),
        },
        currentStock: params.quantity.toDouble(),
        minStockLevel: 10.0,
        expiryDate: params.expiryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _productDao.insert(product);

      final savedEntity = ProductEntity(
        id: 0,
        name: params.name,
        company: params.company,
        category: 'medicalSupplies',
        barcode: params.barcode,
        quantity: params.quantity,
        price: params.price,
        costPrice: params.cost,
        expiryDate: params.expiryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      if (_remoteDataSource != null) {
        _triggerBackgroundSync();
      }

      developer.log('✅ Added product: ${savedEntity.name}',
          name: 'InventoryRepository');
      return Either.right(savedEntity);
    } on Exception catch (e) {
      developer.log('❌ Error adding product: $e', name: 'InventoryRepository');
      return Either.left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<InventoryFailure, ProductEntity>> updateProduct(
      ProductEntity product) async {
    try {
      final model = ProductMapper.toModel(product);
      final updatedModel = await _localDataSource.updateProduct(model);
      final updatedEntity = ProductMapper.toEntity(updatedModel);

      if (_remoteDataSource != null) {
        await _localDataSource.addToSyncQueue(
            updatedEntity.id, SyncAction.update);
        _triggerBackgroundSync();
      }

      developer.log('✅ Updated product: ${updatedEntity.name}',
          name: 'InventoryRepository');
      return Either.right(updatedEntity);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, Unit>> deleteProduct(int id) async {
    try {
      await _localDataSource.deleteProduct(id);

      if (_remoteDataSource != null) {
        await _localDataSource.addToSyncQueue(id, SyncAction.delete);
        _triggerBackgroundSync();
      }

      developer.log('✅ Deleted product ID: $id', name: 'InventoryRepository');
      return const Either.right(Unit.unit);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, ProductEntity?>> getProductById(
      int id) async {
    try {
      final model = await _localDataSource.getProductById(id);
      if (model == null) return const Either.right(null);
      return Either.right(ProductMapper.toEntity(model));
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, ProductEntity?>> getProductByBarcode(
      String barcode) async {
    try {
      final model = await _localDataSource.getProductByBarcode(barcode);
      if (model == null) return const Either.right(null);
      return Either.right(ProductMapper.toEntity(model));
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  // ============ Query Operations ============

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getAllProducts() async {
    try {
      final models = await _localDataSource.getAllProducts();
      final entities = ProductMapper.toEntityList(models);
      return Either.right(entities);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> searchProducts(
      String query) async {
    try {
      final models = await _localDataSource.searchProducts(query);
      final entities = ProductMapper.toEntityList(models);
      return Either.right(entities);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getProductsByCategory(
      String category) async {
    try {
      final models = await _localDataSource.getProductsByCategory(category);
      final entities = ProductMapper.toEntityList(models);
      return Either.right(entities);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getLowStockProducts(
      {int threshold = 20}) async {
    try {
      final models = await _localDataSource.getLowStockProducts(threshold);
      final entities = ProductMapper.toEntityList(models);
      return Either.right(entities);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>>
      getExpiredProducts() async {
    try {
      final models = await _localDataSource.getExpiredProducts();
      final entities = ProductMapper.toEntityList(models);
      return Either.right(entities);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, List<ProductEntity>>> getExpiringSoonProducts(
      {int days = 90}) async {
    try {
      final models = await _localDataSource.getExpiringSoonProducts(days);
      final entities = ProductMapper.toEntityList(models);
      return Either.right(entities);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, PaginatedResult<ProductEntity>>>
      getProductsFiltered(InventoryFilterParams params) async {
    try {
      final (models, totalCount) = await _localDataSource.getProductsFiltered(
        searchQuery: params.searchQuery,
        categoryEnumName: params.categoryEnumName,
        stockFilter: params.stockFilter,
        limit: params.pageSize,
        offset: params.offset,
      );

      final entities = ProductMapper.toEntityList(models);

      final result = PaginatedResult<ProductEntity>(
        items: entities,
        totalCount: totalCount,
        currentPage: params.page,
        pageSize: params.pageSize,
      );

      return Either.right(result);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  // ============ Statistics ============

  @override
  Future<Either<InventoryFailure, InventoryStatsEntity>>
      getInventoryStats() async {
    try {
      final statsModel = await _localDataSource.calculateStats();
      final statsEntity = InventoryStatsMapper.toEntity(statsModel);
      return Either.right(statsEntity);
    } on CacheException catch (e) {
      return Either.left(DatabaseFailure(e.message));
    } catch (e) {
      return Either.left(DatabaseFailure('فشل غير متوقع: $e'));
    }
  }

  // ============ Sync Operations ============

  @override
  Future<Either<InventoryFailure, int>> syncPendingChanges() async {
    if (_remoteDataSource == null) {
      return const Either.right(0); // No remote, nothing to sync
    }

    try {
      // Check if server is reachable
      final isReachable = await _remoteDataSource!.isServerReachable();
      if (!isReachable) {
        return const Either.left(NetworkFailure());
      }

      // Get pending operations
      final pendingOps = await _localDataSource.getPendingSyncOperations();
      if (pendingOps.isEmpty) {
        return const Either.right(0);
      }

      // Sync to server
      final syncedCount = await _remoteDataSource!.syncChanges(pendingOps);

      // Remove synced operations
      for (final op in pendingOps.take(syncedCount)) {
        await _localDataSource.removeSyncOperation(op['id'] as int);
        await _localDataSource.markAsSynced(op['product_id'] as int);
      }

      developer.log('✅ Synced $syncedCount changes',
          name: 'InventoryRepository');
      return Either.right(syncedCount);
    } on ServerException catch (e) {
      return Either.left(SyncFailure(e.message));
    } catch (e) {
      return Either.left(SyncFailure('فشل المزامنة: $e'));
    }
  }

  @override
  Future<Either<InventoryFailure, int>> getPendingSyncCount() async {
    try {
      final count = await _localDataSource.getPendingSyncCount();
      return Either.right(count);
    } catch (e) {
      return const Either.right(0);
    }
  }

  // ============ Streams ============

  @override
  Stream<List<ProductEntity>> watchProducts() {
    return _localDataSource.watchProducts().map(ProductMapper.toEntityList);
  }

  @override
  Stream<ProductEntity?> watchProduct(int id) {
    return _localDataSource.watchProduct(id).map((model) {
      if (model == null) return null;
      return ProductMapper.toEntity(model);
    });
  }

  // ============ Background Sync ============

  void _triggerBackgroundSync() {
    // Fire-and-forget background sync
    Future.delayed(const Duration(seconds: 5), () {
      syncPendingChanges();
    });
  }
}
