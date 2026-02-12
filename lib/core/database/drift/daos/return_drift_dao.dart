import 'package:drift/drift.dart';
import '../app_database.dart';

part 'return_drift_dao.g.dart';

@DriftAccessor(tables: [Returns, ReturnItems, Products, ProductUnits, Sales])
class ReturnDriftDao extends DatabaseAccessor<AppDatabase>
    with _$ReturnDriftDaoMixin {
  ReturnDriftDao(super.db);

  /// 🔄 Create Return (Complex logic with stock updates)
  Future<String> createReturn(ReturnsCompanion returnCompanion,
      List<ReturnItemsCompanion> itemCompanions) async {
    return transaction(() async {
      // 1. Insert Return entry
      await into(returns).insert(returnCompanion);

      // 2. Process items and update stock
      for (final item in itemCompanions) {
        await into(returnItems).insert(item);

        // Update Stock (Refund stock back)
        final productId = item.productId.value;
        final product = await (select(products)
              ..where((p) => p.id.equals(productId)))
            .getSingle();

        // Find conversion rate
        final unitResult = await (select(productUnits)
              ..where((u) =>
                  u.productId.equals(productId) &
                  u.unit.equals(item.unit.value)))
            .getSingleOrNull();

        final conversionRate = unitResult?.conversionToBase ?? 1.0;
        final returnedQuantityBase = item.quantity.value * conversionRate;

        // Perform atomic update
        await (update(products)..where((p) => p.id.equals(productId)))
            .write(ProductsCompanion(
          currentStock: Value(product.currentStock + returnedQuantityBase),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // 3. Update sale status
      final saleId = returnCompanion.saleId.value;
      await _updateSaleStatus(saleId);

      return returnCompanion.id.value;
    });
  }

  /// 📝 Update return status
  Future<void> updateStatus(String returnId, String status) async {
    await (update(returns)..where((r) => r.id.equals(returnId)))
        .write(ReturnsCompanion(status: Value(status)));
  }

  Future<void> _updateSaleStatus(String saleId) async {
    // Basic logic: if any item is returned, status is 'returned'
    await (update(sales)..where((s) => s.id.equals(saleId)))
        .write(const SalesCompanion(status: Value('returned')));
  }

  /// 🔍 Find all returns with their items
  Future<List<ReturnWithItems>> findAll() async {
    final entries = await select(returns).get();
    final List<ReturnWithItems> results = [];

    for (final entry in entries) {
      final items = await (select(returnItems)
            ..where((i) => i.returnId.equals(entry.id)))
          .get();
      results.add(ReturnWithItems(returnEntry: entry, items: items));
    }

    return results;
  }

  /// 🔍 Get single return by ID
  Future<ReturnWithItems?> findById(String id) async {
    final entry = await (select(returns)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return null;

    final items =
        await (select(returnItems)..where((i) => i.returnId.equals(id))).get();
    return ReturnWithItems(returnEntry: entry, items: items);
  }
}

class ReturnWithItems {
  final ReturnEntry returnEntry;
  final List<ReturnItemEntry> items;

  ReturnWithItems({required this.returnEntry, required this.items});
}
