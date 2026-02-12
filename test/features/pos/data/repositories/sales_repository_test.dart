import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:larapill/core/database/drift/app_database.dart';
import 'package:larapill/core/database/drift/daos/daos.dart';
import 'package:larapill/core/exceptions/app_exceptions.dart';
import 'package:larapill/features/pos/data/repositories/sales_repository.dart';
import 'package:larapill/features/pos/domain/entities/sale.dart';
import 'package:larapill/core/models/shared/medicine_unit.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:uuid/uuid.dart';

void main() {
  group('SalesRepository - Atomic Transaction Tests', () {
    late AppDatabase db;
    late SalesRepository repository;
    late ProductDriftDao productDao;
    late SalesDriftDao salesDao;
    late InventoryTransactionDriftDao inventoryDao;
    late CustomerDebtDriftDao debtDao;
    late DailyPurchaseRequestDriftDao purchaseDao;
    late AuditLogDriftDao auditDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // Initialize DAOs
      productDao = ProductDriftDao(db);
      salesDao = SalesDriftDao(db);
      inventoryDao = InventoryTransactionDriftDao(db);
      debtDao = CustomerDebtDriftDao(db);
      purchaseDao = DailyPurchaseRequestDriftDao(db);
      auditDao = AuditLogDriftDao(db);

      // Create repository with all dependencies
      repository = SalesRepository(
        salesDao,
        productDao,
        debtDao,
        purchaseDao,
        auditDao,
        inventoryDao,
        db,
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// Helper to create a test product with stock
    Future<String> createTestProduct({
      required String name,
      required double initialStock,
      required double sellingPrice,
    }) async {
      final productId = const Uuid().v4();
      final now = DateTime.now();

      await productDao.insertProduct(
        ProductsCompanion.insert(
          id: productId,
          name: name,
          company: 'Test Company',
          category: 'Test Category',
          barcode: 'TEST${DateTime.now().millisecondsSinceEpoch}',
          baseUnit: 'piece',
          currentStock: Value(initialStock),
          minStockLevel: const Value(5),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Add default unit
      await productDao.insertProductUnit(
        ProductUnitsCompanion.insert(
          id: const Uuid().v4(),
          productId: productId,
          unit: 'piece',
          conversionToBase: const Value(1),
          sellingPrice: sellingPrice,
          costPrice: sellingPrice * 0.7,
          description: 'Default unit',
        ),
      );

      return productId;
    }

    /// Helper to create a test sale
    Sale createTestSale({
      required String productId,
      required String productName,
      required double quantity,
      required double unitPrice,
    }) {
      final now = DateTime.now();
      final total = quantity * unitPrice;

      return Sale(
        id: const Uuid().v4(),
        date: now,
        items: [
          SaleItem(
            id: const Uuid().v4(),
            productId: productId,
            productName: productName,
            quantity: quantity,
            unitPrice: unitPrice,
            total: total,
            unit: MedicineUnit.piece,
          ),
        ],
        subtotal: total,
        total: total,
        discount: 0,
        tax: 0,
        paymentMethod: PaymentMethod.cash,
        cashierId: 'test-cashier',
        cashierName: 'Test Cashier',
        status: SaleStatus.completed,
        createdAt: now,
      );
    }

    group('✅ Successful Sale Flow', () {
      test('should save sale, deduct stock, and record inventory transaction',
          () async {
        // Arrange: Create product with 100 stock
        final productId = await createTestProduct(
          name: 'Test Product',
          initialStock: 100,
          sellingPrice: 50,
        );

        final sale = createTestSale(
          productId: productId,
          productName: 'Test Product',
          quantity: 10,
          unitPrice: 50,
        );

        // Act: Save sale
        final saleId = await repository.saveSale(sale, userId: 'test-user');

        // Assert 1: Sale saved
        expect(saleId, isNotEmpty);
        final savedSale = await salesDao.findById(saleId);
        expect(savedSale, isNotNull);
        expect(savedSale!.total, equals(500)); // 10 * 50

        // Assert 2: Stock deducted
        final product = await productDao.findById(productId);
        expect(product!.currentStock, equals(90)); // 100 - 10

        // Assert 3: Inventory transaction recorded
        final transactions =
            await inventoryDao.getTransactionsByProduct(productId);
        expect(transactions.length, equals(1));
        expect(transactions.first.type, equals('OUT'));
        expect(transactions.first.quantity, equals(-10)); // Negative for OUT
        expect(transactions.first.referenceType, equals('sale'));
        expect(transactions.first.referenceId, equals(saleId));
      });

      test('should handle multiple items in single sale', () async {
        // Arrange: Create two products
        final product1Id = await createTestProduct(
          name: 'Product 1',
          initialStock: 50,
          sellingPrice: 30,
        );
        final product2Id = await createTestProduct(
          name: 'Product 2',
          initialStock: 30,
          sellingPrice: 40,
        );

        final now = DateTime.now();
        final sale = Sale(
          id: const Uuid().v4(),
          date: now,
          items: [
            SaleItem(
              id: const Uuid().v4(),
              productId: product1Id,
              productName: 'Product 1',
              quantity: 5,
              unitPrice: 30,
              total: 150,
              unit: MedicineUnit.piece,
            ),
            SaleItem(
              id: const Uuid().v4(),
              productId: product2Id,
              productName: 'Product 2',
              quantity: 3,
              unitPrice: 40,
              total: 120,
              unit: MedicineUnit.piece,
            ),
          ],
          subtotal: 270,
          total: 270,
          discount: 0,
          tax: 0,
          paymentMethod: PaymentMethod.cash,
          cashierId: 'test-cashier',
          cashierName: 'Test Cashier',
          status: SaleStatus.completed,
          createdAt: now,
        );

        // Act
        await repository.saveSale(sale);

        // Assert: Both stocks deducted
        final product1 = await productDao.findById(product1Id);
        final product2 = await productDao.findById(product2Id);
        expect(product1!.currentStock, equals(45)); // 50 - 5
        expect(product2!.currentStock, equals(27)); // 30 - 3

        // Assert: Both transactions recorded
        final transactions1 =
            await inventoryDao.getTransactionsByProduct(product1Id);
        final transactions2 =
            await inventoryDao.getTransactionsByProduct(product2Id);
        expect(transactions1.length, equals(1));
        expect(transactions2.length, equals(1));
      });
    });

    group('❌ Transaction Rollback Tests', () {
      test('should rollback all changes when stock is insufficient', () async {
        // Arrange: Create product with only 5 stock
        final productId = await createTestProduct(
          name: 'Limited Stock Product',
          initialStock: 5,
          sellingPrice: 100,
        );

        final sale = createTestSale(
          productId: productId,
          productName: 'Limited Stock Product',
          quantity: 10, // Try to sell more than available
          unitPrice: 100,
        );

        // Act & Assert: Should throw InsufficientStockException
        expect(
          () => repository.saveSale(sale),
          throwsA(isA<InsufficientStockException>()),
        );

        // Assert: Stock unchanged (rollback worked)
        final product = await productDao.findById(productId);
        expect(product!.currentStock, equals(5));

        // Assert: No inventory transaction recorded
        final transactions =
            await inventoryDao.getTransactionsByProduct(productId);
        expect(transactions.length, equals(0));

        // Assert: No sale recorded
        final allSales = await salesDao.findAll();
        expect(allSales.length, equals(0));
      });

      test('should rollback when product is soft deleted', () async {
        // Arrange: Create product and soft delete it
        final productId = await createTestProduct(
          name: 'Deleted Product',
          initialStock: 100,
          sellingPrice: 50,
        );

        // Soft delete the product
        await productDao.softDelete(productId, deletedBy: 'test-user');

        final sale = createTestSale(
          productId: productId,
          productName: 'Deleted Product',
          quantity: 5,
          unitPrice: 50,
        );

        // Act & Assert: Should throw DomainException
        expect(
          () => repository.saveSale(sale),
          throwsA(isA<DomainException>()),
        );

        // Assert: No sale recorded
        final allSales = await salesDao.findAll();
        expect(allSales.length, equals(0));
      });
    });

    group('🔒 Audit Trail Tests', () {
      test('should record createdBy in sale and inventory transaction',
          () async {
        // Arrange
        final productId = await createTestProduct(
          name: 'Audit Test Product',
          initialStock: 100,
          sellingPrice: 50,
        );

        final sale = createTestSale(
          productId: productId,
          productName: 'Audit Test Product',
          quantity: 5,
          unitPrice: 50,
        );

        // Act
        await repository.saveSale(sale,
            userId: 'user-123', userName: 'Test User');

        // Assert: Sale has createdBy
        final savedSale = await salesDao.findById(sale.id);
        expect(savedSale!.createdBy, equals('user-123'));

        // Assert: Inventory transaction has createdBy
        final transactions =
            await inventoryDao.getTransactionsByProduct(productId);
        expect(transactions.first.createdBy, equals('user-123'));
      });
    });
  });
}
