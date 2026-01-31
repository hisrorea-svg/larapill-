import '../../data/datasources/local/supplier_ledger_dao.dart';
import '../../data/datasources/local/supplier_returns_dao.dart';
import '../../data/datasources/local/purchase_orders_dao.dart';
import '../../../../database/database_helper.dart';

/// إحصائيات لوحة تحكم المشتريات
class DashboardStats {
  final int lowStockCount;
  final int pendingInvoices;
  final double pendingReturnsAmount;
  final int preparedReturnsCount;
  final double totalDebt;
  final double cashDebt;
  final double weeklyDebt;
  final double monthlyDebt;
  final double creditDebt;
  final bool hasOverdueDebt;
  final int overdueCount;
  final Map<String, double> debtBySupplier;

  const DashboardStats({
    this.lowStockCount = 0,
    this.pendingInvoices = 0,
    this.pendingReturnsAmount = 0,
    this.preparedReturnsCount = 0,
    this.totalDebt = 0,
    this.cashDebt = 0,
    this.weeklyDebt = 0,
    this.monthlyDebt = 0,
    this.creditDebt = 0,
    this.hasOverdueDebt = false,
    this.overdueCount = 0,
    this.debtBySupplier = const {},
  });

  /// نسبة الديون النقدية
  double get cashDebtPercent =>
      totalDebt > 0 ? (cashDebt / totalDebt) * 100 : 0;

  /// نسبة الديون الشهرية
  double get monthlyDebtPercent =>
      totalDebt > 0 ? (monthlyDebt / totalDebt) * 100 : 0;

  /// نسبة الديون الآجلة
  double get creditDebtPercent =>
      totalDebt > 0 ? (creditDebt / totalDebt) * 100 : 0;
}

/// Use Case: جلب إحصائيات لوحة التحكم
///
/// يجمع البيانات من عدة مصادر:
/// - المخزون المنخفض
/// - الفواتير المعلقة
/// - المرتجعات الجاهزة
/// - الديون المصنفة
class GetDashboardStatsUseCase {
  final DatabaseHelper _dbHelper;
  final SupplierLedgerDao _ledgerDao;
  final SupplierReturnsDao _returnsDao;
  final PurchaseOrdersDao _ordersDao;

