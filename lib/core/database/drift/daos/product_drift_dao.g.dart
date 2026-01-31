// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductsTable get products => attachedDatabase.products;
  $ProductUnitsTable get productUnits => attachedDatabase.productUnits;
  ProductDriftDaoManager get managers => ProductDriftDaoManager(this);
}

class ProductDriftDaoManager {
  final _$ProductDriftDaoMixin _db;
  ProductDriftDaoManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ProductUnitsTableTableManager get productUnits =>
      $$ProductUnitsTableTableManager(_db.attachedDatabase, _db.productUnits);
}
