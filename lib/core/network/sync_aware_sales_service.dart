// lib/core/network/sync_aware_sales_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_database_service.dart';
import 'offline_queue_service.dart';
import '../../features/pos/data/repositories/sales_service.dart';
import '../../features/pos/domain/entities/sale.dart';
import '../../features/network/presentation/providers/lan_providers.dart';

/// خدمة المبيعات المتزامنة - تدعم العمل الـحلي والبعيد
class SyncAwareSalesService {
  final Ref _ref;
  final SalesService _localService = SalesService.instance;
  final OfflineQueueService _offlineQueue = OfflineQueueService();

  SyncAwareSalesService(this._ref);

  bool get _useRemote => _ref.read(shouldUseRemoteDatabaseProvider);
  bool get _isConnected => _ref.read(clientConnectedProvider);
  RemoteDatabaseService get _remoteDb => _ref.read(remoteDatabaseProvider);

  /// حفظ البيع - يدعم الوضع المحلي والبعيد والـ Offline
  Future<void> saveSale(Sale sale, {String? userId, String? userName}) async {
    if (_useRemote) {
      // كلاينت متصل
      if (_isConnected) {
        try {
          await _saveToRemote(sale);
          // ✅ تشغيل فحص النواقص بعد الحفظ في السيرفر
          await _localService.checkAndAddOutOfStockFromSale(sale);
          if (kDebugMode) {
            debugPrint('✅ تم حفظ البيع في السيرفر: ${sale.id}');
          }
        } catch (e) {
          // فشل الإرسال - خزّن في الـ Queue
          if (kDebugMode) {
            debugPrint('⚠️ فشل إرسال البيع للسيرفر، تخزين محلي: $e');
          }
          await _saveToQueueAndLocal(sale, userId: userId, userName: userName);
        }
      } else {
        // كلاينت غير متصل - خزّن محلياً وفي الـ Queue
        await _saveToQueueAndLocal(sale, userId: userId, userName: userName);
      }
    } else {
      // سيرفر أو وضع منفصل - حفظ محلي
      await _localService.saveSale(sale, userId: userId, userName: userName);
    }
  }

  /// حفظ البيع في السيرفر
  Future<void> _saveToRemote(Sale sale) async {
    final saleMap = {
      'id': sale.id,
      'date': sale.date.toIso8601String(),
      'subtotal': sale.subtotal,
      'discount': sale.discount,
      'tax': sale.tax,
      'total': sale.total,
      'paid_amount': sale.paidAmount,
      'remaining_amount': sale.remainingAmount,
      'payment_status': sale.paymentStatus.name,
      'payment_method': sale.paymentMethod.name,
      'customer_name': sale.customerName,
      'customer_phone': sale.customerPhone,
      'cashier_id': sale.cashierId,
      'cashier_name': sale.cashierName,
      'status': sale.status.name,
      'created_at': sale.createdAt.toIso8601String(),
    };

    final itemsList = sale.items
        .map((item) => {
              'id': item.id,
              'sale_id': sale.id,
              'product_id': item.productId,
              'product_name': item.productName,
              'unit': item.unit.name,
              'unit_price': item.unitPrice,
              'quantity': item.quantity,
              'total': item.total,
            })
        .toList();

    final result = await _remoteDb.createSale(sale: saleMap, items: itemsList);

    if (result['success'] != true) {
      throw Exception(result['error'] ?? 'Failed to save sale');
    }
  }

  /// حفظ في الـ Queue والمحلي
  Future<void> _saveToQueueAndLocal(Sale sale,
      {String? userId, String? userName}) async {
    // حفظ محلياً
    await _localService.saveSale(sale, userId: userId, userName: userName);

    // إضافة للـ Queue لإرسالها لاحقاً
    final saleMap = {
      'id': sale.id,
      'date': sale.date.toIso8601String(),
      'subtotal': sale.subtotal,
      'discount': sale.discount,
      'tax': sale.tax,
      'total': sale.total,
      'paid_amount': sale.paidAmount,
      'remaining_amount': sale.remainingAmount,
      'payment_status': sale.paymentStatus.name,
      'payment_method': sale.paymentMethod.name,
      'customer_name': sale.customerName,
      'customer_phone': sale.customerPhone,
      'cashier_id': sale.cashierId,
      'cashier_name': sale.cashierName,
      'status': sale.status.name,
      'created_at': sale.createdAt.toIso8601String(),
    };

    final itemsList = sale.items
        .map((item) => {
              'id': item.id,
              'sale_id': sale.id,
              'product_id': item.productId,
              'product_name': item.productName,
              'unit': item.unit.name,
              'unit_price': item.unitPrice,
              'quantity': item.quantity,
              'total': item.total,
            })
        .toList();

    await _offlineQueue.addSaleOperation(saleMap, itemsList);

    if (kDebugMode) {
      debugPrint('📦 تم تخزين البيع في الـ Queue: ${sale.id}');
    }
  }

  /// معالجة الـ Queue عند استعادة الاتصال
  Future<int> processOfflineQueue() async {
    if (!_isConnected) return 0;

    _offlineQueue.loadQueue();

    return await _offlineQueue.processQueue((operation) async {
      try {
        switch (operation.type) {
          case QueueOperationType.sale:
            final saleData = operation.data['sale'] as Map<String, dynamic>;
            final items = (operation.data['items'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();

            final result =
                await _remoteDb.createSale(sale: saleData, items: items);
            return result['success'] == true;

          case QueueOperationType.stockUpdate:
            final productId = operation.data['product_id'] as String;
            final quantity = (operation.data['quantity'] as num).toDouble();
            final op = operation.data['operation'] as String;

            return await _remoteDb.updateStock(
              productId: productId,
              quantity: quantity,
              operation: op,
            );

          default:
            return false;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ خطأ في معالجة العملية: $e');
        }
        return false;
      }
    });
  }

  /// جلب مبيعات اليوم
  Future<Map<String, dynamic>> getTodaySales() async {
    if (_useRemote && _isConnected) {
      try {
        return await _remoteDb.getTodaySales();
      } catch (e) {
        // Fallback to local
      }
    }

    final revenue = await _localService.getTodayRevenue();
    final count = await _localService.getTodaySalesCount();
    return {
      'total': revenue,
      'count': count,
    };
  }

  /// عدد العمليات المعلقة
  int get pendingOperationsCount => _offlineQueue.pendingCount;
}

// ==================== Provider ====================

/// Provider لـ Sync-Aware Sales Service
final syncAwareSalesServiceProvider = Provider<SyncAwareSalesService>((ref) {
  return SyncAwareSalesService(ref);
});
