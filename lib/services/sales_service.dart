import 'dart:async';
import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart' as sqflite;
import '../database/database_helper.dart';
import '../features/pos/models/sale.dart';
import '../models/medicine_unit.dart';
import '../database/daos/product_dao.dart';
import '../database/daos/customer_debt_dao.dart';
import '../database/daos/daily_purchase_request_dao.dart';
import '../features/purchases/models/daily_purchase_request.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/services/audit_logger.dart';
import '../core/utils/input_sanitizer.dart';
import 'package:uuid/uuid.dart';

class SalesService {
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();

  static SalesService get instance => _instance;

  final _dbHelper = DatabaseHelper();
  final _productDao = ProductDAO();
  final _customerDebtDao = CustomerDebtDAO();
  // TODO: Replace with new sync module when fully integrated
  // final _syncQueueService = SyncQueueService();

  /// حفظ البيع وتحديث المخزون - محسّن مع معالجة أخطاء احترافية ⚡
  Future<String> saveSale(Sale sale, {String? userId, String? userName}) async {
    final stopwatch = Stopwatch()..start();

    try {
      // ✅ 1. التحقق من صحة البيانات
      if (sale.items.isEmpty) {
        throw ValidationException(
          'لا يمكن حفظ بيع فارغ',
          userMessage: 'يجب إضافة منتج واحد على الأقل للبيع',
        );
      }

      if (sale.total <= 0) {
        throw ValidationException(
          'المبلغ الإجمالي غير صحيح',
          userMessage: 'المبلغ الإجمالي يجب أن يكون أكبر من صفر',
        );
      }

      // ✅ 2. تنظيف بيانات العميل إن وجدت
      String? cleanCustomerName;
      String? cleanCustomerPhone;
      if (sale.customerName != null && sale.customerName!.isNotEmpty) {
        cleanCustomerName = InputSanitizer.sanitizeFullName(sale.customerName!);
        if (sale.customerPhone != null) {
          cleanCustomerPhone =
              InputSanitizer.sanitizePhoneNumber(sale.customerPhone!);
        }
      }

      final db = await _dbHelper.database;

      // ✅ 3. جلب كل المنتجات مرة واحدة قبل Transaction
      final productIds = sale.items.map((item) => item.productId).toSet();
      final productsMap = <String, dynamic>{};

      for (final productId in productIds) {
        final product = await _productDao.findById(productId).timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw DatabaseTimeoutException(
                'انتهت مهلة جلب بيانات المنتج',
                timeout: const Duration(seconds: 5),
              ),
            );

        if (product == null) {
          throw NotFoundException(
            'المنتج غير موجود: $productId',
            entityType: 'product',
            entityId: productId,
            userMessage: 'أحد المنتجات غير موجود في قاعدة البيانات',
          );
        }
        productsMap[productId] = product;
      }

      // ✅ 4. فحص المخزون قبل البدء
      for (final item in sale.items) {
        final product = productsMap[item.productId];
        if (product != null) {
          final unitInfo = product.unitInfo[item.unit];
          if (unitInfo == null) {
            throw ValidationException(
              'معلومات الوحدة غير موجودة',
              userMessage:
                  'وحدة "${item.unit.arabicName}" غير متوفرة للمنتج "${item.productName}"',
            );
          }

          final baseQuantity = item.quantity * unitInfo.conversionToBase;
          if (product.currentStock < baseQuantity) {
            throw InsufficientStockException(
              productId: item.productId,
              productName: item.productName,
              available: product.currentStock / unitInfo.conversionToBase,
              requested: item.quantity,
            );
          }
        }
      }

      // ✅ 5. Transaction مع timeout محدد
      await db.transaction((txn) async {
        // حفظ البيع
        await txn.insert('sales', {
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
          'customer_name': cleanCustomerName,
          'customer_phone': cleanCustomerPhone,
          'cashier_id': sale.cashierId,
          'cashier_name': sale.cashierName,
          'status': sale.status.name,
          'created_at': sale.createdAt.toIso8601String(),
        });

        // Batch insert لعناصر البيع
        final batch = txn.batch();

        for (final item in sale.items) {
          batch.insert('sale_items', {
            'id': item.id,
            'sale_id': sale.id,
            'product_id': item.productId,
            'product_name':
                InputSanitizer.sanitizeProductName(item.productName),
            'unit': item.unit.name,
            'unit_price': item.unitPrice,
            'quantity': item.quantity,
            'total': item.total,
          });

          // تحديث المخزون
          final product = productsMap[item.productId];
          if (product != null) {
            final unitInfo = product.unitInfo[item.unit];
            if (unitInfo != null) {
              final baseQuantity = item.quantity * unitInfo.conversionToBase;
              final newStock = product.currentStock - baseQuantity;

              batch.update(
                'products',
                {'current_stock': newStock},
                where: 'id = ?',
                whereArgs: [item.productId],
              );
            }
          }
        }

        await batch.commit(noResult: true);
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw DatabaseTimeoutException(
          'انتهت مهلة حفظ البيع',
          timeout: const Duration(seconds: 30),
          userMessage: 'العملية استغرقت وقتاً طويلاً. يرجى المحاولة مرة أخرى.',
        ),
      );

      // 💰 6. حفظ الدين إذا كان هناك مبلغ متبقي
      if (sale.hasDebt &&
          cleanCustomerName != null &&
          cleanCustomerName.isNotEmpty) {
        await _customerDebtDao.upsertCustomerDebt(
          customerName: cleanCustomerName,
          customerPhone: cleanCustomerPhone,
          debtAmount: sale.remainingAmount,
          saleId: sale.id,
        );

        developer.log(
          '💰 تم تسجيل دين للعميل $cleanCustomerName: ${sale.remainingAmount} د.ع',
          name: 'SalesService',
        );
      }

      // 🛒 7. فحص النواقص وإضافتها تلقائياً لطلبية اليوم
      await _checkAndAddOutOfStock(productsMap, sale.items);

      // 📝 8. تسجيل في AuditLogger
      if (userId != null) {
        await AuditLogger().logSaleCreate(
          userId,
          userName ?? 'مستخدم غير معروف',
          sale.id,
          sale.total,
          customerName: cleanCustomerName,
          itemsCount: sale.items.length,
        );
      }

      // 🔄 9. إضافة المبيعة لقائمة المزامنة (Sync Queue)
      // TODO: Integrate with new sync module (features/sync)
      // The new sync module uses SyncLocalDataSource.enqueueSale()
      // For now, sync is disabled until integration is complete
      /*
      try {
        await _syncQueueService.enqueueSale(
          saleId: sale.id,
          saleData: sale.toMap(),
        );
        developer.log(
          '🔄 تم إضافة المبيعة للـ Sync Queue',
          name: 'SalesService',
        );
      } catch (syncError) {
        // لا نريد فشل حفظ البيع بسبب خطأ في الـ Sync Queue
        developer.log(
          '⚠️ فشل إضافة المبيعة للـ Sync Queue: $syncError',
          name: 'SalesService',
        );
      }
      */

      stopwatch.stop();
      developer.log(
        '✅ تم حفظ البيع بنجاح في ${stopwatch.elapsedMilliseconds}ms',
        name: 'SalesService',
      );

      return sale.id;
    } on AppException catch (e) {
      stopwatch.stop();
      developer.log(
        '❌ فشل حفظ البيع بعد ${stopwatch.elapsedMilliseconds}ms: ${e.message}',
        name: 'SalesService',
        error: e,
        stackTrace: e.stackTrace,
      );
      rethrow;
    } on sqflite.DatabaseException catch (e) {
      stopwatch.stop();
      developer.log(
        '❌ خطأ قاعدة بيانات في حفظ البيع: $e',
        name: 'SalesService',
        error: e,
      );
      throw DatabaseException(
        'فشل حفظ البيع في قاعدة البيانات',
        originalError: e,
        tableName: 'sales',
        operation: 'insert',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      developer.log(
        '❌ خطأ غير متوقع في حفظ البيع: $e',
        name: 'SalesService',
        error: e,
        stackTrace: stackTrace,
      );
      throw UnexpectedException(
        'حدث خطأ غير متوقع أثناء حفظ البيع',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// جلب جميع المبيعات
  Future<List<Sale>> getAllSales() async {
    final db = await _dbHelper.database;

    try {
      final salesData = await db.query(
        'sales',
        orderBy: 'created_at DESC', // ✅ created_at
      );

      final sales = <Sale>[];

      for (final saleMap in salesData) {
        final itemsData = await db.query(
          'sale_items', // ✅ sale_items
          where: 'sale_id = ?', // ✅ sale_id
          whereArgs: [saleMap['id']],
        );

        final items = itemsData.map((itemMap) {
          return SaleItem(
            id: itemMap['id'] as String,
            productId: itemMap['product_id'] as String, // ✅ product_id
            productName: itemMap['product_name'] as String, // ✅ product_name
            unit: MedicineUnit.values.firstWhere(
              (u) => u.name == itemMap['unit'],
            ),
            unitPrice:
                (itemMap['unit_price'] as num).toDouble(), // ✅ unit_price
            quantity: (itemMap['quantity'] as num).toDouble(),
            total: (itemMap['total'] as num).toDouble(),
          );
        }).toList();

        sales.add(Sale(
          id: saleMap['id'] as String,
          date: DateTime.parse(saleMap['date'] as String),
          items: items,
          subtotal: (saleMap['subtotal'] as num).toDouble(),
          discount: (saleMap['discount'] as num).toDouble(),
          tax: (saleMap['tax'] as num).toDouble(),
          total: (saleMap['total'] as num).toDouble(),
          paidAmount: (saleMap['paid_amount'] as num?)?.toDouble() ??
              (saleMap['total'] as num).toDouble(),
          remainingAmount:
              (saleMap['remaining_amount'] as num?)?.toDouble() ?? 0.0,
          paymentStatus: PaymentStatus.values.firstWhere(
            (p) => p.name == (saleMap['payment_status'] ?? 'paid'),
            orElse: () => PaymentStatus.paid,
          ),
          paymentMethod: PaymentMethod.values.firstWhere(
            (p) => p.name == saleMap['payment_method'], // ✅ payment_method
          ),
          customerName: saleMap['customer_name'] as String?, // ✅ customer_name
          customerPhone:
              saleMap['customer_phone'] as String?, // ✅ customer_phone
          cashierId:
              saleMap['cashier_id'] as String? ?? 'unknown', // ✅ cashier_id
          cashierName:
              saleMap['cashier_name'] as String? ?? '', // ✅ cashier_name
          status: SaleStatus.values.firstWhere(
            (s) => s.name == saleMap['status'],
          ),
          createdAt:
              DateTime.parse(saleMap['created_at'] as String), // ✅ created_at
        ));
      }

      return sales;
    } catch (e) {
      developer.log('❌ خطأ في جلب المبيعات: $e', name: 'SalesService');
      return [];
    }
  }

  /// جلب بيع محدد
  Future<Sale?> getSaleById(String id) async {
    final db = await _dbHelper.database;

    try {
      final salesData = await db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (salesData.isEmpty) return null;

      final saleMap = salesData.first;

      final itemsData = await db.query(
        'sale_items', // ✅ sale_items
        where: 'sale_id = ?', // ✅ sale_id
        whereArgs: [id],
      );

      final items = itemsData.map((itemMap) {
        return SaleItem(
          id: itemMap['id'] as String,
          productId: itemMap['product_id'] as String, // ✅ product_id
          productName: itemMap['product_name'] as String, // ✅ product_name
          unit: MedicineUnit.values.firstWhere(
            (u) => u.name == itemMap['unit'],
          ),
          unitPrice: (itemMap['unit_price'] as num).toDouble(), // ✅ unit_price
          quantity: (itemMap['quantity'] as num).toDouble(),
          total: (itemMap['total'] as num).toDouble(),
        );
      }).toList();

      return Sale(
        id: saleMap['id'] as String,
        date: DateTime.parse(saleMap['date'] as String),
        items: items,
        subtotal: (saleMap['subtotal'] as num).toDouble(),
        discount: (saleMap['discount'] as num).toDouble(),
        tax: (saleMap['tax'] as num).toDouble(),
        total: (saleMap['total'] as num).toDouble(),
        paidAmount: (saleMap['paid_amount'] as num?)?.toDouble() ??
            (saleMap['total'] as num).toDouble(),
        remainingAmount:
            (saleMap['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: PaymentStatus.values.firstWhere(
          (p) => p.name == (saleMap['payment_status'] ?? 'paid'),
          orElse: () => PaymentStatus.paid,
        ),
        paymentMethod: PaymentMethod.values.firstWhere(
          (p) => p.name == saleMap['payment_method'], // ✅ payment_method
        ),
        customerName: saleMap['customer_name'] as String?, // ✅ customer_name
        customerPhone: saleMap['customer_phone'] as String?, // ✅ customer_phone
        cashierId:
            saleMap['cashier_id'] as String? ?? 'unknown', // ✅ cashier_id
        cashierName: saleMap['cashier_name'] as String? ?? '', // ✅ cashier_name
        status: SaleStatus.values.firstWhere(
          (s) => s.name == saleMap['status'],
        ),
        createdAt:
            DateTime.parse(saleMap['created_at'] as String), // ✅ created_at
      );
    } catch (e) {
      developer.log('❌ خطأ في جلب البيع: $e', name: 'SalesService');
      return null;
    }
  }

  /// إيرادات اليوم
  Future<double> getTodayRevenue() async {
    final db = await _dbHelper.database;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final result = await db.rawQuery(
        "SELECT SUM(total) as revenue FROM sales WHERE date >= ? AND status = 'completed'",
        [startOfDay.toIso8601String()],
      );

      return (result.first['revenue'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      developer.log('❌ خطأ في حساب الإيرادات: $e', name: 'SalesService');
      return 0.0;
    }
  }

  /// عدد المبيعات اليوم
  Future<int> getTodaySalesCount() async {
    final db = await _dbHelper.database;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sales WHERE date >= ? AND status = 'completed'",
        [startOfDay.toIso8601String()],
      );

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      developer.log('❌ خطأ في حساب عدد المبيعات: $e', name: 'SalesService');
      return 0;
    }
  }

  /// إلغاء بيع
  Future<bool> cancelSale(String saleId) async {
    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        // إرجاع المخزون
        final items = await txn.query(
          'sale_items', // ✅ sale_items
          where: 'sale_id = ?', // ✅ sale_id
          whereArgs: [saleId],
        );

        for (final item in items) {
          final product = await _productDao
              .findById(item['product_id'] as String); // ✅ product_id
          if (product != null) {
            final unit = MedicineUnit.values.firstWhere(
              (u) => u.name == item['unit'],
            );
            final unitInfo = product.unitInfo[unit];

            if (unitInfo != null) {
              final quantity = (item['quantity'] as num).toDouble();
              final baseQuantity = quantity * unitInfo.conversionToBase;
              final newStock = product.currentStock + baseQuantity;

              await _productDao.updateStock(product.id, newStock);
            }
          }
        }

        // تحديث حالة البيع
        await txn.update(
          'sales',
          {'status': 'cancelled'},
          where: 'id = ?',
          whereArgs: [saleId],
        );
      });

      developer.log('✅ تم إلغاء البيع: $saleId', name: 'SalesService');
      return true;
    } catch (e) {
      developer.log('❌ فشل إلغاء البيع: $e', name: 'SalesService');
      return false;
    }
  }

  /// 🛒 فحص النواقص من عملية البيع (للاستخدام الخارجي)
  ///
  /// يُستخدم عند الحفظ عبر Remote حيث لا يتم استدعاء saveSale المحلي
  Future<void> checkAndAddOutOfStockFromSale(Sale sale) async {
    try {
      // جلب بيانات المنتجات
      final productsMap = <String, dynamic>{};
      for (final item in sale.items) {
        final product = await _productDao.findById(item.productId);
        if (product != null) {
          productsMap[item.productId] = product;
        }
      }

      // استدعاء الفحص الداخلي
      await _checkAndAddOutOfStock(productsMap, sale.items);
    } catch (e) {
      developer.log(
        '⚠️ خطأ في فحص النواقص من البيع: $e',
        name: 'AutoReorder',
      );
    }
  }

  /// 🛒 فحص المنتجات الناقصة وإضافتها تلقائياً لطلبية اليوم
  Future<void> _checkAndAddOutOfStock(
    Map<String, dynamic> productsMap,
    List<dynamic> saleItems,
  ) async {
    try {
      final purchaseDao = DailyPurchaseRequestDao();
      final today = DateTime.now();

      developer.log(
        '🔍 فحص ${saleItems.length} منتج للإضافة التلقائية للطلبية (Logic V2)',
        name: 'AutoReorder',
      );

      for (final item in saleItems) {
        final productId = item.productId;

        // ✅ استخدام البيانات الموجودة مسبقاً (قبل البيع) لحساب الرصيد المتبقي
        // هذا يحل مشكلة عدم تحديث قاعدة البيانات المحلية عند البيع عن بعد
        final beforeSaleProduct = productsMap[productId];

        if (beforeSaleProduct != null) {
          final currentStockBeforeSale = beforeSaleProduct.currentStock;

          // الحصول على الوحدة والتحويل
          MedicineUnit unit;
          double quantity;

          if (item is SaleItem) {
            unit = item.unit;
            quantity = item.quantity;
          } else {
            // fallback for dynamic maps if needed, though strictly we pass SaleItem usually
            unit = MedicineUnit.values.firstWhere(
                (u) => u.name == item.unit.name,
                orElse: () => MedicineUnit.packet);
            quantity = (item.quantity as num).toDouble();
          }

          final unitInfo = beforeSaleProduct.unitInfo[unit];

          if (unitInfo != null) {
            final soldQuantityInBase = quantity * unitInfo.conversionToBase;
            final remainingStock = currentStockBeforeSale - soldQuantityInBase;

            developer.log(
              '📦 ${beforeSaleProduct.name}: الرصيد قبل=$currentStockBeforeSale - المباع=$soldQuantityInBase = المتبقي المتوقع=$remainingStock',
              name: 'AutoReorder',
            );

            // إذا كان الرصيد المتبقي صفر أو أقل (مع هامش خطأ)
            if (remainingStock < 0.001) {
              // التحقق من عدم وجود المنتج في طلبية اليوم
              final alreadyExists =
                  await purchaseDao.isProductInTodayRequest(productId);

              if (!alreadyExists) {
                // إضافة المنتج تلقائياً لطلبية اليوم
                final request = DailyPurchaseRequest(
                  id: const Uuid().v4(),
                  productId: productId,
                  productName: beforeSaleProduct.name,
                  requestedQuantity: 5, // ✅ تم التعديل إلى 5 حسب الطلب
                  unit: unit.name,
                  autoAdded: true,
                  date: today,
                  createdAt: DateTime.now(),
                );

                await purchaseDao.insertRequest(request);

                developer.log(
                  '✅ تمت إضافة ${beforeSaleProduct.name} تلقائياً لطلبية اليوم (كمية 5)!',
                  name: 'AutoReorder',
                );
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ خطأ في فحص النواقص: $e',
        name: 'AutoReorder',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
