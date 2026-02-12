// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SupplierDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $SupplierPaymentsTable get supplierPayments =>
      attachedDatabase.supplierPayments;
  $PurchaseOrdersTable get purchaseOrders => attachedDatabase.purchaseOrders;
  $ProductsTable get products => attachedDatabase.products;
  $SupplierReturnsTable get supplierReturns => attachedDatabase.supplierReturns;
  $SupplierLedgerTable get supplierLedger => attachedDatabase.supplierLedger;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  SupplierDriftDaoManager get managers => SupplierDriftDaoManager(this);
}

class SupplierDriftDaoManager {
  final _$SupplierDriftDaoMixin _db;
  SupplierDriftDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$SupplierPaymentsTableTableManager get supplierPayments =>
      $$SupplierPaymentsTableTableManager(
          _db.attachedDatabase, _db.supplierPayments);
  $$PurchaseOrdersTableTableManager get purchaseOrders =>
      $$PurchaseOrdersTableTableManager(
          _db.attachedDatabase, _db.purchaseOrders);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SupplierReturnsTableTableManager get supplierReturns =>
      $$SupplierReturnsTableTableManager(
          _db.attachedDatabase, _db.supplierReturns);
  $$SupplierLedgerTableTableManager get supplierLedger =>
      $$SupplierLedgerTableTableManager(
          _db.attachedDatabase, _db.supplierLedger);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
          _db.attachedDatabase, _db.stockMovements);
}
