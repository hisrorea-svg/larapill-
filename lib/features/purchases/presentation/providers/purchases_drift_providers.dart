// lib/features/purchases/presentation/providers/purchases_drift_providers.dart
// Direct Drift providers for purchases module - No wrappers!

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/supplier_drift_dao.dart';
import '../../../../core/database/drift/daos/product_drift_dao.dart';
import '../../../../core/database/drift/daos/purchase_order_drift_dao.dart';
import '../../../../core/database/drift/database_provider.dart';

// ============== Purchase Item Data ==============

/// Purchase item data for creating orders
class PurchaseItemData {
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double bonus;
  final double unitPrice;
  final String? expiryDate;

  PurchaseItemData({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    this.bonus = 0,
    required this.unitPrice,
    this.expiryDate,
  });

  /// Total = (quantity + bonus) * unitPrice
  double get total => (quantity + bonus) * unitPrice;
}

// ============== DAO Providers ==============

/// Supplier DAO provider
final supplierDriftDaoProvider = Provider<SupplierDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SupplierDriftDao(db);
});

/// Product DAO provider for search
final productDriftDaoForPurchasesProvider = Provider<ProductDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductDriftDao(db);
});

/// Purchase Order DAO provider
final purchaseOrderDriftDaoProvider = Provider<PurchaseOrderDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PurchaseOrderDriftDao(db);
});

// ============== Supplier Providers ==============

/// Supplier item for UI display
class SupplierDisplayItem {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? contactPerson;
  final String paymentType;
  final double balance;
  final bool isActive;

  SupplierDisplayItem({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.contactPerson,
    this.paymentType = 'cash',
    this.balance = 0,
    this.isActive = true,
  });

  /// Payment type label in Arabic
  String get paymentTypeLabel {
    switch (paymentType) {
      case 'cash':
        return 'نقدي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      case 'credit':
        return 'آجل';
      default:
        return paymentType;
    }
  }
}

/// 🚀 OPTIMIZED: Active suppliers list provider (Single Query - No N+1!)
final activeSuppliersProvider =
    FutureProvider<List<SupplierDisplayItem>>((ref) async {
  final dao = ref.watch(supplierDriftDaoProvider);

  // Use optimized method that gets suppliers with balances in single query
  final suppliersWithBalances = await dao.getActiveSuppliersWithBalances();

  return suppliersWithBalances
      .map((swb) => SupplierDisplayItem(
            id: swb.supplier.id,
            name: swb.supplier.name,
            phone: swb.supplier.phone,
            address: swb.supplier.address,
            paymentType: swb.supplier.paymentType,
            balance: swb.balance,
            isActive: swb.supplier.isActive,
          ))
      .toList();
});

/// Add a new supplier using Drift DAO
Future<void> addSupplierDirect(
  WidgetRef ref, {
  required String id,
  required String name,
  String? phone,
  String? contactPerson,
  String paymentType = 'cash',
}) async {
  final dao = ref.read(supplierDriftDaoProvider);
  await dao.upsertSupplier(SuppliersCompanion.insert(
    id: id,
    name: name,
    phone: Value(phone),
    address: const Value(null),
    contactPerson: Value(contactPerson),
    paymentType: Value(paymentType),
    isActive: const Value(true),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
  // Refresh the suppliers list
  // ignore: unused_result
  ref.refresh(activeSuppliersProvider);
}

// ============== Product Search Providers ==============

/// Product search item for UI display
class ProductSearchDisplayItem {
  final String id;
  final String name;
  final String? barcode;
  final double currentStock;
  final double? costPrice;
  final double? sellingPrice;
  final String? unit;

  ProductSearchDisplayItem({
    required this.id,
    required this.name,
    this.barcode,
    this.currentStock = 0,
    this.costPrice,
    this.sellingPrice,
    this.unit,
  });
}

/// Product search state
class ProductSearchState {
  final List<ProductSearchDisplayItem> results;
  final bool isLoading;
  final String query;

  const ProductSearchState({
    this.results = const [],
    this.isLoading = false,
    this.query = '',
  });

  ProductSearchState copyWith({
    List<ProductSearchDisplayItem>? results,
    bool? isLoading,
    String? query,
  }) {
    return ProductSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
  }
}

/// Product search notifier using Drift directly
class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  final ProductDriftDao _dao;

  ProductSearchNotifier(this._dao) : super(const ProductSearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const ProductSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query);

    try {
      // 🚀 OPTIMIZED: Use searchWithUnits (Single JOIN Query - No N+1!)
      final productsWithUnits = await _dao.searchWithUnits(query);

      final results = productsWithUnits.map((pwu) {
        final baseUnit = pwu.units.isNotEmpty ? pwu.units.first : null;
        return ProductSearchDisplayItem(
          id: pwu.product.id,
          name: pwu.product.name,
          barcode: pwu.product.barcode,
          currentStock: pwu.product.currentStock,
          costPrice: baseUnit?.costPrice,
          sellingPrice: baseUnit?.sellingPrice,
          unit: pwu.product.baseUnit,
        );
      }).toList();

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(results: [], isLoading: false);
    }
  }

  void clear() {
    state = const ProductSearchState();
  }

  /// Alias for clear() for backward compatibility
  void clearSelection() {
    clear();
  }
}

