import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/entities/add_product_params.dart';
import 'package:larapill/features/inventory/domain/entities/product_entity.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';
import 'package:larapill/features/inventory/domain/usecases/add_product_usecase.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/mock_product_validator.dart';
import '../../mocks/test_data.dart';

void main() {
  group('AddProductUseCase', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late InventoryRepositoryImpl repository;
    late MockProductValidator mockValidator;
    late AddProductUseCase useCase;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      repository = InventoryRepositoryImpl(mockLocalDataSource);
      mockValidator = MockProductValidator();
      useCase = AddProductUseCase(repository, mockValidator);
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    group('call', () {
      test('should add product successfully when validation passes', () async {
        // Arrange
        final params = TestData.createAddProductParams();
        mockValidator.setValidationResult(true);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<ProductEntity>());
        expect(result.right.name, params.name);
        expect(result.right.company, params.company);
      });

      test('should return ValidationFailure when validation fails', () async {
        // Arrange
        final params = TestData.createAddProductParams();
        mockValidator.setValidationResult(false, errors: {
          'name': 'اسم المنتج مطلوب',
        });

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ValidationFailure>());
        expect((result.left as ValidationFailure).fieldErrors['name'],
            'اسم المنتج مطلوب');
      });

      test('should return ValidationFailure when boxCount is zero', () async {
        // Arrange
        final params = AddProductParams(
          name: 'Test Product',
          company: 'Test Company',
          barcode: '1234567890123',
          quantity: 10,
          price: 50.0,
          cost: 30.0,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          boxCount: 0, // Invalid
          unitsPerBox: 10,
          boxCost: 150.0,
          boxPrice: 250.0,
        );
        mockValidator.setValidationResult(true);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ValidationFailure>());
        expect(result.left.message, contains('عدد العلب'));
      });

      test('should return ValidationFailure when unitsPerBox is zero',
          () async {
        // Arrange
        final params = AddProductParams(
          name: 'Test Product',
          company: 'Test Company',
          barcode: '1234567890123',
          quantity: 10,
          price: 50.0,
          cost: 30.0,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          boxCount: 5,
          unitsPerBox: 0, // Invalid
          boxCost: 150.0,
          boxPrice: 250.0,
        );
        mockValidator.setValidationResult(true);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ValidationFailure>());
        expect(result.left.message, contains('التعبئة'));
      });

      test('should check for duplicate barcode when barcode is provided',
          () async {
        // Arrange
        const barcode = '1234567890123';
        final existingProduct = TestData.createProductModel(
          id: '1',
          barcode: barcode,
          name: 'Existing Product',
        );
        await mockLocalDataSource.insertProduct(existingProduct);

        final params = TestData.createAddProductParams(barcode: barcode);
        mockValidator.setValidationResult(true);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DuplicateBarcodeFailure>());
        expect((result.left as DuplicateBarcodeFailure).barcode, barcode);
        expect((result.left as DuplicateBarcodeFailure).existingProductName,
            'Existing Product');
      });

      test('should allow empty barcode without duplicate check', () async {
        // Arrange
        final params = TestData.createAddProductParams(barcode: '');
        mockValidator.setValidationResult(true);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.barcode, '');
      });

      test('should return DatabaseFailure when repository fails', () async {
        // Arrange
        final params = TestData.createAddProductParams();
        mockValidator.setValidationResult(true);
        mockLocalDataSource.throwCacheException('Database error');

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });

      test('should create product with correct data mapping', () async {
        // Arrange
        final params = TestData.createAddProductParams(
          name: 'Paracetamol',
          company: 'PharmaCo',
          barcode: '1234567890123',
          quantity: 100,
          price: 25.0,
          cost: 15.0,
          boxCount: 10,
          unitsPerBox: 10,
          boxCost: 150.0,
          boxPrice: 250.0,
        );
        mockValidator.setValidationResult(true);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight, true);
        expect(result.right.name, 'Paracetamol');
        expect(result.right.company, 'PharmaCo');
        expect(result.right.barcode, '1234567890123');
        expect(result.right.quantity, 100);
        expect(result.right.price, 25.0);
        expect(result.right.costPrice, 15.0);
      });
    });
  });
}
