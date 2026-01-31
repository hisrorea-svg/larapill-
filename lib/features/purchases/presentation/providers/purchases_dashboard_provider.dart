import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database_helper.dart';
import '../../data/datasources/local/supplier_returns_dao.dart';
import '../../data/datasources/local/purchase_orders_dao.dart';

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
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final returnsDao = SupplierReturnsDao();
  final ordersDao = PurchaseOrdersDao();

  // 1. جلب عدد النواقص (المنتجات ذات المخزون المنخفض)
  final lowStockResult = await db.rawQuery('''
    SELECT COUNT(*) as count FROM products
    WHERE current_stock <= min_stock_level AND is_active = 1
  ''');
  final lowStockCount = (lowStockResult.first['count'] as num?)?.toInt() ?? 0;

  // 2. جلب عدد الفواتير المعلقة (المسودات)
  final draftOrders = await ordersDao.getDraftOrders();
  final pendingInvoices = draftOrders.length;

  // 3. جلب مبلغ المرتجعات الجاهزة للتسليم
  final returnsStats = await returnsDao.getReturnsStats();
  final pendingReturnsAmount =
      (returnsStats['prepared_amount'] as num?)?.toDouble() ?? 0;

  // 4. جلب إجمالي الديون مُصنّفة حسب نوع الدفع
  final debtsByType = await _getDebtsByPaymentType(db);

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
Future<Map<String, double>> _getDebtsByPaymentType(dynamic db) async {
  final result = await db.rawQuery('''
    SELECT 
      s.payment_type,
      COALESCE(SUM(l.balance_after), 0) as total_debt
    FROM suppliers s
    LEFT JOIN (
      SELECT supplier_id, balance_after
      FROM supplier_ledger
      WHERE id IN (
        SELECT MAX(id) FROM supplier_ledger GROUP BY supplier_id
      )
    ) l ON s.id = l.supplier_id
    WHERE l.balance_after > 0
    GROUP BY s.payment_type
  ''');

  double cashDebt = 0;
  double monthlyDebt = 0;
  double creditDebt = 0;
  double total = 0;

  for (final row in result) {
    final paymentType = row['payment_type'] as String? ?? 'cash';
    final debt = (row['total_debt'] as num?)?.toDouble() ?? 0;

    total += debt;

    switch (paymentType) {
      case 'cash':
      case 'weekly':
        cashDebt += debt;
        break;
      case 'monthly':
        monthlyDebt += debt;
        break;
      case 'credit':
        creditDebt += debt;
        break;
      default:
        cashDebt += debt;
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
  final sevenDaysAgo =
      DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

  final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM supplier_ledger sl
    INNER JOIN suppliers s ON sl.supplier_id = s.id
    WHERE sl.balance_after > 0
      AND sl.created_at < ?
      AND (s.payment_type = 'cash' OR s.payment_type = 'weekly')
    LIMIT 1
  ''', [sevenDaysAgo]);

  return ((result.first['count'] as num?)?.toInt() ?? 0) > 0;
}
