// lib/core/network/sync_aware_dao.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_database_service.dart';
import '../../database/daos/product_dao.dart';
import '../../database/daos/sale_dao.dart';
import '../../models/product.dart';
import '../../models/medicine_unit.dart';
import '../../features/pos/models/sale.dart';
import '../../features/network/presentation/providers/lan_providers.dart';

/// Sync-Aware Product DAO
/// يقرر تلقائياً: محلي أو عن بعد
class SyncAwareProductDAO {
  final Ref _ref;
  final ProductDAO _localDao = ProductDAO();

  SyncAwareProductDAO(this._ref);

  bool get _useRemote => _ref.read(shouldUseRemoteDatabaseProvider);
  RemoteDatabaseService get _remoteDb => _ref.read(remoteDatabaseProvider);

  /// جلب كل المنتجات
  Future<List<Product>> findAll({bool activeOnly = true}) async {
    if (_useRemote) {
      try {
        final remoteProducts = await _remoteDb.getProducts();
        return remoteProducts.map(_mapToProduct).toList();
      } catch (e) {
        // Fallback to local on error
        return await _localDao.findAll(activeOnly: activeOnly);
      }
    }
    return await _localDao.findAll(activeOnly: activeOnly);
  }

  /// بحث في المنتجات
  Future<List<Product>> search(String query) async {
    if (_useRemote) {
      try {
        final results = await _remoteDb.searchProducts(query);
        return results.map(_mapToProduct).toList();
      } catch (e) {
        return await _localDao.search(query);
      }
    }
    return await _localDao.search(query);
  }

  /// جلب منتج بالـ ID
  Future<Product?> findById(String id) async {
    if (_useRemote) {
      try {
        final result = await _remoteDb.getProductById(id);
        if (result != null) {
          return _mapToProduct(result);
        }
        return null;
      } catch (e) {
        return await _localDao.findById(id);
      }
    }
    return await _localDao.findById(id);
  }

  /// جلب منتج بالباركود
  Future<Product?> findByBarcode(String barcode) async {
    if (_useRemote) {
      try {
        final result = await _remoteDb.getProductByBarcode(barcode);
        if (result != null && result['product'] != null) {
          return _mapToProduct(result['product'] as Map<String, dynamic>);
        }
        return null;
      } catch (e) {
        return await _localDao.findByBarcode(barcode);
      }
    }
    return await _localDao.findByBarcode(barcode);
  }

  /// إضافة منتج
  Future<void> insert(Product product) async {
    if (_useRemote) {
      await _remoteDb.insertProduct(_productToMap(product));
    } else {
      await _localDao.insert(product);
    }
  }

  /// تحديث المخزون
  Future<void> updateStock(String productId, double newStock) async {
    if (_useRemote) {
      await _remoteDb.updateStock(
        productId: productId,
        quantity: newStock,
        operation: 'set',
      );
    } else {
      await _localDao.updateStock(productId, newStock);
    }
  }

  /// المنتجات منخفضة المخزون
  Future<List<Product>> findLowStock() async {
    if (_useRemote) {
      try {
        final results = await _remoteDb.getLowStockProducts();
        return results.map(_mapToProduct).toList();
      } catch (e) {
        return await _localDao.findLowStock();
      }
    }
    return await _localDao.findLowStock();
  }

  /// تحويل Map إلى Product
  Product _mapToProduct(Map<String, dynamic> map) {
    // تحويل base_unit من String إلى MedicineUnit
    final baseUnitStr = map['base_unit'] as String? ?? 'box';
    final baseUnit = MedicineUnit.values.firstWhere(
      (u) => u.name == baseUnitStr || u.arabicName == baseUnitStr,
      orElse: () => MedicineUnit.box,
    );

    // إنشاء unitInfo افتراضي
    final unitInfo = <MedicineUnit, UnitInfo>{
      baseUnit: UnitInfo(
        sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
        costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
        conversionToBase: 1.0,
        description: baseUnit.arabicName,
      ),
    };

    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      scientificName: map['scientific_name'] as String?,
      company: map['company'] as String? ?? '',
      barcode: map['barcode'] as String,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      baseUnit: baseUnit,
      unitInfo: unitInfo,
      currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0,
      minStockLevel: (map['min_stock_level'] as num?)?.toDouble() ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// تحويل Product إلى Map
  Map<String, dynamic> _productToMap(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'scientific_name': product.scientificName,
      'company': product.company,
      'barcode': product.barcode,
      'expiry_date': product.expiryDate?.toIso8601String(),
      'base_unit': product.baseUnit.name,
      'current_stock': product.currentStock,
      'min_stock_level': product.minStockLevel,
      'is_active': product.isActive ? 1 : 0,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
    };
  }
}

/// Sync-Aware Sale DAO
/// يقرر تلقائياً: محلي أو عن بعد
class SyncAwareSaleDAO {
  final Ref _ref;
  final SaleDAO _localDao = SaleDAO();

  SyncAwareSaleDAO(this._ref);

  bool get _useRemote => _ref.read(shouldUseRemoteDatabaseProvider);
  RemoteDatabaseService get _remoteDb => _ref.read(remoteDatabaseProvider);

  /// إضافة مبيعة جديدة
  Future<void> insertSale(Sale sale) async {
    if (_useRemote) {
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

      await _remoteDb.createSale(sale: saleMap, items: itemsList);
    } else {
      await _localDao.insertSale(sale);
    }
  }

  /// جلب مبيعات اليوم
  Future<Map<String, dynamic>> getTodaySales() async {
    if (_useRemote) {
      try {
        return await _remoteDb.getTodaySales();
      } catch (e) {
        final sales = await _localDao.getSalesByDate(DateTime.now());
        double total = 0;
        for (var sale in sales) {
          total += sale.total;
        }
        return {
          'sales': sales,
          'count': sales.length,
          'total': total,
        };
      }
    }
    final sales = await _localDao.getSalesByDate(DateTime.now());
    double total = 0;
    for (var sale in sales) {
      total += sale.total;
    }
    return {
      'sales': sales,
      'count': sales.length,
      'total': total,
    };
  }

  /// جلب كل المبيعات
  Future<List<Sale>> getAllSales() async {
    // المبيعات دائماً من المحلي للأداء
    return await _localDao.getAllSales();
  }

  /// حذف مبيعة
  Future<int> deleteSale(String saleId) async {
    // الحذف يتم محلياً فقط (الـ API لا يدعم الحذف حالياً)
    return await _localDao.deleteSale(saleId);
  }

  /// توليد رقم فاتورة
  Future<String> generateSaleId() async {
    return await _localDao.generateSaleId();
  }
}

// ==================== Providers ====================

/// Provider لـ Sync-Aware Product DAO
final syncAwareProductDaoProvider = Provider<SyncAwareProductDAO>((ref) {
  return SyncAwareProductDAO(ref);
});

/// Provider لـ Sync-Aware Sale DAO
final syncAwareSaleDaoProvider = Provider<SyncAwareSaleDAO>((ref) {
  return SyncAwareSaleDAO(ref);
});
