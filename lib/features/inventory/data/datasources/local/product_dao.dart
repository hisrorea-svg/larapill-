import 'dart:async';
import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';
import '../../../../../database/database_helper.dart';
import '../../../../../core/models/shared/product.dart';
import '../../../../../core/models/shared/medicine_unit.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/services/audit_logger.dart';
import '../../../../../core/utils/input_sanitizer.dart';

/// DAO للتعامل مع جدول المنتجات
class ProductDAO {
  final DatabaseHelper _dbHelper =
      DatabaseHelper(); // ✅ استخدام factory بدلاً من instance
  final Uuid _uuid = const Uuid();

  // ==================== إضافة منتج مع معالجة أخطاء محسنة ====================
  Future<String> insert(Product product,
      {String? userId, String? userName}) async {
    try {
      // ✅ 1. تنظيف المدخلات
      final cleanName = InputSanitizer.sanitizeProductName(product.name);
      final cleanScientificName = product.scientificName != null
          ? InputSanitizer.sanitizeProductName(product.scientificName!)
          : null;
      final cleanCompany = InputSanitizer.sanitizeProductName(product.company);
      final cleanBarcode = InputSanitizer.sanitizeBarcode(product.barcode);

      // ✅ 2. التحقق من صحة البيانات
      if (cleanName.isEmpty || cleanName.length < 2) {
        throw ValidationException(
          'اسم المنتج غير صحيح',
          fieldName: 'name',
          invalidValue: product.name,
          userMessage: 'اسم المنتج يجب أن يكون حرفين على الأقل',
        );
      }

      if (cleanBarcode.isEmpty) {
        throw ValidationException(
          'الباركود غير صحيح',
          fieldName: 'barcode',
          invalidValue: product.barcode,
          userMessage: 'الباركود مطلوب',
        );
      }

      if (product.unitInfo.isEmpty) {
        throw ValidationException(
          'لا توجد وحدات للمنتج',
          userMessage: 'يجب إضافة وحدة واحدة على الأقل للمنتج',
        );
      }

      final db = await _dbHelper.database;

      developer.log('🔍 فحص الباركود قبل الإضافة: $cleanBarcode',
          name: 'ProductDAO');

      // ✅ 3. فحص الباركود المكرر مع timeout
      final existingBarcode = await db.query(
        'products',
        where: 'barcode = ? AND is_active = 1',
        whereArgs: [cleanBarcode],
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw DatabaseTimeoutException(
          'انتهت مهلة فحص الباركود',
          timeout: const Duration(seconds: 5),
        ),
      );

      if (existingBarcode.isNotEmpty) {
        throw DatabaseConstraintException(
          'الباركود $cleanBarcode موجود مسبقاً',
          constraintType: 'UNIQUE',
          tableName: 'products',
          userMessage:
              'الباركود "$cleanBarcode" مستخدم بالفعل. استخدم باركود آخر.',
        );
      }

      developer.log('✅ الباركود فريد، بدء الإضافة', name: 'ProductDAO');

      // ✅ 4. إضافة المنتج مع timeout
      await db.transaction((txn) async {
        // إضافة المنتج الأساسي
        await txn.insert('products', {
          'id': product.id,
          'name': cleanName,
          'scientific_name': cleanScientificName,
          'company': cleanCompany,
          'barcode': cleanBarcode,
          'base_unit': product.baseUnit.name,
          'current_stock': product.currentStock,
          'min_stock_level': product.minStockLevel,
          'expiry_date': product.expiryDate?.toIso8601String(),
          'production_date': product.productionDate?.toIso8601String(),
          'created_at': product.createdAt.toIso8601String(),
          'updated_at': product.updatedAt.toIso8601String(),
          'is_active': 1,
        });

        // إضافة معلومات الوحدات
        for (var entry in product.unitInfo.entries) {
          final unit = entry.key;
          final info = entry.value;

          await txn.insert('product_units', {
            'id': _uuid.v4(),
            'product_id': product.id,
            'unit': unit.name,
            'selling_price': info.sellingPrice,
            'cost_price': info.costPrice,
            'conversion_to_base': info.conversionToBase,
            'description': info.description,
            'quantity': info.quantity ?? 0,
          });
        }
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw DatabaseTimeoutException(
          'انتهت مهلة إضافة المنتج',
          timeout: const Duration(seconds: 15),
        ),
      );

      // 📝 5. تسجيل في AuditLogger
      if (userId != null) {
        await AuditLogger().logProductCreate(
          userId,
          userName ?? 'مستخدم غير معروف',
          product.id,
          cleanName,
          details: {
            'barcode': cleanBarcode,
            'company': cleanCompany,
          },
        );
      }

      developer.log('✅ تم إضافة المنتج: ${product.id}', name: 'ProductDAO');
      return product.id;
    } on AppException catch (e) {
      developer.log('❌ خطأ في إضافة المنتج: ${e.message}',
          name: 'ProductDAO', error: e, stackTrace: e.stackTrace);
      rethrow;
    } on sqflite.DatabaseException catch (e) {
      developer.log('❌ خطأ قاعدة بيانات في إضافة المنتج: $e',
          name: 'ProductDAO', error: e);
      throw DatabaseException(
        'فشل إضافة المنتج في قاعدة البيانات',
        originalError: e,
        tableName: 'products',
        operation: 'insert',
      );
    } catch (e, stackTrace) {
      developer.log('❌ خطأ غير متوقع في إضافة المنتج: $e',
          name: 'ProductDAO', error: e, stackTrace: stackTrace);
      throw UnexpectedException(
        'حدث خطأ غير متوقع أثناء إضافة المنتج',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== تحديث منتج مع معالجة أخطاء محسنة ====================
  Future<bool> update(Product product,
      {String? userId, String? userName, Map<String, dynamic>? changes}) async {
    try {
      // ✅ 1. تنظيف المدخلات
      final cleanName = InputSanitizer.sanitizeProductName(product.name);
      final cleanScientificName = product.scientificName != null
          ? InputSanitizer.sanitizeProductName(product.scientificName!)
          : null;
      final cleanCompany = InputSanitizer.sanitizeProductName(product.company);
      final cleanBarcode = InputSanitizer.sanitizeBarcode(product.barcode);

      // ✅ 2. التحقق من صحة البيانات
      if (cleanName.isEmpty) {
        throw ValidationException(
          'اسم المنتج غير صحيح',
          fieldName: 'name',
          invalidValue: product.name,
          userMessage: 'اسم المنتج مطلوب',
        );
      }

      final db = await _dbHelper.database;

      developer.log('🔄 بدء تحديث المنتج: $cleanName', name: 'ProductDAO');

      // ✅ 3. التحديث مع timeout
      final updateCount = await db.transaction((txn) async {
        // تحديث المنتج الأساسي
        final cnt = await txn.update(
          'products',
          {
            'name': cleanName,
            'scientific_name': cleanScientificName,
            'company': cleanCompany,
            'barcode': cleanBarcode,
            'base_unit': product.baseUnit.name,
            'current_stock': product.currentStock,
            'min_stock_level': product.minStockLevel,
            'expiry_date': product.expiryDate?.toIso8601String(),
            'production_date': product.productionDate?.toIso8601String(),
            'is_active': product.isActive ? 1 : 0,
            'updated_at': product.updatedAt.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [product.id],
        );

        if (cnt > 0) {
          // حذف الوحدات القديمة
          await txn.delete('product_units',
              where: 'product_id = ?', whereArgs: [product.id]);

          // إضافة الوحدات الجديدة
          for (var entry in product.unitInfo.entries) {
            await txn.insert('product_units', {
              'id': _uuid.v4(),
              'product_id': product.id,
              'unit': entry.key.name,
              'selling_price': entry.value.sellingPrice,
              'cost_price': entry.value.costPrice,
              'conversion_to_base': entry.value.conversionToBase,
              'description': entry.value.description,
              'quantity': entry.value.quantity ?? 0,
            });
          }
        }
        return cnt;
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw DatabaseTimeoutException(
          'انتهت مهلة تحديث المنتج',
          timeout: const Duration(seconds: 15),
        ),
      );

      if (updateCount == 0) {
        throw NotFoundException(
          'المنتج غير موجود: ${product.id}',
          entityType: 'product',
          entityId: product.id,
          userMessage: 'المنتج المطلوب غير موجود في قاعدة البيانات',
        );
      }

      // 📝 4. تسجيل في AuditLogger
      if (userId != null) {
        await AuditLogger().logProductUpdate(
          userId,
          userName ?? 'مستخدم غير معروف',
          product.id,
          cleanName,
          changes: changes,
        );
      }

      developer.log('✅ تم تحديث المنتج: $cleanName', name: 'ProductDAO');
      return true;
    } on AppException catch (e) {
      developer.log('❌ خطأ في تحديث المنتج: ${e.message}',
          name: 'ProductDAO', error: e, stackTrace: e.stackTrace);
      rethrow;
    } on sqflite.DatabaseException catch (e) {
      developer.log('❌ خطأ قاعدة بيانات في تحديث المنتج: $e',
          name: 'ProductDAO', error: e);
      throw DatabaseException(
        'فشل تحديث المنتج في قاعدة البيانات',
        originalError: e,
        tableName: 'products',
        operation: 'update',
      );
    } catch (e, stackTrace) {
      developer.log('❌ خطأ غير متوقع في تحديث المنتج: $e',
          name: 'ProductDAO', error: e, stackTrace: stackTrace);
      throw UnexpectedException(
        'حدث خطأ غير متوقع أثناء تحديث المنتج',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== جلب جميع المنتجات ====================
  Future<List<Product>> findAll({bool activeOnly = true}) async {
    try {
      final db = await _dbHelper.database;
      final whereClause = activeOnly ? 'WHERE p.is_active = 1' : '';

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT p.*, 
               GROUP_CONCAT(
                 pu.unit || ':' || pu.selling_price || ':' || pu.cost_price || ':' ||
                 pu.conversion_to_base || ':' || pu.description || ':' || COALESCE(pu.quantity, 0),
                 '|'
               ) as unit_info_string
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        $whereClause
        GROUP BY p.id
        ORDER BY p.name ASC
      ''');

      return results.map(_mapToProduct).toList();
    } catch (e) {
      developer.log('❌ خطأ في جلب المنتجات: $e', name: 'ProductDAO');
      rethrow;
    }
  }

  // ==================== البحث ====================
  Future<List<Product>> search(String query) async {
    try {
      final db = await _dbHelper.database;
      final searchTerm = '%$query%';

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT p.*, 
               GROUP_CONCAT(
                 pu.unit || ':' || pu.selling_price || ':' || pu.cost_price || ':' ||
                 pu.conversion_to_base || ':' || pu.description || ':' || COALESCE(pu.quantity, 0),
                 '|'
               ) as unit_info_string
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        WHERE p.is_active = 1 
          AND (p.name LIKE ? OR p.barcode LIKE ? OR p.company LIKE ?)
        GROUP BY p.id
        ORDER BY p.name ASC
      ''', [searchTerm, searchTerm, searchTerm]);

      return results.map(_mapToProduct).toList();
    } catch (e) {
      developer.log('❌ خطأ في البحث: $e', name: 'ProductDAO');
      rethrow;
    }
  }

  // ==================== فحص الباركود ====================
  Future<bool> isBarcodeExists(String barcode,
      {String? excludeProductId}) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = 'barcode = ? AND is_active = 1';
      List<dynamic> whereArgs = [barcode];

      if (excludeProductId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeProductId);
      }

      final result = await db.query(
        'products',
        columns: ['id'],
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      developer.log('❌ خطأ في فحص الباركود: $e', name: 'ProductDAO');
      return false;
    }
  }

  // ==================== حذف منتج (soft delete) ====================
  Future<void> delete(String productId) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'products',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [productId],
      );

      developer.log('✅ تم حذف المنتج: $productId', name: 'ProductDAO');
    } catch (e) {
      developer.log('❌ خطأ في حذف المنتج: $e', name: 'ProductDAO');
      rethrow;
    }
  }

  // ==================== جلب المنتجات منخفضة المخزون ====================
  Future<List<Product>> findLowStock() async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT p.*, 
               GROUP_CONCAT(
                 pu.unit || ':' || pu.selling_price || ':' || pu.cost_price || ':' ||
                 pu.conversion_to_base || ':' || pu.description || ':' || COALESCE(pu.quantity, 0),
                 '|'
               ) as unit_info_string
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        WHERE p.is_active = 1 AND p.current_stock <= p.min_stock_level
        GROUP BY p.id
        ORDER BY p.current_stock ASC
      ''');

      return results.map(_mapToProduct).toList();
    } catch (e) {
      developer.log('❌ خطأ في جلب المنتجات منخفضة المخزون: $e',
          name: 'ProductDAO');
      rethrow;
    }
  }

  // ==================== تحديث المخزون ====================
  Future<bool> updateStock(String productId, double newStock) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.update(
        'products',
        {
          'current_stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      return result > 0;
    } catch (e) {
      developer.log('❌ خطأ في تحديث المخزون: $e', name: 'ProductDAO');
      return false;
    }
  }

  // ==================== جلب منتج بواسطة ID ====================
  Future<Product?> findById(String id) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT p.*, 
               GROUP_CONCAT(
                 pu.unit || ':' || pu.selling_price || ':' || pu.cost_price || ':' ||
                 pu.conversion_to_base || ':' || pu.description || ':' || COALESCE(pu.quantity, 0),
                 '|'
               ) as unit_info_string
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        WHERE p.id = ? AND p.is_active = 1
        GROUP BY p.id
      ''', [id]);

      if (results.isEmpty) return null;
      return _mapToProduct(results.first);
    } catch (e) {
      developer.log('❌ خطأ في جلب المنتج: $e', name: 'ProductDAO');
      return null;
    }
  }

