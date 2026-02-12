/// Daily Purchase Requests Drift DAO
library daily_purchase_request_drift_dao;

import 'package:drift/drift.dart';
import '../../../../../core/database/drift/app_database.dart';

part 'daily_purchase_request_drift_dao.g.dart';

@DriftAccessor(tables: [DailyPurchaseRequests])
class DailyPurchaseRequestDriftDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPurchaseRequestDriftDaoMixin {
  DailyPurchaseRequestDriftDao(super.db);

  /// Check if a product is already in today's request
  Future<bool> isProductInTodayRequest(String productId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final count = await (select(dailyPurchaseRequests)
          ..where((r) =>
              r.productId.equals(productId) &
              r.date.isBetweenValues(startOfDay, endOfDay)))
        .get();

    return count.isNotEmpty;
  }

  /// Insert a new request
  Future<void> insertRequest(DailyPurchaseRequestsCompanion companion) {
    return into(dailyPurchaseRequests).insert(companion);
  }

  /// Get today's requests
  Future<List<DailyPurchaseRequestEntry>> getTodayRequests() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(dailyPurchaseRequests)
          ..where((r) => r.date.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }

  /// Update the quantity of a request
  Future<void> updateQuantity(String requestId, double newQuantity) async {
    await (update(dailyPurchaseRequests)..where((r) => r.id.equals(requestId)))
        .write(DailyPurchaseRequestsCompanion(
      requestedQuantity: Value(newQuantity),
    ));
  }

  /// Delete a request by ID
  Future<void> deleteRequest(String requestId) async {
    await (delete(dailyPurchaseRequests)..where((r) => r.id.equals(requestId)))
        .go();
  }

  /// Clear all today's requests
  Future<void> clearTodayRequests() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    await (delete(dailyPurchaseRequests)
          ..where((r) => r.date.isBetweenValues(startOfDay, endOfDay)))
        .go();
  }

  /// Delete old requests (older than daysToKeep)
  Future<void> deleteOldRequests({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await (delete(dailyPurchaseRequests)
          ..where((r) => r.date.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// Get count of auto-added requests for today
  Future<int> getTodayAutoRequestsCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final count = await (select(dailyPurchaseRequests)
          ..where((r) =>
              r.autoAdded.equals(true) &
              r.date.isBetweenValues(startOfDay, endOfDay)))
        .get();

    return count.length;
  }

  /// Get statistics for today's requests
  Future<Map<String, dynamic>> getRequestsStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final requests = await (select(dailyPurchaseRequests)
          ..where((r) => r.date.isBetweenValues(startOfDay, endOfDay)))
        .get();

    final autoCount = requests.where((r) => r.autoAdded).length;
    final manualCount = requests.where((r) => !r.autoAdded).length;
    final totalQuantity = requests.fold<double>(
      0,
      (sum, r) => sum + r.requestedQuantity,
    );

    return {
      'total': requests.length,
      'auto': autoCount,
      'manual': manualCount,
      'totalQuantity': totalQuantity,
    };
  }
}
