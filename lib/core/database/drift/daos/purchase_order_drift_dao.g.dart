// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchaseOrderDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $PurchaseOrdersTable get purchaseOrders => attachedDatabase.purchaseOrders;
  $ProductsTable get products => attachedDatabase.products;
  $PurchaseItemsTable get purchaseItems => attachedDatabase.purchaseItems;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  PurchaseOrderDriftDaoManager get managers =>
      PurchaseOrderDriftDaoManager(this);
}

class PurchaseOrderDriftDaoManager {
  final _$PurchaseOrderDriftDaoMixin _db;
  PurchaseOrderDriftDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$PurchaseOrdersTableTableManager get purchaseOrders =>
      $$PurchaseOrdersTableTableManager(
          _db.attachedDatabase, _db.purchaseOrders);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db.attachedDatabase, _db.purchaseItems);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
          _db.attachedDatabase, _db.stockMovements);
}
