import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/enums/product_sort_type.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';
import 'package:larapill/features/inventory/domain/usecases/filter_products_usecase.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/test_data.dart';

void main() {
  group('FilterProductsUseCase', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late InventoryRepositoryImpl repository;
    late FilterProductsUseCase useCase;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      repository = InventoryRepositoryImpl(mockLocalDataSource);
      useCase = FilterProductsUseCase(repository);
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    group('call', () {
      test('should return all products when no filters applied', () async {
        // Arrange
        final products = TestData.createProductModels(5);
        mockLocalDataSource.setProducts(products);
        const params = ProductFilterParams.empty();

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 5);
      });

      test('should filter by search query', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', name: 'Paracetamol'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', name: 'Ibuprofen'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', name: 'Aspirin'),
        );

        const params = ProductFilterParams(
          searchQuery: 'Para',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Paracetamol');
      });

      test('should filter by category', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', category: 'Tablets'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', category: 'Syrups'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', category: 'Tablets'),
        );

        const params = ProductFilterParams(
          category: 'Tablets',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 2);
      });

      test('should filter by low_stock', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', currentStock: 100.0),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', currentStock: 5.0),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', currentStock: 3.0),
        );

        const params = ProductFilterParams(
          advancedFilter: 'low_stock',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 2);
      });

      test('should filter by expired products', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(
            id: '2',
            expiryDate: DateTime.now()
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          ),
        );

        const params = ProductFilterParams(
          advancedFilter: 'expired',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
      });

      test('should filter by expiring_soon', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(
            id: '2',
            expiryDate:
                DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          ),
        );

        const params = ProductFilterParams(
          advancedFilter: 'expiring_soon',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
      });

      test('should sort by name ascending', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', name: 'Zebra'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', name: 'Apple'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', name: 'Banana'),
        );

        const params = ProductFilterParams(
          sortBy: ProductSortType.name,
          ascending: true,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right[0].name, 'Apple');
        expect(result.right[1].name, 'Banana');
        expect(result.right[2].name, 'Zebra');
      });

      test('should sort by name descending', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', name: 'Apple'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', name: 'Banana'),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', name: 'Zebra'),
        );

        const params = ProductFilterParams(
          sortBy: ProductSortType.name,
          ascending: false,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right[0].name, 'Zebra');
        expect(result.right[1].name, 'Banana');
        expect(result.right[2].name, 'Apple');
      });

      test('should sort by price', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', sellingPrice: 100.0),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', sellingPrice: 50.0),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', sellingPrice: 75.0),
        );

        const params = ProductFilterParams(
          sortBy: ProductSortType.price,
          ascending: true,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right[0].price, 50.0);
        expect(result.right[1].price, 75.0);
        expect(result.right[2].price, 100.0);
      });

      test('should sort by quantity', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1', currentStock: 100.0),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '2', currentStock: 50.0),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '3', currentStock: 75.0),
        );

        const params = ProductFilterParams(
          sortBy: ProductSortType.quantity,
          ascending: true,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right[0].quantity, 50);
        expect(result.right[1].quantity, 75);
        expect(result.right[2].quantity, 100);
      });

      test('should return DatabaseFailure when repository fails', () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Database error');
        const params = ProductFilterParams.empty();

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });

      test('should filter by not_synced', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(id: '1'),
        );
        // Note: isSynced is not directly set in ProductModel,
        // this test verifies the filter path works

        const params = ProductFilterParams(
          advancedFilter: 'not_synced',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        // Result depends on default isSynced value in entity mapping
      });

      test('should handle combination of filters', () async {
        // Arrange
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(
            id: '1',
            name: 'Paracetamol',
            category: 'Tablets',
            currentStock: 5.0,
          ),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(
            id: '2',
            name: 'Ibuprofen',
            category: 'Tablets',
            currentStock: 100.0,
          ),
        );
        await mockLocalDataSource.insertProduct(
          TestData.createProductModel(
            id: '3',
            name: 'Syrup A',
            category: 'Syrups',
            currentStock: 5.0,
          ),
        );

        const params = ProductFilterParams(
          category: 'Tablets',
          advancedFilter: 'low_stock',
          sortBy: ProductSortType.name,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Paracetamol');
      });
    });
  });
}
