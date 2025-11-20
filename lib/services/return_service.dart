import 'dart:developer' as developer;
import '../database/database_helper.dart';
import '../models/return.dart';
import '../features/pos/models/sale.dart';

class ReturnService {
  static final ReturnService _instance = ReturnService._internal();
  factory ReturnService() => _instance;
  ReturnService._internal();

  final _dbHelper = DatabaseHelper();

  // إضافة مرتجع جديد
  Future<String> createReturn(Return returnData) async {
    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        // 1. إدراج بيانات المرتجع الرئيسية
        await txn.insert('returns', returnData.toMap());

        // 2. إدراج عناصر المرتجع
        for (final item in returnData.items) {
          final itemMap = item.toMap();
          itemMap['return_id'] = returnData.id; // إضافة return_id المطلوب
          await txn.insert('return_items', itemMap);

          // 3. تحديث المخزون - إعادة الكمية
          final product = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (product.isNotEmpty) {
            final currentStock =
                (product.first['current_stock'] as num).toDouble();

            // البحث عن معامل التحويل داخل نفس transaction
            final conversionResult = await txn.query(
              'product_units',
              columns: ['conversion_to_base'],
              where: 'product_id = ? AND unit = ?',
              whereArgs: [item.productId, item.unit.name],
            );

            final conversionRate = conversionResult.isNotEmpty
                ? (conversionResult.first['conversion_to_base'] as num)
                    .toDouble()
                : 1.0;

            final returnedQuantity = item.quantity * conversionRate;

            await txn.update(
              'products',
              {'current_stock': currentStock + returnedQuantity},
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }
        }

        // 4. تحديث حالة المبيعة إذا تم إرجاع كل العناصر
        final saleItems = await txn.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [returnData.saleId],
        );

        final returnedItems = await txn.query(
          'return_items r JOIN returns ret ON r.return_id = ret.id',
          where: 'ret.sale_id = ?',
          whereArgs: [returnData.saleId],
        );

        if (saleItems.length == returnedItems.length) {
          await txn.update(
            'sales',
            {'status': SaleStatus.returned.name},
            where: 'id = ?',
            whereArgs: [returnData.saleId],
          );
        }
      });

      developer.log('✅ تم حفظ المرتجع: ${returnData.id}',
          name: 'ReturnService');
      return returnData.id;
    } catch (e) {
      developer.log('❌ خطأ في حفظ المرتجع: $e', name: 'ReturnService');
      rethrow;
    }
  }

  // جلب مرتجع بواسطة المعرف
  Future<Return?> getReturnById(String id) async {
    final db = await _dbHelper.database;

    try {
      final returnData = await db.query(
        'returns',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (returnData.isEmpty) return null;

      final itemsData = await db.query(
        'return_items',
        where: 'return_id = ?',
        whereArgs: [id],
      );

      final items = itemsData.map((item) => ReturnItem.fromMap(item)).toList();
      final returnMap = returnData.first;

      final return_ = Return.fromMap(returnMap);
      return Return(
        id: return_.id,
        saleId: return_.saleId,
        returnDate: return_.returnDate,
        items: items,
        reason: return_.reason,
        status: return_.status,
        totalRefund: return_.totalRefund,
        refundMethod: return_.refundMethod,
        notes: return_.notes,
        processedBy: return_.processedBy,
        createdAt: return_.createdAt,
      );
    } catch (e) {
      developer.log('❌ خطأ في جلب المرتجع: $e', name: 'ReturnService');
      return null;
    }
  }

  // جلب جميع المرتجعات
  Future<List<Return>> getAllReturns() async {
    final db = await _dbHelper.database;

    try {
      final returnsData =
          await db.query('returns', orderBy: 'return_date DESC');
      final returns = <Return>[];

      for (final returnMap in returnsData) {
        final itemsData = await db.query(
          'return_items',
          where: 'return_id = ?',
          whereArgs: [returnMap['id']],
        );

        final items =
            itemsData.map((item) => ReturnItem.fromMap(item)).toList();
        final return_ = Return.fromMap(returnMap);

        returns.add(Return(
          id: return_.id,
          saleId: return_.saleId,
          returnDate: return_.returnDate,
          items: items,
          reason: return_.reason,
          status: return_.status,
          totalRefund: return_.totalRefund,
          refundMethod: return_.refundMethod,
          notes: return_.notes,
          processedBy: return_.processedBy,
          createdAt: return_.createdAt,
        ));
      }

      return returns;
    } catch (e) {
      developer.log('❌ خطأ في جلب المرتجعات: $e', name: 'ReturnService');
      return [];
    }
  }

  // تحديث حالة المرتجع
  Future<bool> updateReturnStatus(
      String returnId, ReturnStatus newStatus) async {
    final db = await _dbHelper.database;

    try {
      await db.update(
        'returns',
        {'status': newStatus.name},
        where: 'id = ?',
        whereArgs: [returnId],
      );

      developer.log('✅ تم تحديث حالة المرتجع: $returnId',
          name: 'ReturnService');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في تحديث حالة المرتجع: $e', name: 'ReturnService');
      return false;
    }
  }
}