  // ==================== جلب منتج بواسطة الباركود ====================
  Future<Product?> findByBarcode(String barcode) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT p.*, 
               GROUP_CONCAT(
                 pu.unit || ':' || pu.selling_price || ':' || pu.cost_price || ':' ||
                 pu.conversion_to_base || ':' || pu.description || ':' || COALESCE(pu.quantity, 0),
                 '|'
               ) as unit_info_string
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        WHERE p.barcode = ? AND p.is_active = 1
        GROUP BY p.id
      ''', [barcode]);

      if (results.isEmpty) return null;
      return _mapToProduct(results.first);
    } catch (e) {
      developer.log('❌ خطأ في البحث بالباركود: $e', name: 'ProductDAO');
      return null;
    }
  }

  // ==================== جلب المنتجات القريبة من انتهاء الصلاحية ====================
  Future<List<Product>> findExpiringSoon({int daysThreshold = 30}) async {
    try {
      final db = await _dbHelper.database;
      final futureDate = DateTime.now().add(Duration(days: daysThreshold));

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT p.*, 
               GROUP_CONCAT(
                 pu.unit || ':' || pu.selling_price || ':' || pu.cost_price || ':' ||
                 pu.conversion_to_base || ':' || pu.description || ':' || COALESCE(pu.quantity, 0),
                 '|'
               ) as unit_info_string
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        WHERE p.expiry_date IS NOT NULL 
          AND p.expiry_date <= ? 
          AND p.expiry_date > ?
          AND p.is_active = 1
        GROUP BY p.id
        ORDER BY p.expiry_date ASC
      ''', [futureDate.toIso8601String(), DateTime.now().toIso8601String()]);

      return results.map(_mapToProduct).toList();
    } catch (e) {
      developer.log('❌ خطأ في جلب المنتجات القريبة من الانتهاء: $e',
          name: 'ProductDAO');
      rethrow;
    }
  }

  // ==================== إحصائيات المنتجات ====================
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final db = await _dbHelper.database;

      final total = await db.rawQuery(
          'SELECT COUNT(*) as count FROM products WHERE is_active = 1');

      final lowStock = await db.rawQuery(
          'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND current_stock <= min_stock_level');

      final outOfStock = await db.rawQuery(
          'SELECT COUNT(*) as count FROM products WHERE is_active = 1 AND current_stock <= 0');

      final expiring = await db.rawQuery('''
        SELECT COUNT(*) as count FROM products 
        WHERE is_active = 1 
        AND expiry_date IS NOT NULL 
        AND expiry_date <= ?
      ''', [DateTime.now().add(const Duration(days: 30)).toIso8601String()]);

      return {
        'total': total.first['count'] as int,
        'lowStock': lowStock.first['count'] as int,
        'outOfStock': outOfStock.first['count'] as int,
        'expiringSoon': expiring.first['count'] as int,
      };
    } catch (e) {
      developer.log('❌ خطأ في جلب الإحصائيات: $e', name: 'ProductDAO');
      return {
        'total': 0,
        'lowStock': 0,
        'outOfStock': 0,
        'expiringSoon': 0,
      };
    }
  }

  // ==================== Helper: تحويل Map إلى Product ====================
  Product _mapToProduct(Map<String, dynamic> map) {
    try {
      final unitInfoString = map['unit_info_string'] as String?;
      final Map<MedicineUnit, UnitInfo> unitInfo = {};

      if (unitInfoString != null && unitInfoString.isNotEmpty) {
        final unitPairs = unitInfoString.split('|');
        for (final pair in unitPairs) {
          if (pair.trim().isEmpty) continue;

          final parts = pair.split(':');
          if (parts.length >= 6) {
            try {
              // ✅ استخدام values.firstWhere بدلاً من fromString
              final unit = MedicineUnit.values.firstWhere(
                (e) => e.name == parts[0],
                orElse: () => MedicineUnit.strip,
              );

              unitInfo[unit] = UnitInfo(
                sellingPrice: double.tryParse(parts[1]) ?? 0.0,
                costPrice: double.tryParse(parts[2]) ?? 0.0,
                conversionToBase: double.tryParse(parts[3]) ?? 1.0,
                description: parts[4],
                quantity: int.tryParse(parts[5]), // ✅ تحويل إلى int
              );
            } catch (e) {
              developer.log('خطأ في تحليل وحدة المنتج: $pair - $e',
                  name: 'ProductDAO');
            }
          }
        }
      }

      return Product(
        id: map['id'] as String,
        name: map['name'] as String,
        scientificName: map['scientific_name'] as String?,
        company: map['company'] as String,
        barcode: map['barcode'] as String,
        // ✅ استخدام values.firstWhere بدلاً من fromString
        baseUnit: MedicineUnit.values.firstWhere(
          (e) => e.name == map['base_unit'],
          orElse: () => MedicineUnit.strip,
        ),
        unitInfo: unitInfo,
        currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0.0,
        minStockLevel: (map['min_stock_level'] as num?)?.toDouble() ?? 0.0,
        expiryDate: map['expiry_date'] != null
            ? DateTime.parse(map['expiry_date'] as String)
            : null,
        productionDate: map['production_date'] != null
            ? DateTime.parse(map['production_date'] as String)
            : null,
        isActive: (map['is_active'] as int?) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    } catch (e) {
      developer.log('❌ خطأ في _mapToProduct: $e', name: 'ProductDAO');
      rethrow;
    }
  }
}

