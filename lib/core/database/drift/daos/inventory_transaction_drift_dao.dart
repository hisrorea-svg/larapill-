part of '../app_database.dart';

/// إدارة قاعدة بيانات حركات المخزون
/// Inventory Transactions DAO
@DriftAccessor(tables: [InventoryTransactions])
class InventoryTransactionDriftDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryTransactionDriftDaoMixin {
  InventoryTransactionDriftDao(super.db);

  /// تسجيل حركة مخزون جديدة
  /// Record a new inventory transaction
  Future<void> recordTransaction({
    required String productId,
    required String type, // IN, OUT, ADJUSTMENT
    required double quantity,
    String? referenceId,
    String? referenceType,
    String? notes,
    String? createdBy,
  }) async {
    final transaction = InventoryTransactionsCompanion.insert(
      id: const Uuid().v4(),
      productId: productId,
      type: type,
      quantity: quantity,
      referenceId: Value(referenceId),
      referenceType: Value(referenceType),
      notes: Value(notes),
      createdBy: Value(createdBy),
      createdAt: DateTime.now(),
    );

    await into(inventoryTransactions).insert(transaction);
  }

  /// جلب حركات المخزون لمنتج معين
  /// Get inventory transactions for a product
  Future<List<InventoryTransactionEntry>> getTransactionsByProduct(
      String productId) {
    return (select(inventoryTransactions)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// حساب المخزون الحالي من مجموع الحركات
  /// Calculate current stock from sum of transactions
  Future<double> calculateCurrentStock(String productId) async {
    final result = await (selectOnly(inventoryTransactions)
          ..addColumns([inventoryTransactions.quantity.sum()])
          ..where(inventoryTransactions.productId.equals(productId)))
        .getSingle();

    return result.read(inventoryTransactions.quantity.sum()) ?? 0.0;
  }

  /// جلب حركات المخزون حسب نوع المرجع (مثل: sale, purchase)
  /// Get transactions by reference type
  Future<List<InventoryTransactionEntry>> getTransactionsByReference({
    required String referenceId,
    String? referenceType,
  }) {
    return (select(inventoryTransactions)
          ..where((t) =>
              t.referenceId.equals(referenceId) &
              (referenceType != null
                  ? t.referenceType.equals(referenceType)
                  : const Constant(true)))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// جلب حركات المخزون خلال فترة زمنية
  /// Get transactions within a date range
  Future<List<InventoryTransactionEntry>> getTransactionsInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? productId,
  }) {
    return (select(inventoryTransactions)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(startDate) &
              t.createdAt.isSmallerOrEqualValue(endDate) &
              (productId != null
                  ? t.productId.equals(productId)
                  : const Constant(true)))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// إحصائيات حركات المخزون حسب النوع
  /// Transaction statistics by type
  Future<Map<String, double>> getTransactionStatsByType(
      String productId) async {
    final transactions = await getTransactionsByProduct(productId);

    final stats = <String, double>{};
    for (final transaction in transactions) {
      stats[transaction.type] =
          (stats[transaction.type] ?? 0.0) + transaction.quantity;
    }

    return stats;
  }
}
