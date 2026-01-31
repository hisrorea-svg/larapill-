import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/entities/product_entity.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';
import 'package:larapill/features/inventory/domain/usecases/get_all_products_usecase.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/test_data.dart';

void main() {
  group('GetAllProductsUseCase', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late InventoryRepositoryImpl repository;
    late GetAllProductsUseCase useCase;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      repository = InventoryRepositoryImpl(mockLocalDataSource);
      useCase = GetAllProductsUseCase(repository);
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    group('call', () {
      test('should return list of all products', () async {
        // Arrange
        final products = TestData.createProductModels(5);
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<List<ProductEntity>>());
        expect(result.right.length, 5);
      });

      test('should return empty list when no products exist', () async {
        // Arrange
        mockLocalDataSource.setProducts([]);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right, isEmpty);
      });

      test('should return DatabaseFailure when repository fails', () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Database error');

        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });

      test('should return products with correct data mapping', () async {
        // Arrange
        final products = [
          TestData.createProductModel(
            id: '1',
            name: 'Paracetamol',
            company: 'PharmaCo',
            barcode: '1234567890123',
            currentStock: 100.0,
            sellingPrice: 50.0,
          ),
        ];
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Paracetamol');
        expect(result.right.first.company, 'PharmaCo');
        expect(result.right.first.barcode, '1234567890123');
        expect(result.right.first.quantity, 100);
        expect(result.right.first.price, 50.0);
      });

      test('should return large list of products efficiently', () async {
        // Arrange
        final products = TestData.createProductModels(1000);
        mockLocalDataSource.setProducts(products);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1000);
      });
    });
  });
}