/// Product search provider
final productSearchDriftProvider =
    StateNotifierProvider<ProductSearchNotifier, ProductSearchState>((ref) {
  final dao = ref.watch(productDriftDaoForPurchasesProvider);
  return ProductSearchNotifier(dao);
});

// ============== Purchase Order Service ==============

/// Service for purchase order operations using Drift DAOs directly
class PurchaseOrderService {
  final AppDatabase _db;
  final PurchaseOrderDriftDao _purchaseOrderDao;
  final SupplierDriftDao _supplierDao;

  PurchaseOrderService(this._db)
      : _purchaseOrderDao = PurchaseOrderDriftDao(_db),
        _supplierDao = SupplierDriftDao(_db);

  /// Create draft purchase order with items
  Future<String> createDraftOrder({
    required String supplierId,
    required String invoiceNumber,
    required List<PurchaseItemData> items,
    required String createdBy,
  }) async {
    final orderId = const Uuid().v4();
    final now = DateTime.now();
    final orderNumber = 'PO-${DateTime.now().millisecondsSinceEpoch}';

    final totalAmount = items.fold(0.0, (sum, item) => sum + item.total);

    final orderCompanion = PurchaseOrdersCompanion.insert(
      id: orderId,
      orderNumber: orderNumber,
      supplierId: supplierId,
      orderDate: now,
      status: const Value('draft'),
      total: Value(totalAmount),
      notes: Value('رقم الفاتورة: $invoiceNumber'),
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    final itemCompanions = items.map((item) {
      return PurchaseItemsCompanion.insert(
        id: const Uuid().v4(),
        purchaseOrderId: orderId,
        productId: item.productId,
        productName: item.productName,
        unit: item.unit,
        quantity: item.quantity + item.bonus,
        unitPrice: item.unitPrice,
        total: item.total,
        notes: item.bonus > 0
            ? Value('بونص: ${item.bonus}')
            : const Value.absent(),
        createdAt: now,
      );
    }).toList();

    await _purchaseOrderDao.createOrder(orderCompanion, itemCompanions);
    return orderId;
  }

  /// Post (receive) a purchase order and update ledger
  Future<void> postOrder({
    required String orderId,
    required String supplierId,
    required double totalAmount,
    required String invoiceNumber,
  }) async {
    // Get order items first
    final items = await (_db.select(_db.purchaseItems)
          ..where((i) => i.purchaseOrderId.equals(orderId)))
        .get();

    // Create stock movements for each item
    final movements = items.map((item) {
      return StockMovementsCompanion.insert(
        id: const Uuid().v4(),
        productId: item.productId,
        referenceType: 'purchase_order',
        referenceId: orderId,
        quantity: item.quantity,
        costPerUnit: Value(item.unitPrice),
        notes: Value('شراء من طلب $orderId'),
        createdAt: DateTime.now(),
      );
    }).toList();

    await _purchaseOrderDao.receiveOrder(orderId, movements);

    // Add ledger entry
    final currentBalance = await _supplierDao.getBalance(supplierId);
    await _supplierDao.addLedgerEntry(SupplierLedgerCompanion.insert(
      id: const Uuid().v4(),
      supplierId: supplierId,
      referenceId: orderId,
      referenceType: 'purchase_order',
      amount: totalAmount,
      balanceAfter: currentBalance + totalAmount,
      description: 'فاتورة شراء رقم $invoiceNumber',
      createdAt: DateTime.now(),
    ));
  }
}

/// Purchase Order Service provider
final purchaseOrderServiceProvider = Provider<PurchaseOrderService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PurchaseOrderService(db);
});
