// lib/core/network/remote_database_service.dart
import 'package:flutter/foundation.dart';
import 'http_client_service.dart';

/// خدمة للتواصل مع قاعدة بيانات السيرفر عن بعد
/// تُستخدم في الكلاينت للقراءة/الكتابة على السيرفر
class RemoteDatabaseService {
  final HttpClientService _client;

  RemoteDatabaseService(this._client);

  /// هل متصل بالسيرفر؟
  bool get isConnected => _client.isConnected;

  // ==================== Products ====================

  /// جلب كل المنتجات
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _client.fetchData('/api/products');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['products'] ?? []);
    }
    throw Exception(response['error'] ?? 'Failed to get products');
  }

  /// جلب منتج بالـ ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final response = await _client.fetchData('/api/products/$id');
      if (response['success'] == true) {
        return response['product'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getProductById error: $e');
      return null;
    }
  }

  /// جلب منتج بالباركود
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response =
          await _client.sendData('/api/products/barcode', {'barcode': barcode});
      if (response['success'] == true) {
        return {
          'product': response['product'],
          'units': response['units'],
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getProductByBarcode error: $e');
      return null;
    }
  }

  /// بحث في المنتجات
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final response =
        await _client.sendData('/api/products/search', {'query': query});
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['products'] ?? []);
    }
    return [];
  }

  /// إضافة منتج
  Future<bool> insertProduct(Map<String, dynamic> product) async {
    try {
      final response = await _client.sendData('/api/products', product);
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ insertProduct error: $e');
      return false;
    }
  }

  /// تحديث منتج
  Future<bool> updateProduct(String id, Map<String, dynamic> product) async {
    try {
      // PUT ليس مدعوم مباشرة، نستخدم POST مع action
      final response = await _client.sendData('/api/products/$id', {
        ...product,
        '_method': 'PUT',
      });
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateProduct error: $e');
      return false;
    }
  }

  // ==================== Sales ====================

  /// جلب مبيعات اليوم
  Future<Map<String, dynamic>> getTodaySales() async {
    final response = await _client.fetchData('/api/sales/today');
    if (response['success'] == true) {
      return {
        'sales': List<Map<String, dynamic>>.from(response['sales'] ?? []),
        'count': response['count'] ?? 0,
        'total': response['total'] ?? 0.0,
      };
    }
    throw Exception(response['error'] ?? 'Failed to get sales');
  }

  /// جلب مبيعة بالـ ID
  Future<Map<String, dynamic>?> getSaleById(String id) async {
    try {
      final response = await _client.fetchData('/api/sales/$id');
      if (response['success'] == true) {
        return {
          'sale': response['sale'],
          'items': response['items'],
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getSaleById error: $e');
      return null;
    }
  }

  /// إضافة مبيعة جديدة
  Future<Map<String, dynamic>> createSale({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.sendData('/api/sales', {
      'sale': sale,
      'items': items,
    });

    if (response['success'] == true) {
      return {
        'success': true,
        'id': response['id'],
        'invoice_number': response['invoice_number'],
      };
    }

    return {
      'success': false,
      'error': response['error'] ?? 'Failed to create sale',
    };
  }

  // ==================== Inventory ====================

  /// تحديث المخزون
  Future<bool> updateStock({
    required String productId,
    required double quantity,
    String operation = 'set', // set, add, subtract
  }) async {
    try {
      final response = await _client.sendData('/api/inventory/update', {
        'product_id': productId,
        'quantity': quantity,
        'operation': operation,
      });
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateStock error: $e');
      return false;
    }
  }

  /// جلب المنتجات منخفضة المخزون
  Future<List<Map<String, dynamic>>> getLowStockProducts(
      {int threshold = 10}) async {
    final response = await _client
        .sendData('/api/inventory/check', {'threshold': threshold});
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['products'] ?? []);
    }
    return [];
  }

  // ==================== Sync ====================

  /// جلب حالة السيرفر
  Future<Map<String, dynamic>> getServerStatus() async {
    return await _client.fetchData('/api/status');
  }

  /// مزامنة المنتجات منذ تاريخ معين
  Future<List<Map<String, dynamic>>> syncProducts({String? since}) async {
    final response = await _client.sendData('/api/sync/products', {
      if (since != null) 'since': since,
    });
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['products'] ?? []);
    }
    return [];
  }

  /// مزامنة كاملة
  Future<Map<String, dynamic>> fullSync() async {
    return await _client.sendData('/api/sync/full', {});
  }

  /// اختبار الاتصال
  Future<bool> ping() async {
    return await _client.ping();
  }
}
