import '../../data/datasources/local/supplier_returns_dao.dart';
import '../../data/datasources/local/stock_movements_dao.dart';
import '../../data/datasources/local/supplier_ledger_dao.dart';

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
  final SupplierReturnsDao _returnsDao;
  final SupplierLedgerDao _ledgerDao;

  ProcessReturnUseCase({
    SupplierReturnsDao? returnsDao,
    StockMovementsDao? stockMovementsDao,
    SupplierLedgerDao? ledgerDao,
  })  : _returnsDao = returnsDao ?? SupplierReturnsDao(),
        _ledgerDao = ledgerDao ?? SupplierLedgerDao();

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
    return await _returnsDao.createReturn(
      supplierId: supplierId,
      invoiceId: invoiceId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      amount: amount,
      notes: notes,
    );
  }

  /// تسليم المرتجع للمورد
  ///
  /// هذا الإجراء نهائي ويؤدي إلى:
  /// - خصم الكمية من المخزون
  /// - تقليل دين المورد
  Future<ProcessReturnResult> deliverReturn(String returnId) async {
    try {
      // جلب بيانات المرتجع قبل التسليم
      final returns = await _returnsDao.getPreparedReturns();
      final returnData = returns.firstWhere(
        (r) => r.id == returnId,
        orElse: () => throw Exception('المرتجع غير موجود أو تم تسليمه'),
      );

      // تسليم المرتجع
      await _returnsDao.deliverReturn(returnId);

      // جلب الرصيد الجديد
      final newBalance =
          await _ledgerDao.getSupplierBalance(returnData.supplierId);

      return ProcessReturnResult.success(
        returnId: returnId,
        amount: returnData.amount,
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
    // TODO: إضافة دالة cancelReturn في DAO
    throw UnimplementedError('إلغاء المرتجع غير منفذ بعد');
  }
}
