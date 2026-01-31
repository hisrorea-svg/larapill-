import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../../database/database_helper.dart';
import '../../models/stock_movement.dart';

/// DAO لحركات المخزون
class StockMovementsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// إضافة حركة مخزون جديدة
  Future<void> insertMovement(StockMovement movement) async {
    final db = await _dbHelper.database;
    await db.insert(
      'stock_movements',
      movement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// إضافة حركة شراء (زيادة المخزون)
  Future<void> addPurchaseMovement({
    required String productId,
    required String purchaseOrderId,
    required double quantity,
    required double costPerUnit,
    String? notes,
  }) async {
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: productId,
      referenceId: purchaseOrderId,
      referenceType: 'purchase',
      quantity: quantity, // موجب = إضافة
      costPerUnit: costPerUnit,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await insertMovement(movement);

    // تحديث المخزون الحالي
    await _updateProductStock(productId, quantity);
  }

  /// إضافة حركة مرتجع مورد (خصم من المخزون)
  Future<void> addSupplierReturnMovement({
    required String productId,
    required String returnId,
    required double quantity,
    String? notes,
  }) async {
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: productId,
      referenceId: returnId,
      referenceType: 'supplier_return',
      quantity: -quantity, // سالب = خصم
      notes: notes,
      createdAt: DateTime.now(),
    );

    await insertMovement(movement);
    await _updateProductStock(productId, -quantity);
  }

  /// إضافة حركة بيع (خصم من المخزون)
  Future<void> addSaleMovement({
    required String productId,
    required String saleId,
    required double quantity,
    String? notes,
  }) async {
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: productId,
      referenceId: saleId,
      referenceType: 'sale',
      quantity: -quantity, // سالب = خصم
      notes: notes,
      createdAt: DateTime.now(),
    );

    await insertMovement(movement);
    await _updateProductStock(productId, -quantity);
  }

  /// إضافة حركة تعديل يدوي
  Future<void> addAdjustmentMovement({
    required String productId,
    required double quantity,
    String? notes,
  }) async {
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: productId,
      referenceId: 'adjustment_${DateTime.now().millisecondsSinceEpoch}',
      referenceType: 'adjustment',
      quantity: quantity,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await insertMovement(movement);
    await _updateProductStock(productId, quantity);
  }

  /// تحديث المخزون الحالي للمنتج
  Future<void> _updateProductStock(
      String productId, double quantityChange) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('''
      UPDATE products 
      SET current_stock = current_stock + ?,
          updated_at = ?
      WHERE id = ?
    ''', [quantityChange, DateTime.now().millisecondsSinceEpoch, productId]);
  }

  /// جلب حركات منتج معين
  Future<List<StockMovement>> getProductMovements(String productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => StockMovement.fromMap(e)).toList();
  }

  /// جلب حركات مخزون بمرجع معين
  Future<List<StockMovement>> getMovementsByReference(
    String referenceId,
    String referenceType,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_movements',
      where: 'reference_id = ? AND reference_type = ?',
      whereArgs: [referenceId, referenceType],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => StockMovement.fromMap(e)).toList();
  }

  /// حساب متوسط تكلفة المنتج من آخر الحركات
  Future<double?> getAverageProductCost(String productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT AVG(cost_per_unit) as avg_cost 
      FROM stock_movements 
      WHERE product_id = ? 
        AND reference_type = 'purchase' 
        AND cost_per_unit IS NOT NULL
    ''', [productId]);

    if (result.isEmpty || result.first['avg_cost'] == null) return null;
    return (result.first['avg_cost'] as num).toDouble();
  }

  /// جلب آخر تكلفة شراء للمنتج
  Future<double?> getLastPurchaseCost(String productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT cost_per_unit 
      FROM stock_movements 
      WHERE product_id = ? 
        AND reference_type = 'purchase' 
        AND cost_per_unit IS NOT NULL
      ORDER BY created_at DESC
      LIMIT 1
    ''', [productId]);

    if (result.isEmpty || result.first['cost_per_unit'] == null) return null;
    return (result.first['cost_per_unit'] as num).toDouble();
  }
}
