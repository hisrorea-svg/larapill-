/// Sales Drift DAO - Type-safe database access for sales
///
/// This DAO provides all sales-related database operations using Drift.
/// Includes reactive streams for POS and reporting.
library sales_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/database_provider.dart';

part 'sales_drift_dao.g.dart';

/// DAO for Sales and SaleItems tables
@DriftAccessor(tables: [Sales, SaleItems, Products])
class SalesDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SalesDriftDaoMixin {
  SalesDriftDao(super.db);

  // ═══════════════════════════════════════════════════════════════════════════
  // 📖 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all sales
  Future<List<SaleEntry>> findAll() => select(sales).get();

  /// Get sales for a date range
  Future<List<SaleEntry>> findByDateRange(DateTime start, DateTime end) {
    return (select(sales)
          ..where((s) => s.date.isBetweenValues(start, end))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  /// Watch sales for today
  Stream<List<SaleEntry>> watchTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(sales)
          ..where((s) => s.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  /// Find sale by ID
  Future<SaleEntry?> findById(String id) {
    return (select(sales)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Find sale by invoice number
  Future<SaleEntry?> findByInvoiceNumber(String invoiceNumber) {
    return (select(sales)..where((s) => s.invoiceNumber.equals(invoiceNumber)))
        .getSingleOrNull();
  }

  /// Get sales by customer phone
  Future<List<SaleEntry>> findByCustomerPhone(String phone) {
    return (select(sales)
          ..where((s) => s.customerPhone.equals(phone))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  /// Get unpaid/partial sales (debts)
  Future<List<SaleEntry>> findUnpaidSales() {
    return (select(sales)
          ..where((s) =>
              s.paymentStatus.equals('partial') |
              s.paymentStatus.equals('unpaid'))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  /// Watch unpaid sales
  Stream<List<SaleEntry>> watchUnpaidSales() {
    return (select(sales)
          ..where((s) =>
              s.paymentStatus.equals('partial') |
              s.paymentStatus.equals('unpaid'))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 SALE ITEMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get items for a sale
  Future<List<SaleItemEntry>> getSaleItems(String saleId) {
    return (select(saleItems)..where((i) => i.saleId.equals(saleId))).get();
  }

  /// Watch sale items
  Stream<List<SaleItemEntry>> watchSaleItems(String saleId) {
    return (select(saleItems)..where((i) => i.saleId.equals(saleId))).watch();
  }

  /// Get sale with items (joined)
  Future<SaleWithItems?> getSaleWithItems(String saleId) async {
    final sale = await findById(saleId);
    if (sale == null) return null;

    final items = await getSaleItems(saleId);
    return SaleWithItems(sale: sale, items: items);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✏️ WRITE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new sale with items (transaction)
  Future<String> createSale({
    required SalesCompanion sale,
    required List<SaleItemsCompanion> items,
  }) async {
    return transaction(() async {
      // Insert sale
      await into(sales).insert(sale);

      // Insert items
      await batch((batch) {
        batch.insertAll(saleItems, items);
      });

      return sale.id.value;
    });
  }

  /// Update sale payment status
  Future<int> updatePaymentStatus({
    required String saleId,
    required double paidAmount,
    required double remainingAmount,
    required String paymentStatus,
  }) {
    return (update(sales)..where((s) => s.id.equals(saleId))).write(
      SalesCompanion(
        paidAmount: Value(paidAmount),
        remainingAmount: Value(remainingAmount),
        paymentStatus: Value(paymentStatus),
      ),
    );
  }

  /// Cancel a sale
  Future<int> cancelSale(String saleId) {
    return (update(sales)..where((s) => s.id.equals(saleId))).write(
      const SalesCompanion(
        status: Value('cancelled'),
      ),
    );
  }

  /// Delete a sale and its items
  Future<void> deleteSale(String saleId) {
    return transaction(() async {
      // Delete items first (foreign key)
      await (delete(saleItems)..where((i) => i.saleId.equals(saleId))).go();
      // Delete sale
      await (delete(sales)..where((s) => s.id.equals(saleId))).go();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 STATISTICS & REPORTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get today's sales summary
  Future<SalesSummary> getTodaySummary() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(total), 0) as total,
        COALESCE(SUM(paid_amount), 0) as paid,
        COALESCE(SUM(remaining_amount), 0) as remaining
      FROM sales 
      WHERE date >= ? AND date < ? AND status = 'completed'
      ''',
      variables: [Variable(startOfDay), Variable(endOfDay)],
      readsFrom: {sales},
    ).getSingle();

    return SalesSummary(
      salesCount: result.read<int>('count'),
      totalSales: result.read<double>('total'),
      totalPaid: result.read<double>('paid'),
      totalRemaining: result.read<double>('remaining'),
    );
  }

  /// Watch today's summary (reactive)
  Stream<SalesSummary> watchTodaySummary() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return customSelect(
      '''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(total), 0) as total,
        COALESCE(SUM(paid_amount), 0) as paid,
        COALESCE(SUM(remaining_amount), 0) as remaining
      FROM sales 
      WHERE date >= ? AND date < ? AND status = 'completed'
      ''',
      variables: [Variable(startOfDay), Variable(endOfDay)],
      readsFrom: {sales},
    )
        .map((row) => SalesSummary(
              salesCount: row.read<int>('count'),
              totalSales: row.read<double>('total'),
              totalPaid: row.read<double>('paid'),
              totalRemaining: row.read<double>('remaining'),
            ))
        .watchSingle();
  }

  /// Get sales by cashier for a date range
  Future<List<CashierSalesReport>> getSalesByCashier(
      DateTime start, DateTime end) {
    return customSelect(
      '''
      SELECT 
        cashier_id, 
        cashier_name,
        COUNT(*) as count,
        SUM(total) as total
      FROM sales 
      WHERE date >= ? AND date < ? AND status = 'completed'
      GROUP BY cashier_id, cashier_name
      ORDER BY total DESC
      ''',
      variables: [Variable(start), Variable(end)],
      readsFrom: {sales},
    )
        .map((row) => CashierSalesReport(
              cashierId: row.read<String>('cashier_id'),
              cashierName: row.read<String?>('cashier_name') ?? 'Unknown',
              salesCount: row.read<int>('count'),
              totalSales: row.read<double>('total'),
            ))
        .get();
  }

  /// Generate next invoice number
  Future<String> generateInvoiceNumber() async {
    final today = DateTime.now();
    final prefix =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final result = await customSelect(
      "SELECT invoice_number FROM sales WHERE invoice_number LIKE ? ORDER BY invoice_number DESC LIMIT 1",
      variables: [Variable('$prefix%')],
      readsFrom: {sales},
    ).getSingleOrNull();

    if (result == null) {
      return '${prefix}001';
    }

    final lastNumber = result.read<String>('invoice_number');
    final sequence = int.parse(lastNumber.substring(8)) + 1;
    return '$prefix${sequence.toString().padLeft(3, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Sale with its items
class SaleWithItems {
  final SaleEntry sale;
  final List<SaleItemEntry> items;

  const SaleWithItems({
    required this.sale,
    required this.items,
  });
}

/// Sales summary for dashboard
class SalesSummary {
  final int salesCount;
  final double totalSales;
  final double totalPaid;
  final double totalRemaining;

  const SalesSummary({
    required this.salesCount,
    required this.totalSales,
    required this.totalPaid,
    required this.totalRemaining,
  });

  double get averageSale => salesCount > 0 ? totalSales / salesCount : 0;
}

/// Cashier sales report
class CashierSalesReport {
  final String cashierId;
  final String cashierName;
  final int salesCount;
  final double totalSales;

  const CashierSalesReport({
    required this.cashierId,
    required this.cashierName,
    required this.salesCount,
    required this.totalSales,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔌 RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for SalesDriftDao
final salesDriftDaoProvider = Provider<SalesDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesDriftDao(db);
});

/// Stream provider for today's sales
final todaySalesStreamProvider = StreamProvider<List<SaleEntry>>((ref) {
  final dao = ref.watch(salesDriftDaoProvider);
  return dao.watchTodaySales();
});

/// Stream provider for today's summary
final todaySalesSummaryProvider = StreamProvider<SalesSummary>((ref) {
  final dao = ref.watch(salesDriftDaoProvider);
  return dao.watchTodaySummary();
});

/// Stream provider for unpaid sales
final unpaidSalesStreamProvider = StreamProvider<List<SaleEntry>>((ref) {
  final dao = ref.watch(salesDriftDaoProvider);
  return dao.watchUnpaidSales();
});
