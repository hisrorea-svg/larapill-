import 'package:drift/drift.dart';
import '../app_database.dart';

part 'purchase_order_drift_dao.g.dart';

@DriftAccessor(tables: [
  PurchaseOrders,
  PurchaseItems,
  StockMovements,
  Products,
])
class PurchaseOrderDriftDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseOrderDriftDaoMixin {
  PurchaseOrderDriftDao(super.db);

  /// 🔍 Get all purchase orders
  Future<List<PurchaseOrderEntry>> getAllOrders() {
    return (select(purchaseOrders)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// ➕ Create purchase order with items
  Future<void> createOrder(
    PurchaseOrdersCompanion order,
    List<PurchaseItemsCompanion> items,
  ) async {
    return transaction(() async {
      await into(purchaseOrders).insert(order);
      for (final item in items) {
        await into(purchaseItems).insert(item);
      }
    });
  }

  /// ✅ Receive purchase order (Update stock and create movements)
  Future<void> receiveOrder(
    String orderId,
    List<StockMovementsCompanion> movements,
  ) async {
    return transaction(() async {
      // 1. Update order status
      await (update(purchaseOrders)..where((o) => o.id.equals(orderId)))
          .write(PurchaseOrdersCompanion(
        status: const Value('received'),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. Process stock movements and update product stock
      for (final movement in movements) {
        await into(stockMovements).insert(movement);

        // Atomic stock update
        final productId = movement.productId.value;
        final quantityChange = movement.quantity.value;

        // Note: Using custom statement for atomic update if needed,
        // but simple update is fine within transaction.
        final product = await (select(products)
              ..where((p) => p.id.equals(productId)))
            .getSingle();

        await (update(products)..where((p) => p.id.equals(productId))).write(
          ProductsCompanion(
            currentStock: Value(product.currentStock + quantityChange),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}
