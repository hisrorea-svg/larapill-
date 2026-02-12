import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/daos/daos.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../models/supplier_item.dart';
import '../models/supplier_ledger_entry.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

class PurchasesRepositoryImpl implements PurchasesRepository {
  final SupplierDriftDao _supplierDao;
  final PurchaseOrderDriftDao _purchaseDao;
  final ProductDriftDao _productDao;

  PurchasesRepositoryImpl({
    required SupplierDriftDao supplierDao,
    required PurchaseOrderDriftDao purchaseDao,
    required ProductDriftDao productDao,
  })  : _supplierDao = supplierDao,
        _purchaseDao = purchaseDao,
        _productDao = productDao;

  @override
  Future<DashboardStats> getDashboardStats() async {
    final lowStockCount = await _productDao.countLowStock();
    final activeSuppliers = await _supplierDao.getActiveSuppliers();

    double totalDebt = 0;
    final debtBySupplier = <String, double>{};

    for (final s in activeSuppliers) {
      final balance = await _supplierDao.getBalance(s.id);
      if (balance > 0) {
        totalDebt += balance;
        debtBySupplier[s.name] = balance;
      }
    }

    return DashboardStats(
      lowStockCount: lowStockCount,
      totalDebt: totalDebt,
      debtBySupplier: debtBySupplier,
    );
  }

  @override
  Future<List<SupplierItem>> getActiveSuppliers() async {
    final entries = await _supplierDao.getActiveSuppliers();
    return entries
        .map((e) => SupplierItem(
              id: e.id,
              name: e.name,
              phone: e.phone,
              contactPerson: e.contactPerson,
              paymentType: e.paymentType,
              isActive: e.isActive,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            ))
        .toList();
  }

  @override
  Future<SupplierItem?> getSupplierById(String id) async {
    final e = await _supplierDao.findById(id);
    if (e == null) return null;
    return SupplierItem(
      id: e.id,
      name: e.name,
      phone: e.phone,
      contactPerson: e.contactPerson,
      paymentType: e.paymentType,
      isActive: e.isActive,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  @override
  Future<double> getSupplierBalance(String supplierId) async {
    return await _supplierDao.getBalance(supplierId);
  }

  @override
  Future<List<SupplierLedgerEntry>> getSupplierLedger(String supplierId) async {
    final entries = await _supplierDao.findLedgerBySupplier(supplierId);
    return entries
        .map((e) => SupplierLedgerEntry(
              id: e.id,
              supplierId: e.supplierId,
              referenceId: e.referenceId,
              referenceType: e.referenceType,
              amount: e.amount,
              balanceAfter: e.balanceAfter,
              description: e.description,
              createdAt: e.createdAt,
            ))
        .toList();
  }

  @override
  Future<void> createPayment({
    required String supplierId,
    required double amount,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    final paymentId = const Uuid().v4();
    final now = DateTime.now();

    final currentBalance = await getSupplierBalance(supplierId);
    final newBalance = currentBalance - amount;

    final paymentCompanion = SupplierPaymentsCompanion.insert(
      id: paymentId,
      supplierId: supplierId,
      amount: amount,
      paymentMethod: drift.Value(paymentMethod),
      notes: drift.Value(notes),
      createdAt: now,
    );

    final ledgerCompanion = SupplierLedgerCompanion.insert(
      id: const Uuid().v4(),
      supplierId: supplierId,
      referenceId: paymentId,
      referenceType: 'payment',
      amount: -amount,
      balanceAfter: newBalance,
      description: notes ?? 'دفعة $paymentMethod',
      createdAt: now,
    );

    await _supplierDao.createPayment(paymentCompanion, ledgerCompanion);
  }

  @override
  Future<void> createOrder(
    String supplierId,
    List<dynamic> items, {
    String status = 'draft',
    String? notes,
  }) async {
    final orderId = const Uuid().v4();
    final now = DateTime.now();
    final orderNum = 'PO-${now.millisecondsSinceEpoch}';

    final total = items.fold<double>(0, (sum, item) {
      if (item is Map) return sum + (item['total'] as num).toDouble();
      return sum;
    });

    final orderCompanion = PurchaseOrdersCompanion.insert(
      id: orderId,
      orderNumber: orderNum,
      supplierId: supplierId,
      total: drift.Value(total),
      status: drift.Value(status),
      orderDate: now,
      notes: drift.Value(notes),
      createdBy: 'system',
      createdAt: now,
      updatedAt: now,
    );

    final itemCompanions = items.map((item) {
      if (item is Map) {
        return PurchaseItemsCompanion.insert(
          id: const Uuid().v4(),
          purchaseOrderId: orderId,
          productId: item['product_id'] as String,
          productName: item['product_name'] as String,
          unit: item['unit'] as String? ?? 'piece',
          quantity: (item['quantity'] as num).toDouble(),
          unitPrice: (item['unit_price'] as num).toDouble(),
          total: (item['total'] as num).toDouble(),
          createdAt: now,
        );
      }
      throw Exception('Invalid item type');
    }).toList();

    await _purchaseDao.createOrder(orderCompanion, itemCompanions);
  }

  @override
  Future<void> receiveOrder(String orderId, List<dynamic> items) async {
    final now = DateTime.now();

    final movementCompanions = items.map((item) {
      if (item is Map) {
        return StockMovementsCompanion.insert(
          id: const Uuid().v4(),
          productId: item['product_id'] as String,
          referenceId: orderId,
          referenceType: 'purchase',
          quantity: (item['total_quantity'] as num).toDouble(),
          costPerUnit: drift.Value((item['cost_per_unit'] as num?)?.toDouble()),
          createdAt: now,
        );
      }
      throw Exception('Invalid item type');
    }).toList();

    await _purchaseDao.receiveOrder(orderId, movementCompanions);
  }
}

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepositoryImpl(
    supplierDao: ref.watch(supplierDriftDaoProvider),
    purchaseDao: ref.watch(purchaseOrderDriftDaoProvider),
    productDao: ref.watch(productDriftDaoProvider),
  );
});

final supplierDriftDaoProvider = Provider<SupplierDriftDao>((ref) {
  return SupplierDriftDao(ref.watch(appDatabaseProvider));
});

final purchaseOrderDriftDaoProvider = Provider<PurchaseOrderDriftDao>((ref) {
  return PurchaseOrderDriftDao(ref.watch(appDatabaseProvider));
});
