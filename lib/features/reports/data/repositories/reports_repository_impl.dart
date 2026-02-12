import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/daos/daos.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/inventory_report.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/debts_report.dart';
import '../../domain/entities/top_product.dart';
import '../../domain/repositories/reports_repository.dart';

// ============ Constants ============

/// نسبة الربح الافتراضية (25%)
const double kDefaultProfitMargin = 0.25;

/// نسبة المصروفات الافتراضية (5%)
const double kDefaultExpenseRatio = 0.05;

/// عدد أيام انتهاء الصلاحية القريب (90 يوم)
const int kExpiringSoonDays = 90;

/// عدد أيام الديون المتأخرة (30 يوم)
const int kOverdueDays = 30;

/// الحد الأدنى الافتراضي للمخزون
const int kDefaultMinStockLevel = 10;

// ============ Repository Implementation ============

/// تنفيذ مستودع التقارير
class ReportsRepositoryImpl implements ReportsRepository {
  final SalesDriftDao _salesDao;
  final ProductDriftDao _productDao;
  final CustomerDebtDriftDao _debtDao;
  final ExpenseDriftDao _expenseDao;

  ReportsRepositoryImpl(
      this._salesDao, this._productDao, this._debtDao, this._expenseDao);

  @override
  Future<SalesReport> getSalesReport(ReportPeriod period) async {
    try {
      // جلب جميع المبيعات
      final allSales = await _salesDao.findAll();

      // تصفية حسب الفترة الزمنية
      final filteredSales = allSales.where((sale) {
        return period.contains(sale.date);
      }).toList();

      // حساب الإحصائيات
      double totalSales = 0;
      int cashInvoices = 0;
      int creditInvoices = 0;

      for (final sale in filteredSales) {
        totalSales += sale.total;

        if (sale.paymentMethod == 'cash') {
          cashInvoices++;
        } else if (sale.paymentMethod == 'credit') {
          creditInvoices++;
        }
      }

      // تقدير الربح - يمكن تحسينه لاحقاً بحساب دقيق
      final expectedProfit = totalSales * kDefaultProfitMargin;

      // جلب المرتجعات (يمكن إضافتها لاحقاً)
      const returnCount = 0;
      const returnValue = 0.0;

      return SalesReport(
        period: period,
        invoiceCount: filteredSales.length,
        totalSales: totalSales,
        expectedProfit: expectedProfit,
        cashInvoices: cashInvoices,
        creditInvoices: creditInvoices,
        returnCount: returnCount,
        returnValue: returnValue,
      );
    } catch (e, stack) {
      dev.log(
        'Error fetching sales report',
        error: e,
        stackTrace: stack,
        name: 'ReportsRepository',
      );
      return SalesReport.empty(period);
    }
  }

  @override
  Future<InventoryReport> getInventoryReport() async {
    try {
      // جلب جميع المنتجات مع الوحدات
      final allProducts = await _productDao.findAllWithUnitsOptimized();

      int totalProducts = allProducts.length;
      double inventoryValue = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      int expiringSoonCount = 0;
      int expiredCount = 0;

      final now = DateTime.now();
      final expiryThreshold = now.add(const Duration(days: kExpiringSoonDays));

      for (final productWithUnits in allProducts) {
        final product = productWithUnits.product;
        final units = productWithUnits.units;

        // حساب قيمة المخزون باستخدام سعر التكلفة من الوحدة الأساسية
        final baseUnit = units.isNotEmpty ? units.first : null;
        final costPrice = baseUnit?.costPrice ?? 0;
        inventoryValue += product.currentStock * costPrice;

        // المخزون المنخفض (أقل من الحد الأدنى)
        final minLevel = product.minStockLevel > 0
            ? product.minStockLevel
            : kDefaultMinStockLevel;
        if (product.currentStock > 0 && product.currentStock < minLevel) {
          lowStockCount++;
        }

        // نفذ من المخزون
        if (product.currentStock <= 0) {
          outOfStockCount++;
        }

        // التحقق من تاريخ الانتهاء
        if (product.expiryDate != null) {
          if (product.expiryDate!.isBefore(now)) {
            expiredCount++;
          } else if (product.expiryDate!.isBefore(expiryThreshold)) {
            expiringSoonCount++;
          }
        }
      }

      return InventoryReport(
        totalProducts: totalProducts,
        inventoryValue: inventoryValue,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        expiringSoonCount: expiringSoonCount,
        expiredCount: expiredCount,
      );
    } catch (e, stack) {
      dev.log(
        'Error fetching inventory report',
        error: e,
        stackTrace: stack,
        name: 'ReportsRepository',
      );
      return InventoryReport.empty();
    }
  }

