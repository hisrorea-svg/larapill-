// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$ReturnDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $ReturnsTable get returns => attachedDatabase.returns;
  $ProductsTable get products => attachedDatabase.products;
  $ReturnItemsTable get returnItems => attachedDatabase.returnItems;
  $ProductUnitsTable get productUnits => attachedDatabase.productUnits;
  ReturnDriftDaoManager get managers => ReturnDriftDaoManager(this);
}

class ReturnDriftDaoManager {
  final _$ReturnDriftDaoMixin _db;
  ReturnDriftDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$ReturnsTableTableManager get returns =>
      $$ReturnsTableTableManager(_db.attachedDatabase, _db.returns);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ReturnItemsTableTableManager get returnItems =>
      $$ReturnItemsTableTableManager(_db.attachedDatabase, _db.returnItems);
  $$ProductUnitsTableTableManager get productUnits =>
      $$ProductUnitsTableTableManager(_db.attachedDatabase, _db.productUnits);
}