  GetDashboardStatsUseCase({
    DatabaseHelper? dbHelper,
    SupplierLedgerDao? ledgerDao,
    SupplierReturnsDao? returnsDao,
    PurchaseOrdersDao? ordersDao,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _ledgerDao = ledgerDao ?? SupplierLedgerDao(),
        _returnsDao = returnsDao ?? SupplierReturnsDao(),
        _ordersDao = ordersDao ?? PurchaseOrdersDao();

  /// تنفيذ الـ Use Case
  Future<DashboardStats> execute() async {
    final db = await _dbHelper.database;

    // 1. عدد النواقص
    final lowStockCount = await _getLowStockCount(db);

    // 2. الفواتير المعلقة
    final pendingInvoices = await _getPendingInvoices();

    // 3. المرتجعات
    final returnsStats = await _getReturnsStats();

    // 4. الديون
    final debtStats = await _getDebtStats(db);

    // 5. الديون المتأخرة
    final overdueStats = await _getOverdueStats(db);

    return DashboardStats(
      lowStockCount: lowStockCount,
      pendingInvoices: pendingInvoices,
      pendingReturnsAmount: (returnsStats['amount'] ?? 0).toDouble(),
      preparedReturnsCount: returnsStats['count']?.toInt() ?? 0,
      totalDebt: debtStats['total'] ?? 0,
      cashDebt: debtStats['cash'] ?? 0,
      weeklyDebt: debtStats['weekly'] ?? 0,
      monthlyDebt: debtStats['monthly'] ?? 0,
      creditDebt: debtStats['credit'] ?? 0,
      hasOverdueDebt: overdueStats['hasOverdue'] ?? false,
      overdueCount: overdueStats['count']?.toInt() ?? 0,
      debtBySupplier: debtStats['bySupplier'] ?? {},
    );
  }

  /// جلب عدد المنتجات ذات المخزون المنخفض
  Future<int> _getLowStockCount(dynamic db) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM products 
      WHERE current_stock <= min_stock_level 
        AND is_active = 1
    ''');
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب عدد الفواتير المعلقة (المسودات)
  Future<int> _getPendingInvoices() async {
    final drafts = await _ordersDao.getDraftOrders();
    return drafts.length;
  }

  /// جلب إحصائيات المرتجعات
  Future<Map<String, num>> _getReturnsStats() async {
    final returns = await _returnsDao.getPreparedReturns();
    final totalAmount = returns.fold<double>(
      0,
      (sum, r) => sum + r.amount,
    );
    return {
      'count': returns.length,
      'amount': totalAmount,
    };
  }

  /// جلب إحصائيات الديون مصنفة حسب نوع الدفع
  Future<Map<String, dynamic>> _getDebtStats(dynamic db) async {
    final result = await db.rawQuery('''
      SELECT 
        s.id as supplier_id,
        s.name as supplier_name,
        s.payment_type,
        COALESCE(l.balance_after, 0) as balance
      FROM suppliers s
      LEFT JOIN (
        SELECT supplier_id, balance_after
        FROM supplier_ledger sl1
        WHERE id = (
          SELECT MAX(id) 
          FROM supplier_ledger sl2 
          WHERE sl2.supplier_id = sl1.supplier_id
        )
      ) l ON s.id = l.supplier_id
      WHERE l.balance_after > 0
    ''');

    double total = 0;
    double cash = 0;
    double weekly = 0;
    double monthly = 0;
    double credit = 0;
    final bySupplier = <String, double>{};

    for (final row in result) {
      final balance = (row['balance'] as num).toDouble();
      final paymentType = row['payment_type'] as String? ?? 'cash';
      final supplierName = row['supplier_name'] as String? ?? 'Unknown';

      total += balance;
      bySupplier[supplierName] = balance;

      switch (paymentType) {
        case 'cash':
          cash += balance;
          break;
        case 'weekly':
          weekly += balance;
          break;
        case 'monthly':
          monthly += balance;
          break;
        case 'credit':
          credit += balance;
          break;
        default:
          cash += balance;
      }
    }

    return {
      'total': total,
      'cash': cash,
      'weekly': weekly,
      'monthly': monthly,
      'credit': credit,
      'bySupplier': bySupplier,
    };
  }

  /// جلب إحصائيات الديون المتأخرة
  Future<Map<String, dynamic>> _getOverdueStats(dynamic db) async {
    final now = DateTime.now();

    // الديون المتأخرة: أكثر من 7 أيام للنقدي/الأسبوعي
    final sevenDaysAgo =
        now.subtract(const Duration(days: 7)).toIso8601String();

    // الديون المتأخرة: أكثر من 30 يوم للشهري
    final thirtyDaysAgo =
        now.subtract(const Duration(days: 30)).toIso8601String();

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM supplier_ledger sl
      INNER JOIN suppliers s ON sl.supplier_id = s.id
      WHERE sl.balance_after > 0
        AND (
          (s.payment_type IN ('cash', 'weekly') AND sl.created_at < ?)
          OR
          (s.payment_type = 'monthly' AND sl.created_at < ?)
        )
    ''', [sevenDaysAgo, thirtyDaysAgo]);

    final count = (result.first['count'] as num?)?.toInt() ?? 0;

    return {
      'hasOverdue': count > 0,
      'count': count,
    };
  }

  /// جلب إجمالي ديون مورد معين
  Future<double> getSupplierDebt(String supplierId) async {
    return await _ledgerDao.getSupplierBalance(supplierId);
  }

  /// جلب تفصيل ديون مورد
  Future<Map<String, dynamic>> getSupplierDebtDetails(String supplierId) async {
    final entries = await _ledgerDao.getSupplierEntries(supplierId);
    final currentBalance = await _ledgerDao.getSupplierBalance(supplierId);

    double totalInvoices = 0;
    double totalPayments = 0;
    double totalReturns = 0;

    for (final entry in entries) {
      switch (entry.referenceType) {
        case 'invoice':
          if (entry.amount > 0) totalInvoices += entry.amount;
          break;
        case 'payment':
          if (entry.amount < 0) totalPayments += entry.amount.abs();
          break;
        case 'return':
          if (entry.amount < 0) totalReturns += entry.amount.abs();
          break;
      }
    }

    return {
      'currentBalance': currentBalance,
      'totalInvoices': totalInvoices,
      'totalPayments': totalPayments,
      'totalReturns': totalReturns,
      'entries': entries,
    };
  }
}
