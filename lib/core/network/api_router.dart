// lib/core/network/api_router.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../database/database_helper.dart';

/// معالج الـ API endpoints في السيرفر
class ApiRouter {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// معالجة الطلب وإرجاع النتيجة
  Future<Map<String, dynamic>> handleRequest(
    String method,
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      // تقسيم المسار
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();

      if (segments.isEmpty || segments.first != 'api') {
        return _error('Invalid API path', HttpStatus.badRequest);
      }

      // إزالة 'api' من البداية
      segments.removeAt(0);

      if (segments.isEmpty) {
        return _success({'message': 'API is running', 'version': '1.0'});
      }

      final resource = segments.first;
      final resourceId = segments.length > 1 ? segments[1] : null;
      final action = segments.length > 2 ? segments[2] : null;

      switch (resource) {
        case 'products':
          return await _handleProducts(method, resourceId, action, data);
        case 'sales':
          return await _handleSales(method, resourceId, action, data);
        case 'inventory':
          return await _handleInventory(method, action, data);
        case 'sync':
          return await _handleSync(method, action, data);
        case 'ping':
        case 'test':
          return _success({
            'message': 'pong',
            'serverTime': DateTime.now().toIso8601String()
          });
        case 'status':
          return await _getServerStatus();
        default:
          return _error('Unknown resource: $resource', HttpStatus.notFound);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ API Error: $e\n$stack');
      }
      return _error(e.toString(), HttpStatus.internalServerError);
    }
  }

  // ==================== Products API ====================

  Future<Map<String, dynamic>> _handleProducts(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> data,
  ) async {
    final db = await _dbHelper.database;

    switch (method) {
      case 'GET':
        if (id != null) {
          // جلب منتج معين
          final product =
              await db.query('products', where: 'id = ?', whereArgs: [id]);
          if (product.isEmpty) {
            return _error('Product not found', HttpStatus.notFound);
          }
          // جلب الوحدات
          final units = await db
              .query('product_units', where: 'product_id = ?', whereArgs: [id]);
          return _success({
            'product': product.first,
            'units': units,
          });
        } else {
          // جلب كل المنتجات
          final products = await db.query('products', where: 'is_active = 1');
          return _success({'products': products, 'count': products.length});
        }

      case 'POST':
        if (action == 'search') {
          // بحث في المنتجات
          final query = data['query'] as String? ?? '';
          final products = await db.rawQuery('''
            SELECT * FROM products 
            WHERE is_active = 1 AND (
              name LIKE ? OR 
              scientific_name LIKE ? OR 
              barcode LIKE ? OR
              company LIKE ?
            )
            LIMIT 50
          ''', ['%$query%', '%$query%', '%$query%', '%$query%']);
          return _success({'products': products, 'count': products.length});
        } else if (action == 'barcode') {
          // بحث بالباركود
          final barcode = data['barcode'] as String?;
          if (barcode == null) {
            return _error('Barcode required', HttpStatus.badRequest);
          }
          final products = await db.query('products',
              where: 'barcode = ? AND is_active = 1', whereArgs: [barcode]);
          if (products.isEmpty) {
            return _error('Product not found', HttpStatus.notFound);
          }
          final units = await db.query('product_units',
              where: 'product_id = ?', whereArgs: [products.first['id']]);
          return _success({'product': products.first, 'units': units});
        } else {
          // إضافة منتج جديد
          if (!data.containsKey('id')) {
            return _error('Product data required', HttpStatus.badRequest);
          }
          await db.insert('products', data);
          return _success({'message': 'Product created', 'id': data['id']});
        }

      case 'PUT':
        if (id == null) {
          return _error('Product ID required', HttpStatus.badRequest);
        }
        await db.update('products', data, where: 'id = ?', whereArgs: [id]);
        return _success({'message': 'Product updated', 'id': id});

      case 'DELETE':
        if (id == null) {
          return _error('Product ID required', HttpStatus.badRequest);
        }
        // Soft delete
        await db.update('products', {'is_active': 0},
            where: 'id = ?', whereArgs: [id]);
        return _success({'message': 'Product deleted', 'id': id});

      default:
        return _error('Method not allowed', HttpStatus.methodNotAllowed);
    }
  }

  // ==================== Sales API ====================

  Future<Map<String, dynamic>> _handleSales(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> data,
  ) async {
    final db = await _dbHelper.database;

    switch (method) {
      case 'GET':
        if (action == 'today') {
          // مبيعات اليوم
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final sales = await db.rawQuery('''
            SELECT * FROM sales 
            WHERE date LIKE ? 
            ORDER BY created_at DESC
          ''', ['$today%']);

          // حساب الإجمالي
          double total = 0;
          for (var sale in sales) {
            total += (sale['total'] as num?)?.toDouble() ?? 0;
          }

          return _success({
            'sales': sales,
            'count': sales.length,
            'total': total,
            'date': today,
          });
        } else if (id != null) {
          // جلب مبيعة معينة مع عناصرها
          final sale =
              await db.query('sales', where: 'id = ?', whereArgs: [id]);
          if (sale.isEmpty) {
            return _error('Sale not found', HttpStatus.notFound);
          }
          final items = await db
              .query('sale_items', where: 'sale_id = ?', whereArgs: [id]);
          return _success({'sale': sale.first, 'items': items});
        } else {
          // جلب المبيعات الأخيرة (100)
          final sales =
              await db.query('sales', orderBy: 'created_at DESC', limit: 100);
          return _success({'sales': sales, 'count': sales.length});
        }

      case 'POST':
        // إضافة مبيعة جديدة
        if (!data.containsKey('sale') || !data.containsKey('items')) {
          return _error('Sale and items required', HttpStatus.badRequest);
        }

        final saleData = data['sale'] as Map<String, dynamic>;
        final itemsData = data['items'] as List;

        await db.transaction((txn) async {
          // إدراج المبيعة
          await txn.insert('sales', saleData);

          // إدراج العناصر وتحديث المخزون
          for (var item in itemsData) {
            final itemMap = item as Map<String, dynamic>;
            await txn.insert('sale_items', itemMap);

            // تحديث المخزون
            final productId = itemMap['product_id'];
            final quantity = (itemMap['quantity'] as num).toDouble();
            await txn.rawUpdate('''
              UPDATE products 
              SET current_stock = current_stock - ?,
                  updated_at = ?
              WHERE id = ?
            ''', [quantity, DateTime.now().toIso8601String(), productId]);
          }
        });

        return _success({
          'message': 'Sale created',
          'id': saleData['id'],
          'invoice_number': saleData['invoice_number'],
        });

      default:
        return _error('Method not allowed', HttpStatus.methodNotAllowed);
    }
  }

  // ==================== Inventory API ====================

  Future<Map<String, dynamic>> _handleInventory(
    String method,
    String? action,
    Map<String, dynamic> data,
  ) async {
    final db = await _dbHelper.database;

    if (method != 'POST') {
      return _error('Method not allowed', HttpStatus.methodNotAllowed);
    }

    switch (action) {
      case 'update':
        // تحديث المخزون
        final productId = data['product_id'] as String?;
        final quantity = data['quantity'] as num?;
        final operation =
            data['operation'] as String? ?? 'set'; // set, add, subtract

        if (productId == null || quantity == null) {
          return _error(
              'product_id and quantity required', HttpStatus.badRequest);
        }

        switch (operation) {
          case 'add':
            await db.rawUpdate('''
              UPDATE products SET current_stock = current_stock + ?, updated_at = ? WHERE id = ?
            ''', [quantity, DateTime.now().toIso8601String(), productId]);
          case 'subtract':
            await db.rawUpdate('''
              UPDATE products SET current_stock = current_stock - ?, updated_at = ? WHERE id = ?
            ''', [quantity, DateTime.now().toIso8601String(), productId]);
          default:
            await db.update(
                'products',
                {
                  'current_stock': quantity,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [productId]);
        }

        return _success({'message': 'Stock updated', 'product_id': productId});

      case 'check':
        // فحص المخزون المنخفض
        // threshold للمستقبل
        final lowStock = await db.rawQuery('''
          SELECT * FROM products 
          WHERE is_active = 1 AND current_stock <= min_stock_level
          ORDER BY current_stock ASC
        ''');
        return _success({'products': lowStock, 'count': lowStock.length});

      default:
        return _error('Unknown action', HttpStatus.badRequest);
    }
  }

  // ==================== Sync API ====================

  Future<Map<String, dynamic>> _handleSync(
    String method,
    String? action,
    Map<String, dynamic> data,
  ) async {
    final db = await _dbHelper.database;

    switch (action) {
      case 'status':
        return await _getServerStatus();

      case 'products':
        // مزامنة المنتجات - جلب المنتجات المحدثة منذ تاريخ معين
        final since = data['since'] as String?;
        List<Map<String, dynamic>> products;

        if (since != null) {
          products = await db.rawQuery('''
            SELECT * FROM products WHERE updated_at > ? ORDER BY updated_at ASC
          ''', [since]);
        } else {
          products = await db.query('products', orderBy: 'updated_at ASC');
        }

        return _success({
          'products': products,
          'count': products.length,
          'syncTime': DateTime.now().toIso8601String(),
        });

      case 'full':
        // مزامنة كاملة - جلب كل البيانات
        final products = await db.query('products');
        final units = await db.query('product_units');
        final settings = await db.query('pharmacy_settings');

        return _success({
          'products': products,
          'product_units': units,
          'pharmacy_settings': settings,
          'syncTime': DateTime.now().toIso8601String(),
        });

      default:
        return _error('Unknown sync action', HttpStatus.badRequest);
    }
  }

  // ==================== Helpers ====================

  Future<Map<String, dynamic>> _getServerStatus() async {
    final db = await _dbHelper.database;

    final productsCount = (await db.rawQuery(
            'SELECT COUNT(*) as count FROM products WHERE is_active = 1'))
        .first['count'];
    final salesToday = (await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as total 
      FROM sales WHERE date LIKE ?
    ''', ['${DateTime.now().toIso8601String().substring(0, 10)}%'])).first;

    return _success({
      'status': 'online',
      'serverTime': DateTime.now().toIso8601String(),
      'stats': {
        'products': productsCount,
        'salesToday': salesToday['count'],
        'totalToday': salesToday['total'],
      },
    });
  }

  Map<String, dynamic> _success(Map<String, dynamic> data) {
    return {
      'success': true,
      ...data,
    };
  }

  Map<String, dynamic> _error(String message, int statusCode) {
    return {
      'success': false,
      'error': message,
      'statusCode': statusCode,
    };
  }
}
