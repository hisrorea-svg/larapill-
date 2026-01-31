// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SalesDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $ProductsTable get products => attachedDatabase.products;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  SalesDriftDaoManager get managers => SalesDriftDaoManager(this);
}

class SalesDriftDaoManager {
  final _$SalesDriftDaoMixin _db;
  SalesDriftDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
}
