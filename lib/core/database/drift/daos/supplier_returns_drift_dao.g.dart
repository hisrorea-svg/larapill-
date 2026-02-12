// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_returns_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SupplierReturnsDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $PurchaseOrdersTable get purchaseOrders => attachedDatabase.purchaseOrders;
  $ProductsTable get products => attachedDatabase.products;
  $SupplierReturnsTable get supplierReturns => attachedDatabase.supplierReturns;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $SupplierLedgerTable get supplierLedger => attachedDatabase.supplierLedger;
  SupplierReturnsDriftDaoManager get managers =>
      SupplierReturnsDriftDaoManager(this);
}

class SupplierReturnsDriftDaoManager {
  final _$SupplierReturnsDriftDaoMixin _db;
  SupplierReturnsDriftDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$PurchaseOrdersTableTableManager get purchaseOrders =>
      $$PurchaseOrdersTableTableManager(
          _db.attachedDatabase, _db.purchaseOrders);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SupplierReturnsTableTableManager get supplierReturns =>
      $$SupplierReturnsTableTableManager(
          _db.attachedDatabase, _db.supplierReturns);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
          _db.attachedDatabase, _db.stockMovements);
  $$SupplierLedgerTableTableManager get supplierLedger =>
      $$SupplierLedgerTableTableManager(
          _db.attachedDatabase, _db.supplierLedger);
}
