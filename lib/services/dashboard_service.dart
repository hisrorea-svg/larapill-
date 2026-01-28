import 'dart:developer' as developer;
import '../database/database_helper.dart';

class DashboardService {
  final DatabaseHelper _db = DatabaseHelper();

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final database = await _db.database;
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
          .toIso8601String();

      // 1️⃣ عدد الفواتير اليوم
      final salesCountResult = await database.rawQuery('''
        SELECT COUNT(*) as count, COALESCE(AVG(total), 0) as average
        FROM sales
        WHERE date >= ? AND date <= ? AND status = 'completed'
      ''', [startOfDay, endOfDay]);

      final salesCount = (salesCountResult.first['count'] as int?) ?? 0;
      final averageInvoice = _toDouble(salesCountResult.first['average']);

      // 2️⃣ قيمة المخزون (بسعر البيع)
      final inventoryValueResult = await database.rawQuery('''
        SELECT COALESCE(SUM(p.current_stock * pu.selling_price), 0) as total_value
        FROM products p
        INNER JOIN product_units pu ON p.id = pu.product_id AND pu.conversion_to_base = 1.0
        WHERE p.is_active = 1
      ''');

      final inventoryValue =
          _toDouble(inventoryValueResult.first['total_value']);

      // 3️⃣ إجمالي التكلفة (بسعر التكلفة)
      final totalCostResult = await database.rawQuery('''
        SELECT COALESCE(SUM(p.current_stock * pu.cost_price), 0) as total_cost
        FROM products p
        INNER JOIN product_units pu ON p.id = pu.product_id AND pu.conversion_to_base = 1.0
        WHERE p.is_active = 1
      ''');

      final totalCost = _toDouble(totalCostResult.first['total_cost']);

      // 4️⃣ الربح المتوقع
      final expectedProfit = inventoryValue - totalCost;
      final profitPercentage =
          totalCost > 0 ? (expectedProfit / totalCost) * 100 : 0.0;

      // 5️⃣ أدوية على وشك النفاذ
      final lowStockResult = await database.rawQuery('''
        SELECT COUNT(*) as count
        FROM products
        WHERE current_stock <= min_stock_level AND is_active = 1
      ''');

      final lowStockCount = (lowStockResult.first['count'] as int?) ?? 0;

      // ✅ 6️⃣ أدوية قريبة الانتهاء (خلال 90 يوم) - جديد!
      final now = DateTime.now();
      final expiryThreshold = now.add(const Duration(days: 90));

      final expiringSoonResult = await database.rawQuery('''
        SELECT COUNT(*) as count
        FROM products
        WHERE expiry_date IS NOT NULL 
          AND expiry_date <= ? 
          AND expiry_date >= ?
          AND is_active = 1
      ''', [expiryThreshold.toIso8601String(), now.toIso8601String()]);

      final expiringSoonCount =
          (expiringSoonResult.first['count'] as int?) ?? 0;

      // 7️⃣ إجمالي المبيعات اليوم
      final totalSalesTodayResult = await database.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total
        FROM sales
        WHERE date >= ? AND date <= ? AND status = 'completed'
      ''', [startOfDay, endOfDay]);

      final totalSalesToday = _toDouble(totalSalesTodayResult.first['total']);

      // 8️⃣ مقارنة مع الأمس
      final yesterday = today.subtract(const Duration(days: 1));
      final startOfYesterday =
          DateTime(yesterday.year, yesterday.month, yesterday.day)
              .toIso8601String();
      final endOfYesterday =
          DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59)
              .toIso8601String();

      final totalSalesYesterdayResult = await database.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total
        FROM sales
        WHERE date >= ? AND date <= ? AND status = 'completed'
      ''', [startOfYesterday, endOfYesterday]);

      final totalSalesYesterday =
          _toDouble(totalSalesYesterdayResult.first['total']);

      double percentageChange = 0.0;
      if (totalSalesYesterday > 0) {
        percentageChange =
            ((totalSalesToday - totalSalesYesterday) / totalSalesYesterday) *
                100;
      }

      developer.log(
          '✅ Dashboard Stats: Inventory: $inventoryValue, Expiring Soon: $expiringSoonCount',
          name: 'DashboardService');

      return {
        'sales_count': salesCount,
        'average_invoice': averageInvoice,
        'inventory_value': inventoryValue,
        'total_cost': totalCost,
        'expected_profit': expectedProfit,
        'profit_percentage': profitPercentage,
        'low_stock_count': lowStockCount,
        'expiring_soon_count': expiringSoonCount, // ✅ جديد!
        'total_sales_today': totalSalesToday,
        'percentage_change': percentageChange,
      };
    } catch (e) {
      developer.log('❌ خطأ في جلب إحصائيات Dashboard: $e',
          name: 'DashboardService');
      return {
        'sales_count': 0,
        'average_invoice': 0.0,
        'inventory_value': 0.0,
        'total_cost': 0.0,
        'expected_profit': 0.0,
        'profit_percentage': 0.0,
        'low_stock_count': 0,
        'expiring_soon_count': 0, // ✅ جديد!
        'total_sales_today': 0.0,
        'percentage_change': 0.0,
      };
    }
  }

  /// جلب أكثر المنتجات مبيعاً
  Future<Map<String, double>> getTopSellingProducts({int limit = 5}) async {
    try {
      final database = await _db.database;

      final result = await database.rawQuery('''
        SELECT p.name, COALESCE(SUM(si.quantity), 0) as total_sold
        FROM sale_items si
        INNER JOIN products p ON si.product_id = p.id
        INNER JOIN sales s ON si.sale_id = s.id
        WHERE s.status = 'completed'
        GROUP BY si.product_id
        ORDER BY total_sold DESC
        LIMIT ?
      ''', [limit]);

      final Map<String, double> topProducts = {};
      double totalSold = 0;

      // حساب المجموع الكلي
      for (var row in result) {
        final sold = (row['total_sold'] as num?)?.toDouble() ?? 0;
        totalSold += sold;
      }

      // حساب النسب المئوية
      if (totalSold > 0) {
        for (var row in result) {
          final name = row['name'] as String? ?? 'غير معروف';
          final sold = (row['total_sold'] as num?)?.toDouble() ?? 0;
          final percentage = (sold / totalSold) * 100;
          topProducts[name] = percentage;
        }
      }

      developer.log('✅ Top Selling Products: $topProducts',
          name: 'DashboardService');
      return topProducts;
    } catch (e) {
      developer.log('❌ خطأ في جلب أكثر المنتجات مبيعاً: $e',
          name: 'DashboardService');
      return {};
    }
  }
}