// ---------- Wrappers to work with ProductEntity (simpler domain entity) ----------
extension ProductEntityAdapters on ProductDAO {
  /// Insert from ProductEntity - improved version
  Future<String> insertProduct(ProductEntity e) async {
    try {
      // جلب آخر ID رقمي
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
          'SELECT MAX(CAST(id AS INTEGER)) as maxId FROM products WHERE id GLOB "[0-9]*"');
      final maxId = (result.first['maxId'] as int?) ?? 0;
      final newId = (maxId + 1).toString();

      final product = Product(
        id: newId,
        name: e.name,
        scientificName: null,
        company: e.company,
        barcode: e.barcode.isNotEmpty
            ? e.barcode
            : 'BARCODE$newId', // ✅ استخدام باركود المستخدم أو توليد مؤقت
        baseUnit: MedicineUnit.piece,
        unitInfo: {
          MedicineUnit.piece: UnitInfo(
            sellingPrice: e.price,
            costPrice: e.price * 0.8,
            conversionToBase: 1.0,
            description: 'قطعة واحدة',
            quantity: e.quantity,
          ),
        },
        currentStock: e.quantity.toDouble(),
        minStockLevel: 10.0,
        expiryDate: e.expiryDate,
        productionDate: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      developer.log('✅ إضافة منتج جديد: ${e.name}', name: 'ProductDAO');
      return await insert(product);
    } catch (e) {
      developer.log('❌ خطأ في insertProduct: $e', name: 'ProductDAO');
      rethrow;
    }
  }

