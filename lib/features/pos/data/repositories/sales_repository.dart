import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/mappers/sale_mapper.dart';
import '../../domain/entities/sale.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/input_sanitizer.dart';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../../../core/database/drift/daos/daos.dart';

class SalesRepository {
  final SalesDriftDao _salesDao;
  final ProductDriftDao _productDao;
  final CustomerDebtDriftDao _debtDao;
  final DailyPurchaseRequestDriftDao _purchaseDao;
  final AuditLogDriftDao _auditDao;
  final InventoryTransactionDriftDao _inventoryDao;
  final AppDatabase _db;

  SalesRepository(
    this._salesDao,
    this._productDao,
    this._debtDao,
    this._purchaseDao,
    this._auditDao,
    this._inventoryDao,
    this._db,
  );

  /// 🛒 Save Sale (Complete POS Logic with Atomic Transaction)
  Future<String> saveSale(Sale sale, {String? userId, String? userName}) async {
    try {
      // 1. Validation
      if (sale.items.isEmpty) throw ValidationException('لا يمكن حفظ بيع فارغ');

      // 2. Data Preparation
      final cleanCustomerName = sale.customerName != null
          ? InputSanitizer.sanitizeFullName(sale.customerName!)
          : null;
      final cleanCustomerPhone = sale.customerPhone != null
          ? InputSanitizer.sanitizePhoneNumber(sale.customerPhone!)
          : null;

      // 3. Stock Check & Product Retrieval
      final productIds = sale.items.map((i) => i.productId).toList();
      final products = <String, ProductEntry>{};

      for (final id in productIds) {
        final p = await _productDao.findById(id);
        if (p == null) throw NotFoundException('المنتج غير موجود: $id');
        // Check soft delete
        if (p.isDeleted) throw DomainException('المنتج محذوف: $id');
        products[id] = p;
      }

      // 4. Detailed Stock Validation
      for (final item in sale.items) {
        final product = products[item.productId]!;
        developer.log(
            '🔍 Looking for unit: "${item.unit.name}" for product: ${item.productId}',
            name: 'SalesRepository');
        final unitEntry =
            await _productDao.getUnit(item.productId, item.unit.name);
        if (unitEntry == null) {
          final allUnits = await _productDao.getProductUnits(item.productId);
          developer.log(
              '❌ Unit not found. Available units: ${allUnits.map((u) => u.unit).toList()}',
              name: 'SalesRepository');
          throw ValidationException('وحدة ${item.unit.name} غير متوفرة');
        }

        final baseQuantity = item.quantity * unitEntry.conversionToBase;
        if (product.currentStock < baseQuantity) {
          throw InsufficientStockException(
            productId: item.productId,
            productName: item.productName,
            available: product.currentStock / unitEntry.conversionToBase,
            requested: item.quantity,
          );
        }
      }

      // 🔥 5. ATOMIC TRANSACTION - All or Nothing
      await _db.transaction(() async {
        // A. Generate Invoice Number
        final invoiceNumber = await _salesDao.generateInvoiceNumber();

        // B. Insert Sale with audit trail
        final saleCompanion = SaleMapper.toCompanion(sale).copyWith(
          customerName: Value(cleanCustomerName),
          customerPhone: Value(cleanCustomerPhone),
          invoiceNumber: Value(invoiceNumber),
          createdBy: Value(userId),
        );
        await _salesDao.into(_salesDao.sales).insert(saleCompanion);

        // C. Insert Items
        for (final item in sale.items) {
          final itemCompanion = SaleMapper.toItemCompanion(sale.id, item);
          await _salesDao.into(_salesDao.saleItems).insert(itemCompanion);
        }

        // D. 🔥 Record Inventory Transactions (OUT) + Update Stock
        for (final item in sale.items) {
          final unitEntry =
              await _productDao.getUnit(item.productId, item.unit.name);
          final baseQuantity = item.quantity * unitEntry!.conversionToBase;
          final product = products[item.productId]!;
          final newStock = product.currentStock - baseQuantity;

          // 1. Record inventory transaction
          await _inventoryDao.recordTransaction(
            productId: item.productId,
            type: 'OUT',
            quantity: -baseQuantity, // Negative for OUT
            referenceId: sale.id,
            referenceType: 'sale',
            notes: 'بيع: ${item.productName} (فاتورة: $invoiceNumber)',
            createdBy: userId,
          );

          // 2. Update product stock with audit trail
          await _productDao.updateProductFields(
            item.productId,
            ProductsCompanion(
              currentStock: Value(newStock),
              updatedBy: Value(userId),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }

        // E. Handle Debt (inside transaction for consistency)
        if (sale.hasDebt && cleanCustomerName != null) {
          await _debtDao.upsertDebt(
            customerName: cleanCustomerName,
            customerPhone: cleanCustomerPhone,
            debtAmount: sale.remainingAmount,
          );
        }

        // إذا فشلت أي خطوة، سيحدث Rollback تلقائياً
      });

      // 6. Auto-Reorder Check (outside transaction - not critical)
      await _checkAutoReorder(sale, products);

      // 7. Audit Logging (outside transaction)
      if (userId != null) {
        await _auditDao.logSaleCreate(
            userId, userName ?? 'User', sale.id, sale.total,
            customerName: cleanCustomerName, itemsCount: sale.items.length);
      }

      developer.log('✅ Sale saved successfully: ${sale.id}',
          name: 'SalesRepository');
      return sale.id;
    } catch (e) {
      developer.log('❌ Error saving sale: $e',
          name: 'SalesRepository', error: e);
      rethrow;
    }
  }

  /// 🔄 Get All Sales (Domain Models)
  Future<List<Sale>> getAllSales() async {
    final entries = await _salesDao.findAll();
    final List<Sale> sales = [];

    for (final entry in entries) {
      final items = await _salesDao.getSaleItems(entry.id);
      sales.add(SaleMapper.fromEntry(SaleWithItems(sale: entry, items: items)));
    }

    return sales;
  }

  /// 🔍 Get Sale by ID or Invoice Number
  Future<Sale?> getSaleById(String id) async {
    var entry = await _salesDao.findById(id);
    entry ??= await _salesDao.findByInvoiceNumber(id);
    if (entry == null) return null;

    final items = await _salesDao.getSaleItems(entry.id);
    return SaleMapper.fromEntry(SaleWithItems(sale: entry, items: items));
  }

  /// 💰 Get Today's Revenue
  Future<double> getTodayRevenue() => _salesDao.getTodayRevenue();

  /// 📊 Get Today's Sales Count
  Future<int> getTodaySalesCount() => _salesDao.getTodaySalesCount();

  /// 🆔 Generate next Sale ID
  Future<String> generateSaleId() => _salesDao.generateSaleId();

  /// 🛒 Public Auto Reorder Check
  Future<void> checkAutoReorder(Sale sale) async {
    final productIds = sale.items.map((i) => i.productId).toList();
    final products = <String, ProductEntry>{};
    for (final id in productIds) {
      final p = await _productDao.findById(id);
      if (p != null) products[id] = p;
    }
    await _checkAutoReorder(sale, products);
  }

  /// 📉 Auto Reorder Logic
  Future<void> _checkAutoReorder(
      Sale sale, Map<String, ProductEntry> products) async {
    for (final item in sale.items) {
      final product = products[item.productId]!;
      final unitEntry =
          await _productDao.getUnit(item.productId, item.unit.name);
      final remainingStock =
          product.currentStock - (item.quantity * unitEntry!.conversionToBase);

      if (remainingStock < 0.001) {
        final exists =
            await _purchaseDao.isProductInTodayRequest(item.productId);
        if (!exists) {
          await _purchaseDao
              .insertRequest(DailyPurchaseRequestsCompanion.insert(
            id: const Uuid().v4(),
            productId: item.productId,
            productName: item.productName,
            requestedQuantity: 5,
            unit: Value(item.unit.name),
            autoAdded: const Value(true),
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }
    }
  }
}

// 🔌 Providers
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    ref.watch(salesDriftDaoProvider),
    ref.watch(productDriftDaoProvider),
    ref.watch(customerDebtDriftDaoProvider),
    ref.watch(dailyPurchaseRequestDriftDaoProvider),
    ref.watch(auditLogDriftDaoProvider),
    ref.watch(inventoryTransactionDriftDaoProvider),
    ref.watch(appDatabaseProvider),
  );
});

final customerDebtDriftDaoProvider = Provider<CustomerDebtDriftDao>(
    (ref) => CustomerDebtDriftDao(ref.watch(appDatabaseProvider)));

final dailyPurchaseRequestDriftDaoProvider =
    Provider<DailyPurchaseRequestDriftDao>(
        (ref) => DailyPurchaseRequestDriftDao(ref.watch(appDatabaseProvider)));

final auditLogDriftDaoProvider = Provider<AuditLogDriftDao>(
    (ref) => AuditLogDriftDao(ref.watch(appDatabaseProvider)));
