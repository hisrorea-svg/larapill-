// lib/features/purchases/presentation/providers/daily_purchase_provider.dart
// Direct Drift providers - No wrappers!

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:developer' as developer;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/daily_purchase_request_drift_dao.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../data/models/daily_purchase_request.dart';

/// DAO Provider - directly using Drift
final dailyPurchaseRequestDaoProvider =
    Provider<DailyPurchaseRequestDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DailyPurchaseRequestDriftDao(db);
});

/// Convert Drift Entry to Model
DailyPurchaseRequest _entryToModel(DailyPurchaseRequestEntry entry) {
  return DailyPurchaseRequest(
    id: entry.id,
    productId: entry.productId,
    productName: entry.productName,
    requestedQuantity: entry.requestedQuantity,
    unit: entry.unit,
    autoAdded: entry.autoAdded,
    supplierName: entry.supplierName,
    date: entry.date,
    createdAt: entry.createdAt,
  );
}

/// Provider for today's purchase requests
final todayPurchaseRequestsProvider =
    FutureProvider.autoDispose<List<DailyPurchaseRequest>>((ref) async {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  final entries = await dao.getTodayRequests();
  return entries.map(_entryToModel).toList();
});

/// Provider for out-of-stock count badge
final outOfStockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  return await dao.getTodayAutoRequestsCount();
});

/// Provider for purchase request statistics
final purchaseRequestsStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  final allEntries = await dao.getTodayRequests();
  final autoCount = allEntries.where((e) => e.autoAdded).length;
  final manualCount = allEntries.where((e) => !e.autoAdded).length;

  return {
    'total': allEntries.length,
    'auto': autoCount,
    'manual': manualCount,
  };
});

/// StateNotifier for managing purchase requests
class DailyPurchaseNotifier
    extends StateNotifier<AsyncValue<List<DailyPurchaseRequest>>> {
  final DailyPurchaseRequestDriftDao dao;
  final Ref ref;

  DailyPurchaseNotifier(this.dao, this.ref)
      : super(const AsyncValue.loading()) {
    _loadRequests();
  }

  /// Load requests from Drift
  Future<void> _loadRequests() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final entries = await dao.getTodayRequests();
      final requests = entries.map(_entryToModel).toList();
      if (!mounted) return;
      state = AsyncValue.data(requests);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
      developer.log('❌ Error loading requests: $e',
          name: 'DailyPurchaseNotifier');
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadRequests();
  }

  /// Add manual product request
  Future<void> addManualRequest({
    required String productId,
    required String productName,
    required double quantity,
    String? unit,
  }) async {
    try {
      // Check if product already exists
      final exists = await dao.isProductInTodayRequest(productId);
      if (exists) {
        throw Exception('المنتج موجود في الطلبية بالفعل');
      }

      final now = DateTime.now();
      final companion = DailyPurchaseRequestsCompanion.insert(
        id: const Uuid().v4(),
        productId: productId,
        productName: productName,
        requestedQuantity: quantity,
        unit: Value(unit),
        autoAdded: const Value(false),
        supplierName: const Value.absent(),
        date: now,
        createdAt: now,
      );

      await dao.insertRequest(companion);
      await refresh();

      final displayText = unit != null && unit.isNotEmpty
          ? '$productName - $quantity $unit'
          : '$productName - $quantity';
      developer.log('✅ Added $displayText to request',
          name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ Error adding product: $e',
          name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// Update quantity
  Future<void> updateQuantity(String requestId, double newQuantity) async {
    try {
      if (newQuantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر');
      }

      await dao.updateQuantity(requestId, newQuantity);
      await refresh();

      developer.log('✅ Quantity updated', name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ Error updating quantity: $e',
          name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// Delete request
  Future<void> deleteRequest(String requestId) async {
    try {
      await dao.deleteRequest(requestId);
      await refresh();

      developer.log('✅ Product removed from request',
          name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ Error deleting product: $e',
          name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// Clear all requests
  Future<void> clearAll() async {
    try {
      await dao.clearTodayRequests();
      await refresh();

      developer.log('✅ All requests cleared', name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ Error clearing requests: $e',
          name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// Cleanup old requests
  Future<void> cleanupOldRequests({int daysToKeep = 30}) async {
    try {
      await dao.deleteOldRequests(daysToKeep: daysToKeep);
      developer.log('✅ Old requests cleaned up', name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ Error cleaning up requests: $e',
          name: 'DailyPurchaseNotifier');
    }
  }
}

/// Provider for StateNotifier with AutoDispose
final dailyPurchaseNotifierProvider = StateNotifierProvider.autoDispose<
    DailyPurchaseNotifier, AsyncValue<List<DailyPurchaseRequest>>>((ref) {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  return DailyPurchaseNotifier(dao, ref);
});