  Future<bool> updateProduct(ProductEntity e) async {
    try {
      developer.log('🔄 بدء تحديث المنتج: ${e.name} (ID: ${e.id})',
          name: 'ProductDAO');

      final existing = await findById(e.id.toString());

      if (existing == null) {
        developer.log('❌ المنتج غير موجود: ${e.id}', name: 'ProductDAO');
        throw Exception('المنتج غير موجود: ${e.id}');
      }

      developer.log('✅ تم جلب المنتج الحالي', name: 'ProductDAO');

      // ✅ تحديث unitInfo مع costPrice الجديد
      final updatedUnitInfo =
          Map<MedicineUnit, UnitInfo>.from(existing.unitInfo);

      // تحديث الوحدة الأساسية
      if (updatedUnitInfo.containsKey(existing.baseUnit)) {
        final oldInfo = updatedUnitInfo[existing.baseUnit]!;
        updatedUnitInfo[existing.baseUnit] = UnitInfo(
          sellingPrice: e.price, // ✅ السعر الجديد
          costPrice:
              e.costPrice ?? oldInfo.costPrice, // ✅ استخدم costPrice من Entity!
          conversionToBase: oldInfo.conversionToBase,
          description: oldInfo.description,
          quantity: e.quantity,
        );

        // ✅ أضف log للتأكد
        developer.log(
          '💰 تحديث التكلفة: ${oldInfo.costPrice} → ${e.costPrice ?? oldInfo.costPrice}',
          name: 'ProductDAO',
        );
      } else {
        // إذا ما فيه unitInfo، أضف واحد جديد
        updatedUnitInfo[existing.baseUnit] = UnitInfo(
          sellingPrice: e.price,
          costPrice: e.costPrice ?? (e.price * 0.8), // ✅ استخدم من Entity
          conversionToBase: 1.0,
          description: 'قطعة',
          quantity: e.quantity,
        );
      }

      // تحديث المنتج
      final updatedProduct = Product(
        id: existing.id,
        name: e.name,
        scientificName: existing.scientificName,
        company: e.company,
        barcode: existing.barcode,
        baseUnit: existing.baseUnit,
        unitInfo: updatedUnitInfo, // ✅ استخدم المحدّث
        currentStock: e.quantity.toDouble(),
        minStockLevel: existing.minStockLevel,
        expiryDate: e.expiryDate,
        productionDate: existing.productionDate,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      developer.log('📝 تحديث البيانات: ${updatedProduct.name}',
          name: 'ProductDAO');

      // تنفيذ التحديث
      final success = await update(updatedProduct);

      if (success) {
        developer.log('✅ تم تحديث المنتج بنجاح: ${e.name}', name: 'ProductDAO');
      } else {
        developer.log('❌ فشل تحديث المنتج: ${e.name}', name: 'ProductDAO');
      }

      return success;
    } catch (e, stackTrace) {
      developer.log(
        '❌ خطأ في updateProduct',
        name: 'ProductDAO',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      developer.log('🗑️ حذف المنتج: $id', name: 'ProductDAO');
      await delete(id.toString());
      developer.log('✅ تم حذف المنتج بنجاح', name: 'ProductDAO');
    } catch (e) {
      developer.log('❌ خطأ في حذف المنتج: $e', name: 'ProductDAO');
      rethrow;
    }
  }
}
