import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../models/daily_purchase_request.dart';
import '../../../database/daos/daily_purchase_request_dao.dart';

/// Provider لـ DAO
final dailyPurchaseRequestDaoProvider =
    Provider<DailyPurchaseRequestDao>((ref) {
  return DailyPurchaseRequestDao();
});

/// Provider لقائمة طلبيات اليوم
final todayPurchaseRequestsProvider =
    FutureProvider.autoDispose<List<DailyPurchaseRequest>>((ref) async {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  return await dao.getTodayRequests();
});

/// Provider لعدد النواقص (للـ Badge)
final outOfStockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  return await dao.getTodayAutoRequestsCount();
});

/// Provider لإحصائيات الطلبية
final purchaseRequestsStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  return await dao.getRequestsStats();
});

/// StateNotifier لإدارة الطلبيات
class DailyPurchaseNotifier
    extends StateNotifier<AsyncValue<List<DailyPurchaseRequest>>> {
  final DailyPurchaseRequestDao dao;
  final Ref ref;

  DailyPurchaseNotifier(this.dao, this.ref)
      : super(const AsyncValue.loading()) {
    _loadRequests();
  }

  /// تحميل الطلبيات
  Future<void> _loadRequests() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final requests = await dao.getTodayRequests();
      if (!mounted) return;
      state = AsyncValue.data(requests);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
      developer.log('❌ خطأ في تحميل الطلبيات: $e',
          name: 'DailyPurchaseNotifier');
    }
  }

  /// إعادة تحميل
  Future<void> refresh() async {
    await _loadRequests();
  }

  /// إضافة منتج يدوياً
  Future<void> addManualRequest({
    required String productId,
    required String productName,
    required double quantity,
    String? unit, // إضافة حقل الوحدة (اختياري)
  }) async {
    try {
      // التحقق من عدم وجود المنتج مسبقاً
      final exists = await dao.isProductInTodayRequest(productId);
      if (exists) {
        throw Exception('المنتج موجود في الطلبية بالفعل');
      }

      final request = DailyPurchaseRequest(
        id: const Uuid().v4(),
        productId: productId,
        productName: productName, // الاسم فقط بدون الكمية
        requestedQuantity: quantity,
        unit: unit, // حفظ الوحدة بشكل منفصل
        autoAdded: false,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await dao.insertRequest(request);
      await refresh();

      final displayText = unit != null && unit.isNotEmpty
          ? '$productName - $quantity $unit'
          : '$productName - $quantity';
      developer.log('✅ تمت إضافة $displayText للطلبية',
          name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ خطأ في إضافة منتج: $e', name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// تحديث الكمية
  Future<void> updateQuantity(String requestId, double newQuantity) async {
    try {
      if (newQuantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر');
      }

      await dao.updateQuantity(requestId, newQuantity);
      await refresh();

      developer.log('✅ تم تحديث الكمية', name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ خطأ في تحديث الكمية: $e', name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// حذف منتج
  Future<void> deleteRequest(String requestId) async {
    try {
      await dao.deleteRequest(requestId);
      await refresh();

      developer.log('✅ تم حذف المنتج من الطلبية',
          name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ خطأ في حذف المنتج: $e', name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// مسح جميع الطلبيات
  Future<void> clearAll() async {
    try {
      await dao.clearTodayRequests();
      await refresh();

      developer.log('✅ تم مسح جميع الطلبيات', name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ خطأ في مسح الطلبيات: $e', name: 'DailyPurchaseNotifier');
      rethrow;
    }
  }

  /// حذف الطلبيات القديمة
  Future<void> cleanupOldRequests({int daysToKeep = 30}) async {
    try {
      await dao.deleteOldRequests(daysToKeep: daysToKeep);
      developer.log('✅ تم تنظيف الطلبيات القديمة',
          name: 'DailyPurchaseNotifier');
    } catch (e) {
      developer.log('❌ خطأ في تنظيف الطلبيات: $e',
          name: 'DailyPurchaseNotifier');
    }
  }
}

/// Provider للـ StateNotifier مع AutoDispose لمنع مشاكل الـ dispose
final dailyPurchaseNotifierProvider = StateNotifierProvider.autoDispose<
    DailyPurchaseNotifier, AsyncValue<List<DailyPurchaseRequest>>>((ref) {
  final dao = ref.watch(dailyPurchaseRequestDaoProvider);
  return DailyPurchaseNotifier(dao, ref);
});
