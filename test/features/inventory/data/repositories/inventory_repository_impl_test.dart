import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/datasources/inventory_datasource_interface.dart';
import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/entities/inventory_stats.dart';
import 'package:larapill/features/inventory/domain/entities/paginated_result.dart';
import 'package:larapill/features/inventory/domain/entities/product_entity.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/test_data.dart';

/// Unit type for void success returns
class Unit {
  const Unit();
}

void main() {
  group('InventoryRepositoryImpl', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late MockInventoryRemoteDataSource mockRemoteDataSource;
    late InventoryRepositoryImpl repository;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      mockRemoteDataSource = MockInventoryRemoteDataSource();
      repository = InventoryRepositoryImpl(
        mockLocalDataSource,
        mockRemoteDataSource,
      );
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    // ============ CRUD Operations Tests ============

    group('addProduct', () {
      test('should add product successfully and return right', () async {
        // Arrange
        final params = TestData.createAddProductParams();

        // Act
        final result = await repository.addProduct(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<ProductEntity>());
        expect(result.right.name, params.name);
        expect(result.right.company, params.company);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        final params = TestData.createAddProductParams();
        mockLocalDataSource.throwCacheException('Database connection failed');

        // Act
        final result = await repository.addProduct(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
        expect(result.left.message, 'Database connection failed');
      });

      test('should handle generic exceptions and return DatabaseFailure',
          () async {
        // Arrange
        final params = TestData.createAddProductParams();
        mockLocalDataSource.throwCacheException('');

        // Act
        final result = await repository.addProduct(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('updateProduct', () {
      test('should update product successfully and return right', () async {
        // Arrange
        final product = TestData.createProductEntity(id: 1);
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );

        // Act
        final result = await repository.updateProduct(product);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<ProductEntity>());
        expect(result.right.id, product.id);
        expect(result.right.name, product.name);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        final product = TestData.createProductEntity(id: 1);
        mockLocalDataSource.throwCacheException('Update failed');

        // Act
        final result = await repository.updateProduct(product);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('deleteProduct', () {
      test('should delete product successfully and return right', () async {
        // Arrange
        const productId = 1;
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );

        // Act
        final result = await repository.deleteProduct(productId);

        // Assert
        expect(result.isRight, true);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        const productId = 1;
        mockLocalDataSource.throwCacheException('Delete failed');

        // Act
        final result = await repository.deleteProduct(productId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getProductById', () {
      test('should return product when found', () async {
        // Arrange
        const productId = 1;
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );

        // Act
        final result = await repository.getProductById(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<ProductEntity>());
        expect(result.right?.id, productId);
      });

      test('should return null when product not found', () async {
        // Arrange
        const productId = 999;

        // Act
        final result = await repository.getProductById(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isNull);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        const productId = 1;
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getProductById(productId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getProductByBarcode', () {
      test('should return product when barcode found', () async {
        // Arrange
        const barcode = '1234567890123';
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', barcode: barcode),
        );

        // Act
        final result = await repository.getProductByBarcode(barcode);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<ProductEntity>());
        expect(result.right?.barcode, barcode);
      });

      test('should return null when barcode not found', () async {
        // Arrange
        const barcode = 'nonexistent';

        // Act
        final result = await repository.getProductByBarcode(barcode);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isNull);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        const barcode = '1234567890123';
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getProductByBarcode(barcode);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    // ============ Query Operations Tests ============

    group('getAllProducts', () {
      test('should return list of products', () async {
        // Arrange
        final products = TestData.createProductModels(5);
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<List<ProductEntity>>());
        expect(result.right.length, 5);
      });

      test('should return empty list when no products', () async {
        // Arrange
        mockLocalDataSource.setProducts([]);

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result.isRight, true);
        expect(result.right, isEmpty);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('searchProducts', () {
      test('should return matching products', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', name: 'Paracetamol'),
          TestData.createProductModel(id: '2', name: 'Ibuprofen'),
          TestData.createProductModel(id: '3', name: 'Aspirin'),
        ];
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.searchProducts('Paracetamol');

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Paracetamol');
      });

      test('should return empty list when no matches', () async {
        // Arrange
        final products = TestData.createProductModels(3);
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.searchProducts('NonExistent');

        // Assert
        expect(result.isRight, true);
        expect(result.right, isEmpty);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Search failed');

        // Act
        final result = await repository.searchProducts('test');

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getProductsByCategory', () {
      test('should return products in category', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', category: 'Tablets'),
          TestData.createProductModel(id: '2', category: 'Syrups'),
          TestData.createProductModel(id: '3', category: 'Tablets'),
        ];
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.getProductsByCategory('Tablets');

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 2);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getProductsByCategory('Tablets');

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getLowStockProducts', () {
      test('should return products with low stock', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', currentStock: 100.0),
          TestData.createProductModel(id: '2', currentStock: 5.0),
          TestData.createProductModel(id: '3', currentStock: 3.0),
        ];
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.getLowStockProducts(threshold: 10);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 2);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getLowStockProducts();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getExpiredProducts', () {
      test('should return expired products', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1'),
          TestData.createExpiredProduct(),
        ];
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.getExpiredProducts();

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Expired Product');
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getExpiredProducts();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getExpiringSoonProducts', () {
      test('should return products expiring soon', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1'),
          TestData.createExpiringSoonProduct(),
        ];
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await repository.getExpiringSoonProducts(days: 90);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Expiring Soon Product');
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getExpiringSoonProducts();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    group('getProductsFiltered', () {
      test('should return paginated result', () async {
        // Arrange
        final products = TestData.createProductModels(20);
        mockLocalDataSource.setProducts(products);
        const params = InventoryFilterParams(
          page: 0,
          pageSize: 10,
        );

        // Act
        final result = await repository.getProductsFiltered(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<PaginatedResult<ProductEntity>>());
        expect(result.right.items.length, lessThanOrEqualTo(10));
        expect(result.right.totalCount, 20);
      });

      test('should filter by search query', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', name: 'Paracetamol'),
          TestData.createProductModel(id: '2', name: 'Ibuprofen'),
        ];
        mockLocalDataSource.setProducts(products);
        const params = InventoryFilterParams(
          searchQuery: 'Para',
          page: 0,
          pageSize: 10,
        );

        // Act
        final result = await repository.getProductsFiltered(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.items.length, 1);
        expect(result.right.items.first.name, 'Paracetamol');
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');
        const params = InventoryFilterParams();

        // Act
        final result = await repository.getProductsFiltered(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    // ============ Statistics Tests ============

    group('getInventoryStats', () {
      test('should return inventory stats', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel();
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await repository.getInventoryStats();

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<InventoryStatsEntity>());
        expect(result.right.totalProducts, stats.totalProducts);
        expect(result.right.inventoryValue, stats.inventoryValue);
      });

      test('should return DatabaseFailure when CacheException occurs',
          () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Stats calculation failed');

        // Act
        final result = await repository.getInventoryStats();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });
    });

    // ============ Sync Operations Tests ============

    group('syncPendingChanges', () {
      test('should return 0 when no remote data source', () async {
        // Arrange
        final localOnlyRepository =
            InventoryRepositoryImpl(mockLocalDataSource);

        // Act
        final result = await localOnlyRepository.syncPendingChanges();

        // Assert
        expect(result.isRight, true);
        expect(result.right, 0);
      });

      test('should return NetworkFailure when server not reachable', () async {
        // Arrange
        mockRemoteDataSource.setServerReachable(false);

        // Act
        final result = await repository.syncPendingChanges();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<NetworkFailure>());
      });

      test('should sync pending changes successfully', () async {
        // Arrange
        mockRemoteDataSource.setServerReachable(true);
        await mockLocalDataSource.addToSyncQueue(1, SyncAction.create);
        await mockLocalDataSource.addToSyncQueue(2, SyncAction.update);

        // Act
        final result = await repository.syncPendingChanges();

        // Assert
        expect(result.isRight, true);
        expect(result.right, greaterThanOrEqualTo(0));
      });

      test('should return SyncFailure when ServerException occurs', () async {
        // Arrange
        mockRemoteDataSource.setServerReachable(true);
        mockRemoteDataSource.throwServerException('Sync failed');

        // Act
        final result = await repository.syncPendingChanges();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<SyncFailure>());
      });
    });

    group('getPendingSyncCount', () {
      test('should return pending sync count', () async {
        // Arrange
        await mockLocalDataSource.addToSyncQueue(1, SyncAction.create);
        await mockLocalDataSource.addToSyncQueue(2, SyncAction.update);

        // Act
        final result = await repository.getPendingSyncCount();

        // Assert
        expect(result.isRight, true);
        expect(result.right, 2);
      });

      test('should return 0 when exception occurs', () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Query failed');

        // Act
        final result = await repository.getPendingSyncCount();

        // Assert
        expect(result.isRight, true);
        expect(result.right, 0);
      });
    });

    // ============ Stream Tests ============

    group('watchProducts', () {
      test('should emit list of products', () async {
        // Arrange
        final products = TestData.createProductModels(3);
        mockLocalDataSource.setProducts(products);

        // Act & Assert
        await expectLater(
          repository.watchProducts(),
          emits(isA<List<ProductEntity>>()),
        );
      });
    });

    group('watchProduct', () {
      test('should emit product when found', () async {
        // Arrange
        const productId = 1;
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );

        // Act & Assert
        await expectLater(
          repository.watchProduct(productId),
          emits(isA<ProductEntity>()),
        );
      });

      test('should emit null when product not found', () async {
        // Arrange
        const productId = 999;

        // Act & Assert
        await expectLater(
          repository.watchProduct(productId),
          emits(null),
        );
      });
    });
  });
}
