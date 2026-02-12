import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Variable;
import '../../../../core/database/drift/database_provider.dart';
import '../../../../core/database/drift/app_database.dart';

/// نموذج بيانات تحليل سرعة الاستهلاك
class ProductVelocityData {
  final String productId;
  final String productName;
  final double avgDailySales;
  final double salesVelocity; // معدل الدوران
  final String velocityCategory; // slow, normal, fast, very_fast
  final DateTime? lastSaleDate;
  final int stockoutCount;
  final double recommendedMinStock;
  final double currentMinStock;
  final double trendFactor; // عامل الاتجاه (زيادة أو نقصان)
  final List<double> weeklyPattern; // نمط المبيعات الأسبوعي

  const ProductVelocityData({
    required this.productId,
    required this.productName,
    required this.avgDailySales,
    required this.salesVelocity,
    required this.velocityCategory,
    this.lastSaleDate,
    required this.stockoutCount,
    required this.recommendedMinStock,
    required this.currentMinStock,
    required this.trendFactor,
    required this.weeklyPattern,
  });

  bool get needsAdjustment => (recommendedMinStock - currentMinStock).abs() > 2;

  String get velocityLabel {
    switch (velocityCategory) {
      case 'very_fast':
        return 'مبيعات عالية جداً';
      case 'fast':
        return 'مبيعات عالية';
      case 'normal':
        return 'مبيعات متوسطة';
      case 'slow':
        return 'مبيعات بطيئة';
      default:
        return 'غير معروف';
    }
  }

