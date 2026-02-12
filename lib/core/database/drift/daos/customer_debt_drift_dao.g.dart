// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_debt_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomerDebtDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomerDebtsTable get customerDebts => attachedDatabase.customerDebts;
  CustomerDebtDriftDaoManager get managers => CustomerDebtDriftDaoManager(this);
}

class CustomerDebtDriftDaoManager {
  final _$CustomerDebtDriftDaoMixin _db;
  CustomerDebtDriftDaoManager(this._db);
  $$CustomerDebtsTableTableManager get customerDebts =>
      $$CustomerDebtsTableTableManager(_db.attachedDatabase, _db.customerDebts);
}
