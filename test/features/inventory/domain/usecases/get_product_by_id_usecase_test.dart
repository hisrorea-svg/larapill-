import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/entities/product_entity.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';
import 'package:larapill/features/inventory/domain/usecases/get_product_by_id_usecase.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/test_data.dart';

void main() {
  group('GetProductByIdUseCase', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late InventoryRepositoryImpl repository;
    late GetProductByIdUseCase useCase;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      repository = InventoryRepositoryImpl(mockLocalDataSource);
      useCase = GetProductByIdUseCase(repository);
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    group('call', () {
      test('should return product when found', () async {
        // Arrange
        const productId = 1;
        final product = TestData.createProductModel(
          id: '1',
          name: 'Paracetamol',
          company: 'PharmaCo',
        );
        await mockLocalDataSource.insertProduct(product);

        // Act
        final result = await useCase(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<ProductEntity>());
        expect(result.right?.id, productId);
        expect(result.right?.name, 'Paracetamol');
      });

      test('should return null when product not found', () async {
        // Arrange
        const productId = 999;

        // Act
        final result = await useCase(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isNull);
      });

      test('should return DatabaseFailure when repository fails', () async {
        // Arrange
        const productId = 1;
        mockLocalDataSource.throwCacheException('Database error');

        // Act
        final result = await useCase(productId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });

      test('should handle zero ID gracefully', () async {
        // Arrange
        const productId = 0;

        // Act
        final result = await useCase(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isNull);
      });

      test('should handle negative ID gracefully', () async {
        // Arrange
        const productId = -1;

        // Act
        final result = await useCase(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isNull);
      });

      test('should return product with all fields correctly mapped', () async {
        // Arrange
        const productId = 1;
        final expiryDate = DateTime.now().add(const Duration(days: 365));
        final product = TestData.createProductModel(
          id: '1',
          name: 'Complete Product',
          company: 'Test Company',
          category: 'Tablets',
          barcode: '1234567890123',
          currentStock: 150.0,
          sellingPrice: 75.0,
          costPrice: 50.0,
          expiryDate: expiryDate.toIso8601String(),
        );
        await mockLocalDataSource.insertProduct(product);

        // Act
        final result = await useCase(productId);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isNotNull);
        expect(result.right!.name, 'Complete Product');
        expect(result.right!.company, 'Test Company');
        expect(result.right!.category, 'Tablets');
        expect(result.right!.barcode, '1234567890123');
        expect(result.right!.quantity, 150);
        expect(result.right!.price, 75.0);
        expect(result.right!.costPrice, 50.0);
      });
    });
  });
}
