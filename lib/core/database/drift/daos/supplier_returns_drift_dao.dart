/// Supplier Returns Drift DAO - Type-safe database access for supplier returns
library supplier_returns_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/database_provider.dart';
import 'supplier_drift_dao.dart';

part 'supplier_returns_drift_dao.g.dart';

/// DAO for SupplierReturns table with type-safe queries
@DriftAccessor(tables: [
  SupplierReturns,
  Products,
  StockMovements,
  SupplierLedger,
])
class SupplierReturnsDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierReturnsDriftDaoMixin {
  late final SupplierDriftDao _supplierDao;

  SupplierReturnsDriftDao(super.db, {SupplierDriftDao? supplierDao}) {
    _supplierDao = supplierDao ?? SupplierDriftDao(db);
  }

  // 📖 READ OPERATIONS

  /// Get all returns ordered by createdAt desc
  Future<List<SupplierReturnEntry>> getAllReturns() {
    return (select(supplierReturns)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get returns for a specific supplier
  Future<List<SupplierReturnEntry>> getReturnsBySupplier(String supplierId) {
    return (select(supplierReturns)
          ..where((t) => t.supplierId.equals(supplierId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get prepared returns only
  Future<List<SupplierReturnEntry>> getPreparedReturns() {
    return (select(supplierReturns)
          ..where((t) => t.status.equals('prepared'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get a single return by ID
  Future<SupplierReturnEntry?> findById(String returnId) {
    return (select(supplierReturns)..where((t) => t.id.equals(returnId)))
        .getSingleOrNull();
  }

  // 📝 WRITE OPERATIONS

  /// Create a new return with 'prepared' status
  Future<String> createReturn({
    required String supplierId,
    String? invoiceId,
    required String productId,
    required double quantity,
    required double amount,
    String? notes,
  }) async {
    final id = const Uuid().v4();

    await into(supplierReturns).insert(
      SupplierReturnsCompanion.insert(
        id: id,
        supplierId: supplierId,
        invoiceId: invoiceId != null ? Value(invoiceId) : const Value.absent(),
        productId: productId,
        quantity: quantity,
        amount: amount,
        status: const Value('prepared'),
        notes: notes != null ? Value(notes) : const Value.absent(),
        createdAt: DateTime.now(),
      ),
    );

    return id;
  }

  /// Deliver a return (change status, update stock, add ledger entry)
  Future<void> deliverReturn(String returnId) async {
    await transaction(() async {
      // 1. Get the return
      final returnEntry = await (select(supplierReturns)
            ..where((t) => t.id.equals(returnId)))
          .getSingle();

      // 2. Update status to delivered
      await (update(supplierReturns)..where((t) => t.id.equals(returnId)))
          .write(
        SupplierReturnsCompanion(
          status: const Value('delivered'),
          deliveredDate: Value(DateTime.now()),
        ),
      );

      // 3. Decrease product stock
      final product = await (select(products)
            ..where((p) => p.id.equals(returnEntry.productId)))
          .getSingleOrNull();

      if (product != null) {
        final newStock = product.currentStock - returnEntry.quantity;
        await (update(products)
              ..where((p) => p.id.equals(returnEntry.productId)))
            .write(ProductsCompanion(
          currentStock: Value(newStock > 0 ? newStock : 0),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // 4. Add stock movement
      await into(stockMovements).insert(
        StockMovementsCompanion.insert(
          id: const Uuid().v4(),
          productId: returnEntry.productId,
          referenceType: 'supplier_return',
          referenceId: returnId,
          quantity: -returnEntry.quantity,
          notes: const Value('مرتجع للمورد'),
          createdAt: DateTime.now(),
        ),
      );

      // 5. Update supplier balance (decrease debt)
      final currentBalance =
          await _supplierDao.getBalance(returnEntry.supplierId);
      final newBalance = currentBalance - returnEntry.amount;

      await into(supplierLedger).insert(
        SupplierLedgerCompanion.insert(
          id: const Uuid().v4(),
          supplierId: returnEntry.supplierId,
          referenceId: returnId,
          referenceType: 'return',
          amount: -returnEntry.amount,
          balanceAfter: newBalance,
          description: 'مرتجع للمورد',
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  /// Delete a return (only if not delivered)
  Future<void> deleteReturn(String returnId) async {
    final returnEntry = await findById(returnId);

    if (returnEntry == null) {
      throw Exception('المرتجع غير موجود');
    }

    if (returnEntry.status == 'delivered') {
      throw Exception('لا يمكن حذف مرتجع تم تسليمه');
    }

    await (delete(supplierReturns)..where((t) => t.id.equals(returnId))).go();
  }

  // 📊 STATISTICS

  /// Get comprehensive returns statistics for dashboard
  ///
  /// Returns a map containing:
  /// - 'preparedCount': Number of prepared returns
  /// - 'deliveredCount': Number of delivered returns
  /// - 'preparedAmount': Total amount of prepared returns (pending delivery)
  /// - 'deliveredAmount': Total amount of delivered returns
  Future<Map<String, dynamic>> getReturnsStats() async {
    // Get prepared returns count and amount
    final preparedQuery = selectOnly(supplierReturns)
      ..addColumns([
        supplierReturns.id.count(),
        supplierReturns.amount.sum(),
      ])
      ..where(supplierReturns.status.equals('prepared'));

    final preparedResult = await preparedQuery
        .map((row) => (
              row.read(supplierReturns.id.count()) ?? 0,
              row.read(supplierReturns.amount.sum()) ?? 0.0,
            ))
        .getSingle();

    // Get delivered returns count and amount
    final deliveredQuery = selectOnly(supplierReturns)
      ..addColumns([
        supplierReturns.id.count(),
        supplierReturns.amount.sum(),
      ])
      ..where(supplierReturns.status.equals('delivered'));

    final deliveredResult = await deliveredQuery
        .map((row) => (
              row.read(supplierReturns.id.count()) ?? 0,
              row.read(supplierReturns.amount.sum()) ?? 0.0,
            ))
        .getSingle();

    return {
      'preparedCount': preparedResult.$1,
      'deliveredCount': deliveredResult.$1,
      'preparedAmount': preparedResult.$2,
      'deliveredAmount': deliveredResult.$2,
      'totalCount': preparedResult.$1 + deliveredResult.$1,
      'totalAmount': preparedResult.$2 + deliveredResult.$2,
    };
  }

  /// Count returns by status (legacy method)
  Future<Map<String, int>> countByStatus() async {
    final stats = await getReturnsStats();
    return {
      'prepared': stats['preparedCount'] as int,
      'delivered': stats['deliveredCount'] as int,
    };
  }
}

/// Provider for SupplierReturnsDriftDao
final supplierReturnsDriftDaoProvider =
    Provider<SupplierReturnsDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supplierDao = SupplierDriftDao(db);
  return SupplierReturnsDriftDao(db, supplierDao: supplierDao);
});