  Color get velocityColor {
    switch (velocityCategory) {
      case 'very_fast':
        return Colors.red;
      case 'fast':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'slow':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// نموذج إعدادات الحد الأدنى الذكي
class SmartStockSettings {
  final String productId;
  final double baseMinStock;
  final double velocityMultiplier;
  final double seasonalFactor;
  final DateTime? lastCalculatedAt;
  final double calculatedMinStock;

  const SmartStockSettings({
    required this.productId,
    required this.baseMinStock,
    required this.velocityMultiplier,
    required this.seasonalFactor,
    this.lastCalculatedAt,
    required this.calculatedMinStock,
  });

  factory SmartStockSettings.fromMap(Map<String, dynamic> map) {
    return SmartStockSettings(
      productId: map['product_id'] as String,
      baseMinStock: (map['base_min_stock'] as num?)?.toDouble() ?? 5.0,
      velocityMultiplier:
          (map['velocity_multiplier'] as num?)?.toDouble() ?? 1.0,
      seasonalFactor: (map['seasonal_factor'] as num?)?.toDouble() ?? 1.0,
      lastCalculatedAt: map['last_calculated_at'] != null
          ? DateTime.parse(map['last_calculated_at'] as String)
          : null,
      calculatedMinStock:
          (map['calculated_min_stock'] as num?)?.toDouble() ?? 5.0,
    );
  }
}

/// خدمة تحليل سرعة الاستهلاك
class ProductVelocityAnalyzer {
  final AppDatabase _db;

  ProductVelocityAnalyzer(this._db);

  /// تحليل سرعة استهلاك منتج واحد
  Future<ProductVelocityData> analyzeProduct(String productId,
      {int daysBack = 30}) async {
    // جلب بيانات المنتج
    final productResult = await _db.customSelect(
      'SELECT * FROM products WHERE id = ? LIMIT 1',
      variables: [Variable.withString(productId)],
    ).get();

    if (productResult.isEmpty) {
      throw Exception('المنتج غير موجود');
    }

    final product = productResult.first.data;
    final productName = product['name'] as String;
    final currentMinStock =
        (product['min_stock_level'] as num?)?.toDouble() ?? 5.0;

    // جلب بيانات المبيعات للفترة
    final fromDate = DateTime.now().subtract(Duration(days: daysBack));
    final salesData = await _db.customSelect('''
      SELECT 
        s.date,
        SUM(si.quantity) as total_quantity,
        COUNT(*) as transaction_count
      FROM sale_items si
      INNER JOIN sales s ON si.sale_id = s.id
      WHERE si.product_id = ?
        AND s.date >= ?
        AND s.status = 'completed'
      GROUP BY date(s.date)
      ORDER BY s.date DESC
    ''', variables: [
      Variable.withString(productId),
      Variable.withString(fromDate.toIso8601String()),
    ]).get();

    // حساب المتوسط اليومي
    double totalQuantity = 0;
    int daysWithSales = 0;
    final weeklyPattern = List<double>.filled(7, 0);
    final dailySales = <double>[];

    for (final row in salesData) {
      final quantity = (row.data['total_quantity'] as num?)?.toDouble() ?? 0;
      final dateStr = row.data['date'] as String?;
      if (dateStr == null) continue;

      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      totalQuantity += quantity;
      daysWithSales++;
      weeklyPattern[date.weekday % 7] += quantity;
      dailySales.add(quantity);
    }

    final avgDailySales =
        daysWithSales > 0 ? (totalQuantity / daysBack).toDouble() : 0.0;

    // حساب الانحراف المعياري للاتجاه
    double trendFactor = 1.0;
    if (dailySales.length >= 7) {
      final firstHalf = dailySales
          .take(dailySales.length ~/ 2)
          .fold<double>(0, (a, b) => a + b);
      final secondHalf = dailySales
          .skip(dailySales.length ~/ 2)
          .fold<double>(0, (a, b) => a + b);
      trendFactor = firstHalf > 0 ? secondHalf / firstHalf : 1.0;
    }

    // تصنيف سرعة الاستهلاك
    final velocityCategory = _categorizeVelocity(avgDailySales);
    final velocityMultiplier = _getVelocityMultiplier(velocityCategory);

    // حساب الحد الأدنى الموصى به
    // المعادلة: الحد الأساسي × مضاعف السرعة × عامل الاتجاه × عامل الأمان
    const safetyFactor = 1.2; // عامل أمان 20%
    final recommendedMinStock = math.max(
        5.0, // الحد الأدنى المطلق
        (5.0 * velocityMultiplier * trendFactor * safetyFactor)
            .roundToDouble());

    // جلب تاريخ آخر بيع
    final lastSaleResult = await _db.customSelect('''
      SELECT MAX(s.date) as last_sale
      FROM sale_items si
      INNER JOIN sales s ON si.sale_id = s.id
      WHERE si.product_id = ? AND s.status = 'completed'
    ''', variables: [Variable.withString(productId)]).get();

    final lastSaleDate = lastSaleResult.isNotEmpty &&
            lastSaleResult.first.data['last_sale'] != null
        ? DateTime.parse(lastSaleResult.first.data['last_sale'] as String)
        : null;

    // جلب عدد مرات نفاد المخزون
    final stockoutResult = await _db.customSelect('''
      SELECT COUNT(*) as count
      FROM product_sales_history
      WHERE product_id = ? AND quantity_sold = 0
    ''', variables: [Variable.withString(productId)]).get();

    final stockoutCount = stockoutResult.isNotEmpty
        ? (stockoutResult.first.data['count'] as num?)?.toInt() ?? 0
        : 0;

    return ProductVelocityData(
      productId: productId,
      productName: productName,
      avgDailySales: avgDailySales.toDouble(),
      salesVelocity: (avgDailySales * velocityMultiplier).toDouble(),
      velocityCategory: velocityCategory,
      lastSaleDate: lastSaleDate,
      stockoutCount: stockoutCount,
      recommendedMinStock: recommendedMinStock,
      currentMinStock: currentMinStock,
      trendFactor: trendFactor,
      weeklyPattern: weeklyPattern,
    );
  }

  /// تحليل جميع المنتجات
  Future<List<ProductVelocityData>> analyzeAllProducts(
      {int daysBack = 30}) async {
    // جلب جميع المنتجات النشطة
    final products = await _db
        .customSelect(
          'SELECT id FROM products WHERE is_active = 1',
        )
        .get();

    final results = <ProductVelocityData>[];

    for (final product in products) {
      try {
        final productId = product.data['id']?.toString() ?? '';
        if (productId.isEmpty) continue;
        final analysis = await analyzeProduct(productId, daysBack: daysBack);
        results.add(analysis);
      } catch (e) {
        debugPrint('خطأ في تحليل المنتج ${product.data['id']}: $e');
      }
    }

    // ترتيب حسب أهمية التعديل
    results.sort((a, b) {
      final aPriority = (a.recommendedMinStock - a.currentMinStock).abs();
      final bPriority = (b.recommendedMinStock - b.currentMinStock).abs();
      return bPriority.compareTo(aPriority);
    });

    return results;
  }

  /// تصنيف سرعة الاستهلاك
  String _categorizeVelocity(double avgDailySales) {
    if (avgDailySales >= 10) return 'very_fast';
    if (avgDailySales >= 5) return 'fast';
    if (avgDailySales >= 1) return 'normal';
    return 'slow';
  }

  /// الحصول على مضاعف السرعة
  double _getVelocityMultiplier(String category) {
    switch (category) {
      case 'very_fast':
        return 3.0; // 3x للمنتجات سريعة الحركة
      case 'fast':
        return 2.0; // 2x للمنتجات سريعة
      case 'normal':
        return 1.0; // 1x للمنتجات عادية
      case 'slow':
        return 0.5; // 0.5x للمنتجات بطيئة
      default:
        return 1.0;
    }
  }

  /// تطبيق الحد الأدنى الذكي على منتج
  Future<void> applySmartMinStock(String productId,
      {bool autoApply = false}) async {
    final analysis = await analyzeProduct(productId);

    if (!autoApply || analysis.needsAdjustment) {
      await _db.customStatement('''
        UPDATE products SET
          min_stock_level = ?,
          avg_daily_sales = ?,
          sales_velocity = ?,
          last_sale_date = ?,
          updated_at = ?
        WHERE id = ?
      ''', [
        analysis.recommendedMinStock,
        analysis.avgDailySales,
        analysis.velocityCategory,
        analysis.lastSaleDate?.toIso8601String(),
        DateTime.now().toIso8601String(),
        productId,
      ]);

      // تحديث إعدادات الحد الأدنى الذكي
      await _db.customStatement('''
        INSERT OR REPLACE INTO smart_stock_settings 
        (product_id, base_min_stock, velocity_multiplier, seasonal_factor, 
         last_calculated_at, calculated_min_stock)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        productId,
        5.0,
        _getVelocityMultiplier(analysis.velocityCategory),
        1.0,
        DateTime.now().toIso8601String(),
        analysis.recommendedMinStock,
      ]);
    }
  }

  /// تطبيق الحد الأدنى الذكي على جميع المنتجات
  Future<Map<String, dynamic>> applySmartMinStockToAll(
      {bool autoApply = false}) async {
    final analyses = await analyzeAllProducts();
    int updatedCount = 0;
    int skippedCount = 0;

    for (final analysis in analyses) {
      if (autoApply && !analysis.needsAdjustment) {
        skippedCount++;
        continue;
      }

      try {
        await applySmartMinStock(analysis.productId, autoApply: true);
        updatedCount++;
      } catch (e) {
        debugPrint('خطأ في تحديث ${analysis.productId}: $e');
      }
    }

    return {
      'updated': updatedCount,
      'skipped': skippedCount,
      'total': analyses.length,
    };
  }

  /// تسجيل عملية بيع في التاريخ
  Future<void> recordSale(
      String productId, double quantity, DateTime date) async {
    await _db.customStatement('''
      INSERT OR IGNORE INTO product_sales_history
      (id, product_id, date, quantity_sold, day_of_week, is_weekend)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [
      '${productId}_${date.millisecondsSinceEpoch}',
      productId,
      date.toIso8601String(),
      quantity,
      date.weekday,
      (date.weekday == DateTime.friday || date.weekday == DateTime.saturday)
          ? 1
          : 0,
    ]);
  }

  /// الحصول على إعدادات المنتج
  Future<SmartStockSettings?> getSmartSettings(String productId) async {
    final result = await _db.customSelect('''
      SELECT * FROM smart_stock_settings WHERE product_id = ? LIMIT 1
    ''', variables: [Variable.withString(productId)]).get();

    if (result.isEmpty) return null;
    return SmartStockSettings.fromMap(result.first.data);
  }

  /// تحديث العوامل الموسمية
  Future<void> updateSeasonalFactors(Map<String, double> seasonalData) async {
    for (final entry in seasonalData.entries) {
      await _db.customStatement('''
        INSERT OR REPLACE INTO smart_stock_settings
        (product_id, seasonal_factor, last_calculated_at)
        VALUES (?, ?, ?)
      ''', [
        entry.key,
        entry.value,
        DateTime.now().toIso8601String(),
      ]);
    }
  }

  /// تنظيف البيانات القديمة (أقدم من 90 يوم)
  Future<int> cleanupOldData({int daysToKeep = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    // نحتاج استخدام customSelect لمعرفة عدد الصفوف المتأثرة
    final countBefore = await _db.customSelect('''
      SELECT COUNT(*) as count FROM product_sales_history WHERE date < ?
    ''', variables: [Variable.withString(cutoffDate.toIso8601String())]).get();

    final deletedCount = countBefore.isNotEmpty
        ? (countBefore.first.data['count'] as int?) ?? 0
        : 0;

    await _db.customStatement('''
      DELETE FROM product_sales_history WHERE date < ?
    ''', [cutoffDate.toIso8601String()]);

    return deletedCount;
  }
}

/// Provider للمحلل
final productVelocityAnalyzerProvider =
    Provider<ProductVelocityAnalyzer>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductVelocityAnalyzer(db);
});

/// Provider لتحليل جميع المنتجات
final allProductsVelocityProvider =
    FutureProvider.autoDispose<List<ProductVelocityData>>((ref) async {
  final analyzer = ref.watch(productVelocityAnalyzerProvider);
  return await analyzer.analyzeAllProducts(daysBack: 30);
});

/// Provider لتحليل منتج محدد
final productVelocityProvider = FutureProvider.autoDispose
    .family<ProductVelocityData, String>((ref, productId) async {
  final analyzer = ref.watch(productVelocityAnalyzerProvider);
  return await analyzer.analyzeProduct(productId);
});
