import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:larapill/core/database/drift/app_database.dart';
import 'package:larapill/core/database/drift/daos/daos.dart';
import 'package:larapill/core/exceptions/app_exceptions.dart';
import 'package:larapill/core/models/shared/medicine_unit.dart';
import 'package:larapill/core/models/shared/product.dart';
import 'package:larapill/features/inventory/data/repositories/product_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('ProductRepository - Price Validation Tests', () {
    late AppDatabase db;
    late ProductRepository repository;
    late ProductDriftDao productDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      productDao = ProductDriftDao(db);
      repository = ProductRepository(productDao);
    });

    tearDown(() async {
      await db.close();
    });

    /// Helper to create a test product
    Product createTestProduct({
      required String name,
      required double sellingPrice,
      required double costPrice,
    }) {
      final now = DateTime.now();
      return Product(
        id: const Uuid().v4(),
        name: name,
        company: 'Test Company',
        barcode: 'TEST${now.millisecondsSinceEpoch}',
        baseUnit: MedicineUnit.piece,
        unitInfo: {
          MedicineUnit.piece: UnitInfo(
            sellingPrice: sellingPrice,
            costPrice: costPrice,
            conversionToBase: 1.0,
            description: 'Default unit description', // Required field
          ),
        },
        currentStock: 100,
        minStockLevel: 5,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('✅ Valid Price Tests', () {
      test('should accept valid selling price (greater than 0)', () async {
        final product = createTestProduct(
          name: 'Valid Product',
          sellingPrice: 50.0,
          costPrice: 30.0,
        );

        final id = await repository.insertProduct(product);
        expect(id, isNotEmpty);
      });

      test('should accept zero cost price', () async {
        final product = createTestProduct(
          name: 'Free Cost Product',
          sellingPrice: 50.0,
          costPrice: 0.0,
        );

        final id = await repository.insertProduct(product);
        expect(id, isNotEmpty);
      });
    });

    group('❌ Invalid Price Tests', () {
      test('should reject zero selling price', () async {
        final product = createTestProduct(
          name: 'Invalid Product',
          sellingPrice: 0.0,
          costPrice: 30.0,
        );

        expect(
          () => repository.insertProduct(product),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject negative selling price', () async {
        final product = createTestProduct(
          name: 'Invalid Product',
          sellingPrice: -10.0,
          costPrice: 30.0,
        );

        expect(
          () => repository.insertProduct(product),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject negative cost price', () async {
        final product = createTestProduct(
          name: 'Invalid Product',
          sellingPrice: 50.0,
          costPrice: -5.0,
        );

        expect(
          () => repository.insertProduct(product),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('✏️ Update Product Price Validation', () {
      test('should reject invalid prices on update', () async {
        // First, create a valid product
        final product = createTestProduct(
          name: 'Update Test',
          sellingPrice: 50.0,
          costPrice: 30.0,
        );
        await repository.insertProduct(product);

        // Now try to update with invalid price
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          company: product.company,
          barcode: product.barcode,
          baseUnit: product.baseUnit,
          unitInfo: {
            MedicineUnit.piece: const UnitInfo(
              sellingPrice: 0.0, // Invalid!
              costPrice: 30.0,
              conversionToBase: 1.0,
              description: 'Default unit',
            ),
          },
          currentStock: product.currentStock,
          minStockLevel: product.minStockLevel,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
        );

        expect(
          () => repository.updateProduct(updatedProduct),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}
