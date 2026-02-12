// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_purchase_request_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyPurchaseRequestDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductsTable get products => attachedDatabase.products;
  $DailyPurchaseRequestsTable get dailyPurchaseRequests =>
      attachedDatabase.dailyPurchaseRequests;
  DailyPurchaseRequestDriftDaoManager get managers =>
      DailyPurchaseRequestDriftDaoManager(this);
}

class DailyPurchaseRequestDriftDaoManager {
  final _$DailyPurchaseRequestDriftDaoMixin _db;
  DailyPurchaseRequestDriftDaoManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$DailyPurchaseRequestsTableTableManager get dailyPurchaseRequests =>
      $$DailyPurchaseRequestsTableTableManager(
          _db.attachedDatabase, _db.dailyPurchaseRequests);
}
