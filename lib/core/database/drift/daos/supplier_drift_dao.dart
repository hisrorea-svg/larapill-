import 'package:drift/drift.dart';
import '../app_database.dart';

part 'supplier_drift_dao.g.dart';

@DriftAccessor(tables: [
  Suppliers,
  SupplierPayments,
  SupplierReturns,
  SupplierLedger,
  Products,
  StockMovements,
])
class SupplierDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierDriftDaoMixin {
  SupplierDriftDao(super.db);

  /// 🔍 Get all active suppliers
  Future<List<SupplierEntry>> getActiveSuppliers() {
    return (select(suppliers)..where((s) => s.isActive.equals(true))).get();
  }

  /// 🚀 OPTIMIZED: Get all active suppliers with their balances (Single Query)
  Future<List<SupplierWithBalance>> getActiveSuppliersWithBalances() async {
    final results = await customSelect(
      '''
      SELECT s.*, 
             COALESCE(
               (SELECT balance_after FROM supplier_ledger 
                WHERE supplier_id = s.id 
                ORDER BY created_at DESC LIMIT 1), 
               0.0
             ) as current_balance
      FROM suppliers s
      WHERE s.is_active = 1
      ORDER BY s.name ASC
      ''',
      readsFrom: {suppliers, supplierLedger},
    ).get();

    return results
        .map((row) => SupplierWithBalance(
              supplier: SupplierEntry(
                id: row.read<String>('id'),
                name: row.read<String>('name'),
                phone: row.readNullable<String>('phone'),
                address: row.readNullable<String>('address'),
                contactPerson: row.readNullable<String>('contact_person'),
                paymentType: row.read<String>('payment_type'),
                isActive: row.read<bool>('is_active'),
                createdAt: row.read<DateTime>('created_at'),
                updatedAt: row.read<DateTime>('updated_at'),
              ),
              balance: row.read<double>('current_balance'),
            ))
        .toList();
  }

  /// 🔍 Find supplier by ID
  Future<SupplierEntry?> findById(String id) {
    return (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// ➕ Add or update supplier
  Future<void> upsertSupplier(SuppliersCompanion entry) {
    return into(suppliers).insertOnConflictUpdate(entry);
  }

  /// 💰 Get supplier balance from ledger
  Future<double> getBalance(String supplierId) async {
    final lastEntry = await (select(supplierLedger)
          ..where((l) => l.supplierId.equals(supplierId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    return lastEntry?.balanceAfter ?? 0.0;
  }

  /// 📝 Add ledger entry
  Future<void> addLedgerEntry(SupplierLedgerCompanion entry) {
    return into(supplierLedger).insert(entry);
  }

  /// 🔍 Get ledger entries for a supplier
  Future<List<SupplierLedgerData>> findLedgerBySupplier(String supplierId) {
    return (select(supplierLedger)
          ..where((l) => l.supplierId.equals(supplierId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// 💳 Create payment
  Future<void> createPayment(SupplierPaymentsCompanion payment,
      SupplierLedgerCompanion ledgerEntry) async {
    return transaction(() async {
      await into(supplierPayments).insert(payment);
      await addLedgerEntry(ledgerEntry);
    });
  }

  // ========== Supplier Returns Operations ==========

  /// 📦 Get all returns ordered by createdAt desc
  Future<List<SupplierReturnEntry>> getAllReturns() {
    return (select(supplierReturns)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 📦 Get returns for a specific supplier
  Future<List<SupplierReturnEntry>> getReturnsBySupplier(String supplierId) {
    return (select(supplierReturns)
          ..where((t) => t.supplierId.equals(supplierId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 📦 Get prepared returns only
  Future<List<SupplierReturnEntry>> getPreparedReturns() {
    return (select(supplierReturns)
          ..where((t) => t.status.equals('prepared'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// ➕ Create a new return
  Future<String> createReturn({
    required String id,
    required String supplierId,
    String? invoiceId,
    required String productId,
    required double quantity,
    required double amount,
    String? notes,
  }) async {
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

  /// 📦 Get a single return by ID
  Future<SupplierReturnEntry> getReturnById(String returnId) {
    return (select(supplierReturns)..where((t) => t.id.equals(returnId)))
        .getSingle();
  }

  /// ✅ Update return status to delivered
  Future<void> updateReturnStatusDelivered(String returnId) {
    return (update(supplierReturns)..where((t) => t.id.equals(returnId))).write(
      SupplierReturnsCompanion(
        status: const Value('delivered'),
        deliveredDate: Value(DateTime.now()),
      ),
    );
  }

  /// 🗑️ Delete a return (only if not delivered)
  Future<void> deleteReturn(String returnId) async {
    final returnEntry = await getReturnById(returnId);

    if (returnEntry.status == 'delivered') {
      throw Exception('لا يمكن حذف مرتجع تم تسليمه');
    }

    await (delete(supplierReturns)..where((t) => t.id.equals(returnId))).go();
  }

  /// 📦 Update product stock
  Future<void> updateProductStock(String productId, double newStock) {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        currentStock: Value(newStock > 0 ? newStock : 0),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 📦 Get product by ID
  Future<ProductEntry?> getProductById(String productId) {
    return (select(products)..where((p) => p.id.equals(productId)))
        .getSingleOrNull();
  }

  /// 📝 Add stock movement
  Future<void> addStockMovement(StockMovementsCompanion entry) {
    return into(stockMovements).insert(entry);
  }
}

/// Supplier with balance from JOIN query (for optimized display)
class SupplierWithBalance {
  final SupplierEntry supplier;
  final double balance;

  const SupplierWithBalance({
    required this.supplier,
    required this.balance,
  });
}
