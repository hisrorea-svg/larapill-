import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/daos/product_drift_dao.dart';
import '../../../../core/database/drift/daos/purchase_order_drift_dao.dart';
import '../../../../core/database/drift/daos/supplier_drift_dao.dart';
import '../../../../core/database/drift/daos/supplier_returns_drift_dao.dart';
import '../../../../core/database/drift/daos/supplier_ledger_drift_dao.dart';
import '../../../../core/database/drift/database_provider.dart';

/// إحصائيات لوحة التحكم
class DashboardStats {
  final int lowStockCount;
  final int pendingInvoices;
  final double pendingReturnsAmount;
  final double totalDebt;
  final double cashDebt;
  final double monthlyDebt;
  final double creditDebt;
  final bool hasOverdueDebt;

  const DashboardStats({
    this.lowStockCount = 0,
    this.pendingInvoices = 0,
    this.pendingReturnsAmount = 0,
    this.totalDebt = 0,
    this.cashDebt = 0,
    this.monthlyDebt = 0,
    this.creditDebt = 0,
    this.hasOverdueDebt = false,
  });
}

/// Provider لإحصائيات لوحة التحكم
final purchasesDashboardStatsProvider =
    FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final productDao = ProductDriftDao(db);
  final orderDao = PurchaseOrderDriftDao(db);
  final supplierDao = SupplierDriftDao(db);

  // 1. جلب عدد النواقص (المنتجات ذات المخزون المنخفض)
  final lowStockCount = await productDao.countLowStock();

  // 2. جلب عدد الفواتير المعلقة (المسودات)
  final allOrders = await orderDao.getAllOrders();
  final pendingInvoices = allOrders.where((o) => o.status == 'draft').length;

  // 3. جلب مبلغ المرتجعات الجاهزة للتسليم
  final returnsDao = ref.watch(supplierReturnsDriftDaoProvider);
  final returnsStats = await returnsDao.getReturnsStats();
  final pendingReturnsAmount = returnsStats['preparedAmount'] as double;

  // 4. جلب إجمالي الديون مُصنّفة حسب نوع الدفع
  final debtsByType = await _getDebtsByPaymentType(db, supplierDao);

  // 5. التحقق من وجود ديون متأخرة
  final hasOverdueDebt = await _checkOverdueDebts(db);

  return DashboardStats(
    lowStockCount: lowStockCount,
    pendingInvoices: pendingInvoices,
    pendingReturnsAmount: pendingReturnsAmount,
    totalDebt: debtsByType['total'] ?? 0,
    cashDebt: debtsByType['cash'] ?? 0,
    monthlyDebt: debtsByType['monthly'] ?? 0,
    creditDebt: debtsByType['credit'] ?? 0,
    hasOverdueDebt: hasOverdueDebt,
  );
});

/// جلب الديون مُصنّفة حسب نوع الدفع
Future<Map<String, double>> _getDebtsByPaymentType(
    dynamic db, SupplierDriftDao supplierDao) async {
  // Get all active suppliers
  final suppliers = await supplierDao.getActiveSuppliers();

  double cashDebt = 0;
  double monthlyDebt = 0;
  double creditDebt = 0;
  double total = 0;

  for (final supplier in suppliers) {
    // Get balance for each supplier
    final balance = await supplierDao.getBalance(supplier.id);
    if (balance > 0) {
      total += balance;

      switch (supplier.paymentType) {
        case 'cash':
        case 'weekly':
          cashDebt += balance;
          break;
        case 'monthly':
          monthlyDebt += balance;
          break;
        case 'credit':
          creditDebt += balance;
          break;
        default:
          cashDebt += balance;
      }
    }
  }

  return {
    'total': total,
    'cash': cashDebt,
    'monthly': monthlyDebt,
    'credit': creditDebt,
  };
}

/// التحقق من وجود ديون متأخرة
Future<bool> _checkOverdueDebts(dynamic db) async {
  // Use SupplierLedgerDriftDao to check for overdue debts
  // A debt is considered overdue if it's older than 30 days
  final ledgerDao = SupplierLedgerDriftDao(db);
  return await ledgerDao.hasOverdueDebts(overdueDays: 30);
}
