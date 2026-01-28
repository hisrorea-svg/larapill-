import 'dart:async';
import '../database_helper.dart';
import '../../features/purchases/models/daily_purchase_request.dart';

/// DAO للتعامل مع طلبيات الشراء اليومية
class DailyPurchaseRequestDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// جلب طلبيات اليوم
  Future<List<DailyPurchaseRequest>> getTodayRequests() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final maps = await db.query(
      'daily_purchase_requests',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'auto_added DESC, created_at ASC', // التلقائي أولاً
    );

    return maps.map((map) => DailyPurchaseRequest.fromMap(map)).toList();
  }

  /// جلب جميع الطلبيات (لتاريخ معين)
  Future<List<DailyPurchaseRequest>> getRequestsByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];

    final maps = await db.query(
      'daily_purchase_requests',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'auto_added DESC, created_at ASC',
    );

    return maps.map((map) => DailyPurchaseRequest.fromMap(map)).toList();
  }

  /// عدد الطلبيات لليوم
  Future<int> getTodayRequestsCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_purchase_requests WHERE date = ?',
      [today],
    );

    return result.first['count'] as int;
  }

  /// عدد الطلبيات التلقائية لليوم (النواقص)
  Future<int> getTodayAutoRequestsCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_purchase_requests WHERE date = ? AND auto_added = 1',
      [today],
    );

    return result.first['count'] as int;
  }

  /// إضافة طلبية جديدة
  Future<void> insertRequest(DailyPurchaseRequest request) async {
    final db = await _dbHelper.database;
    await db.insert('daily_purchase_requests', request.toMap());
  }

  /// التحقق من وجود منتج في طلبية اليوم
  Future<bool> isProductInTodayRequest(String productId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.query(
      'daily_purchase_requests',
      where: 'product_id = ? AND date = ?',
      whereArgs: [productId, today],
    );

    return result.isNotEmpty;
  }

  /// تحديث كمية منتج موجود
  Future<void> updateQuantity(String requestId, double newQuantity) async {
    final db = await _dbHelper.database;
    await db.update(
      'daily_purchase_requests',
      {'requested_quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  /// حذف طلبية
  Future<void> deleteRequest(String requestId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'daily_purchase_requests',
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  /// حذف جميع طلبيات اليوم
  Future<void> clearTodayRequests() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    await db.delete(
      'daily_purchase_requests',
      where: 'date = ?',
      whereArgs: [today],
    );
  }

  /// حذف الطلبيات القديمة (أقدم من عدد أيام معين)
  Future<void> deleteOldRequests({int daysToKeep = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String()
        .split('T')[0];

    await db.delete(
      'daily_purchase_requests',
      where: 'date < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// إحصائيات الطلبيات
  Future<Map<String, dynamic>> getRequestsStats() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_items,
        SUM(requested_quantity) as total_quantity,
        SUM(CASE WHEN auto_added = 1 THEN 1 ELSE 0 END) as auto_items,
        SUM(CASE WHEN auto_added = 0 THEN 1 ELSE 0 END) as manual_items
      FROM daily_purchase_requests 
      WHERE date = ?
    ''', [today]);

    final row = result.first;
    return {
      'totalItems': row['total_items'] ?? 0,
      'totalQuantity': row['total_quantity'] ?? 0.0,
      'autoItems': row['auto_items'] ?? 0,
      'manualItems': row['manual_items'] ?? 0,
    };
  }
}