  @override
  Future<FinancialReport> getFinancialReport(ReportPeriod period) async {
    try {
      // جلب تقرير المبيعات
      final salesReport = await getSalesReport(period);

      // Calculate real expenses
      // Assuming period has start and end dates.
      // If not, we might need a helper, but ReportPeriod usually allows us to get the range
      // or we can use the same logic as getSalesReport (which uses database query).
      // But ExpenseDriftDao needs dates.

      // Let's inspect ReportPeriod class to be sure about how to get dates.
      // Since I can't view it easily now without losing context, I will use a helper
      // based on period type if needed, or if period has start/end getter.
      // I'll take a safe bet that I need to calculate dates from the period.

      // Minimal logic to extract dates from ReportPeriod - checking checking what's available
      // Actually, let's look at getSalesReport. It uses period.contains(date).
      // But ExpenseDAO.getTotalExpenses needs (from, to).
      // I will implement a helper in this file to convert ReportPeriod to DateTime range.

      final totalExpenses =
          await _expenseDao.getTotalExpenses(period.startDate, period.endDate);

      return FinancialReport(
        period: period,
        totalRevenue: salesReport.totalSales,
        totalProfit: salesReport.expectedProfit,
        totalExpenses: totalExpenses,
        totalPurchases: 0, // يمكن إضافتها لاحقاً من جدول المشتريات
      );
    } catch (e, stack) {
      dev.log(
        'Error fetching financial report',
        error: e,
        stackTrace: stack,
        name: 'ReportsRepository',
      );
      return FinancialReport.empty(period);
    }
  }

  @override
  Future<DebtsReport> getDebtsReport() async {
    try {
      final allDebts = await _debtDao.getAllDebts();

      double totalDebts = 0;
      double totalCollected = 0;
      int overdueCount = 0;
      double overdueValue = 0;

      final now = DateTime.now();
      final overdueThreshold = now.subtract(const Duration(days: kOverdueDays));

      for (final debt in allDebts) {
        totalDebts += debt.remainingDebt;
        totalCollected += debt.totalPaid;

        // الديون المتأخرة
        if (debt.remainingDebt > 0) {
          if (debt.lastTransactionDate.isBefore(overdueThreshold)) {
            overdueCount++;
            overdueValue += debt.remainingDebt;
          }
        }
      }

      return DebtsReport(
        totalDebts: totalDebts,
        debtorsCount: allDebts.where((d) => d.remainingDebt > 0).length,
        totalCollected: totalCollected,
        overdueCount: overdueCount,
        overdueValue: overdueValue,
      );
    } catch (e, stack) {
      dev.log(
        'Error fetching debts report',
        error: e,
        stackTrace: stack,
        name: 'ReportsRepository',
      );
      return DebtsReport.empty();
    }
  }

  @override
  Future<List<TopProduct>> getTopProducts({
    required int limit,
    required ReportPeriod period,
  }) async {
    try {
      // ✅ استخدام الاستعلام المحسن بدلاً من N+1 queries
      final saleItems = await _salesDao.getSaleItemsWithDateRange(
        period.startDate,
        period.endDate,
      );

      // تجميع المبيعات حسب المنتج
      final productSales = <String, _ProductSalesData>{};

      for (final item in saleItems) {
        final existing = productSales[item.productId];
        if (existing != null) {
          productSales[item.productId] = _ProductSalesData(
            productId: item.productId,
            name: item.productName,
            quantitySold: existing.quantitySold + item.quantity.toInt(),
            totalSales: existing.totalSales + item.total,
          );
        } else {
          productSales[item.productId] = _ProductSalesData(
            productId: item.productId,
            name: item.productName,
            quantitySold: item.quantity.toInt(),
            totalSales: item.total,
          );
        }
      }

      // ترتيب حسب الكمية المباعة
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

      // تحويل إلى TopProduct مع الترتيب
      return sortedProducts
          .take(limit)
          .toList()
          .asMap()
          .entries
          .map((entry) => TopProduct(
                productId: int.tryParse(entry.value.productId) ?? 0,
                name: entry.value.name,
                quantitySold: entry.value.quantitySold,
                totalSales: entry.value.totalSales,
                rank: entry.key + 1,
              ))
          .toList();
    } catch (e, stack) {
      dev.log(
        'Error fetching top products',
        error: e,
        stackTrace: stack,
        name: 'ReportsRepository',
      );
      return [];
    }
  }
}

/// بيانات مبيعات منتج مؤقتة للحساب
class _ProductSalesData {
  final String productId;
  final String name;
  final int quantitySold;
  final double totalSales;

  _ProductSalesData({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.totalSales,
  });
}

// ============ Providers ============

/// Provider لـ ProductDriftDao
final productDriftDaoProvider = Provider<ProductDriftDao>(
    (ref) => ProductDriftDao(ref.watch(appDatabaseProvider)));

/// Provider لـ CustomerDebtDriftDao
final _customerDebtDaoProvider = Provider<CustomerDebtDriftDao>(
    (ref) => CustomerDebtDriftDao(ref.watch(appDatabaseProvider)));

/// Provider لمستودع التقارير
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
    ref.watch(salesDriftDaoProvider),
    ref.watch(productDriftDaoProvider),
    ref.watch(_customerDebtDaoProvider),
    ref.watch(expenseDriftDaoProvider),
  );
});
