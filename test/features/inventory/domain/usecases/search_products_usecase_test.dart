import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';
import 'package:larapill/features/inventory/domain/usecases/search_products_usecase.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/test_data.dart';

void main() {
  group('SearchProductsUseCase', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late InventoryRepositoryImpl repository;
    late SearchProductsUseCase useCase;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      repository = InventoryRepositoryImpl(mockLocalDataSource);
      useCase = SearchProductsUseCase(repository);
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    group('call', () {
      test('should return all products when query is empty', () async {
        // Arrange
        final products = TestData.createProductModels(5);
        mockLocalDataSource.setProducts(products);
        const query = '';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 5);
      });

      test('should return all products when query contains only whitespace',
          () async {
        // Arrange
        final products = TestData.createProductModels(3);
        mockLocalDataSource.setProducts(products);
        const query = '   ';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 3);
      });

      test('should return matching products by name', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', name: 'Paracetamol'),
          TestData.createProductModel(id: '2', name: 'Ibuprofen'),
          TestData.createProductModel(id: '3', name: 'Aspirin'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = 'Para';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'Paracetamol');
      });

      test('should return matching products by company', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', company: 'PharmaCo'),
          TestData.createProductModel(id: '2', company: 'MediCorp'),
          TestData.createProductModel(id: '3', company: 'HealthInc'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = 'Pharma';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.company, 'PharmaCo');
      });

      test('should return matching products by barcode', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', barcode: '1234567890123'),
          TestData.createProductModel(id: '2', barcode: '9876543210987'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = '123456';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.barcode, '1234567890123');
      });

      test('should return matching products by category', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', category: 'Tablets'),
          TestData.createProductModel(id: '2', category: 'Syrups'),
          TestData.createProductModel(id: '3', category: 'Injections'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = 'Syrup';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.category, 'Syrups');
      });

      test('should perform case-insensitive search', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', name: 'PARACETAMOL'),
          TestData.createProductModel(id: '2', name: 'ibuprofen'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = 'para';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
        expect(result.right.first.name, 'PARACETAMOL');
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        final products = TestData.createProductModels(3);
        mockLocalDataSource.setProducts(products);
        const query = 'NonExistentProduct';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isEmpty);
      });

      test('should trim whitespace from query', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', name: 'Paracetamol'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = '  Para  ';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
      });

      test('should return DatabaseFailure when repository fails', () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Database error');
        const query = 'test';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });

      test('should handle special characters in query', () async {
        // Arrange
        final products = [
          TestData.createProductModel(id: '1', name: 'Product-123'),
          TestData.createProductModel(id: '2', name: 'Product_456'),
        ];
        mockLocalDataSource.setProducts(products);
        const query = 'Product-';

        // Act
        final result = await useCase(query);

        // Assert
        expect(result.isRight, true);
        expect(result.right.length, 1);
      });
    });
  });
}
