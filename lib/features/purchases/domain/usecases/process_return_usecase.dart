// lib/features/purchases/domain/usecases/process_return_usecase.dart
// Direct Drift implementation - No wrappers!

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../../../core/database/drift/daos/supplier_drift_dao.dart';

/// نتيجة معالجة المرتجع
class ProcessReturnResult {
  final String returnId;
  final bool success;
  final String? error;
  final double amount;
  final double newBalance;

  const ProcessReturnResult({
    required this.returnId,
    required this.success,
    this.error,
    required this.amount,
    required this.newBalance,
  });

  factory ProcessReturnResult.success({
    required String returnId,
    required double amount,
    required double newBalance,
  }) {
    return ProcessReturnResult(
      returnId: returnId,
      success: true,
      amount: amount,
      newBalance: newBalance,
    );
  }

  factory ProcessReturnResult.failure({
    required String error,
    String returnId = '',
  }) {
    return ProcessReturnResult(
      returnId: returnId,
      success: false,
      error: error,
      amount: 0,
      newBalance: 0,
    );
  }
}

/// Use Case: معالجة مرتجع مورد
///
/// المسؤوليات:
/// 1. إنشاء سجل المرتجع (prepared)
/// 2. عند التسليم: خصم من المخزون + تقليل الدين
class ProcessReturnUseCase {
  final AppDatabase _db;
  final SupplierDriftDao _supplierDao;

  ProcessReturnUseCase({
    AppDatabase? database,
  })  : _db = database ?? DatabaseProviderHelper.instance,
        _supplierDao =
            SupplierDriftDao(database ?? DatabaseProviderHelper.instance);

  /// إنشاء مرتجع جديد (حالة prepared)
  Future<String> createReturn({
    required String supplierId,
    String? invoiceId,
    required String productId,
    required String productName,
    required double quantity,
    required double amount,
    String? notes,
  }) async {
    final id = const Uuid().v4();

    await _db.into(_db.supplierReturns).insert(
          SupplierReturnsCompanion.insert(
            id: id,
            supplierId: supplierId,
            invoiceId:
                invoiceId != null ? Value(invoiceId) : const Value.absent(),
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

  /// تسليم المرتجع للمورد
  ///
  /// هذا الإجراء نهائي ويؤدي إلى:
  /// - خصم الكمية من المخزون
  /// - تقليل دين المورد
  Future<ProcessReturnResult> deliverReturn(String returnId) async {
    try {
      // Get return data
      final returnEntry = await (_db.select(_db.supplierReturns)
            ..where((t) => t.id.equals(returnId)))
          .getSingleOrNull();

      if (returnEntry == null) {
        throw Exception('المرتجع غير موجود');
      }

      if (returnEntry.status == 'delivered') {
        throw Exception('المرتجع تم تسليمه مسبقاً');
      }

      await _db.transaction(() async {
        // 1. Update return status
        await (_db.update(_db.supplierReturns)
              ..where((t) => t.id.equals(returnId)))
            .write(SupplierReturnsCompanion(
          status: const Value('delivered'),
          deliveredDate: Value(DateTime.now()),
        ));

        // 2. Decrease product stock
        final product = await (_db.select(_db.products)
              ..where((p) => p.id.equals(returnEntry.productId)))
            .getSingleOrNull();

        if (product != null) {
          final newStock = product.currentStock - returnEntry.quantity;
          await (_db.update(_db.products)
                ..where((p) => p.id.equals(returnEntry.productId)))
              .write(ProductsCompanion(
            currentStock: Value(newStock > 0 ? newStock : 0),
            updatedAt: Value(DateTime.now()),
          ));
        }

        // 3. Add stock movement
        await _db.into(_db.stockMovements).insert(
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

        // 4. Update supplier ledger
        final currentBalance =
            await _supplierDao.getBalance(returnEntry.supplierId);
        final newBalance = currentBalance - returnEntry.amount;

        await _supplierDao.addLedgerEntry(
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

      final newBalance = await _supplierDao.getBalance(returnEntry.supplierId);

      return ProcessReturnResult.success(
        returnId: returnId,
        amount: returnEntry.amount,
        newBalance: newBalance,
      );
    } catch (e) {
      return ProcessReturnResult.failure(error: e.toString());
    }
  }

  /// تسليم مجموعة مرتجعات دفعة واحدة
  Future<List<ProcessReturnResult>> deliverMultipleReturns(
    List<String> returnIds,
  ) async {
    final results = <ProcessReturnResult>[];

    for (final id in returnIds) {
      final result = await deliverReturn(id);
      results.add(result);
    }

    return results;
  }

  /// إلغاء مرتجع (فقط إذا لم يتم تسليمه)
  Future<void> cancelReturn(String returnId) async {
    final returnEntry = await (_db.select(_db.supplierReturns)
          ..where((t) => t.id.equals(returnId)))
        .getSingleOrNull();

    if (returnEntry == null) {
      throw Exception('المرتجع غير موجود');
    }

    if (returnEntry.status == 'delivered') {
      throw Exception('لا يمكن إلغاء مرتجع تم تسليمه');
    }

    await (_db.delete(_db.supplierReturns)..where((t) => t.id.equals(returnId)))
        .go();
  }
}
