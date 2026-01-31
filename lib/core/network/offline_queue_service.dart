// lib/core/network/offline_queue_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/hive_storage.dart';

/// أنواع العمليات المخزنة
enum QueueOperationType {
  sale, // عملية بيع
  stockUpdate, // تحديث مخزون
  productAdd, // إضافة منتج
  productUpdate, // تحديث منتج
}

/// عملية مخزنة في الـ Queue
class QueuedOperation {
  final String id;
  final QueueOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) =>
      QueuedOperation(
        id: json['id'] as String,
        type:
            QueueOperationType.values.firstWhere((t) => t.name == json['type']),
        data: json['data'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

/// خدمة تخزين العمليات عند انقطاع الاتصال
class OfflineQueueService {
  static const String _queueKey = 'larapill_offline_queue';
  static const int _maxRetries = 3;

  final List<QueuedOperation> _queue = [];
  bool _isProcessing = false;

  /// الحصول على عدد العمليات المعلقة
  int get pendingCount => _queue.length;

  /// هل يوجد عمليات معلقة؟
  bool get hasPendingOperations => _queue.isNotEmpty;

  /// تحميل الـ Queue من التخزين
  void loadQueue() {
    try {
      final queueJson = HiveStorage.getCache<String>(_queueKey);

      if (queueJson != null) {
        final List<dynamic> queueList = jsonDecode(queueJson);
        _queue.clear();
        _queue.addAll(queueList.map(
            (item) => QueuedOperation.fromJson(item as Map<String, dynamic>)));
        if (kDebugMode) {
          debugPrint('📥 تم تحميل ${_queue.length} عملية من الـ Queue');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ خطأ في تحميل الـ Queue: $e');
    }
  }

  /// حفظ الـ Queue في التخزين
  Future<void> _saveQueue() async {
    try {
      final queueJson = jsonEncode(_queue.map((op) => op.toJson()).toList());
      await HiveStorage.setCache(_queueKey, queueJson);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ خطأ في حفظ الـ Queue: $e');
    }
  }

  /// إضافة عملية بيع للـ Queue
  Future<void> addSaleOperation(
      Map<String, dynamic> saleData, List<Map<String, dynamic>> items) async {
    final operation = QueuedOperation(
      id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
      type: QueueOperationType.sale,
      data: {
        'sale': saleData,
        'items': items,
      },
      createdAt: DateTime.now(),
    );

    _queue.add(operation);
    await _saveQueue();

    if (kDebugMode) {
      debugPrint('📦 تمت إضافة عملية بيع للـ Queue: ${operation.id}');
    }
  }

  /// إضافة عملية تحديث مخزون للـ Queue
  Future<void> addStockUpdateOperation(
      String productId, double quantity, String operation) async {
    final op = QueuedOperation(
      id: 'stock_${DateTime.now().millisecondsSinceEpoch}',
      type: QueueOperationType.stockUpdate,
      data: {
        'product_id': productId,
        'quantity': quantity,
        'operation': operation,
      },
      createdAt: DateTime.now(),
    );

    _queue.add(op);
    await _saveQueue();
  }

  /// إضافة عملية منتج للـ Queue
  Future<void> addProductOperation(Map<String, dynamic> productData,
      {bool isUpdate = false}) async {
    final operation = QueuedOperation(
      id: 'product_${DateTime.now().millisecondsSinceEpoch}',
      type: isUpdate
          ? QueueOperationType.productUpdate
          : QueueOperationType.productAdd,
      data: productData,
      createdAt: DateTime.now(),
    );

    _queue.add(operation);
    await _saveQueue();
  }

  /// معالجة الـ Queue (تنفيذ العمليات المعلقة)
  Future<int> processQueue(
      Future<bool> Function(QueuedOperation) processor) async {
    if (_isProcessing || _queue.isEmpty) return 0;

    _isProcessing = true;
    int successCount = 0;
    final List<QueuedOperation> toRemove = [];

    try {
      for (final operation in _queue) {
        try {
          final success = await processor(operation);

          if (success) {
            toRemove.add(operation);
            successCount++;
            if (kDebugMode) {
              debugPrint('✅ تم تنفيذ العملية: ${operation.id}');
            }
          } else {
            operation.retryCount++;
            if (operation.retryCount >= _maxRetries) {
              toRemove.add(operation);
              if (kDebugMode) {
                debugPrint('❌ فشل نهائي للعملية: ${operation.id}');
              }
            }
          }
        } catch (e) {
          operation.retryCount++;
          if (kDebugMode) {
            debugPrint('⚠️ خطأ في العملية ${operation.id}: $e');
          }
        }
      }

      // إزالة العمليات المكتملة/الفاشلة
      _queue.removeWhere((op) => toRemove.contains(op));
      await _saveQueue();
    } finally {
      _isProcessing = false;
    }

    return successCount;
  }

  /// مسح الـ Queue
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
  }

  /// الحصول على قائمة العمليات المعلقة
  List<QueuedOperation> getPendingOperations() => List.unmodifiable(_queue);
}
