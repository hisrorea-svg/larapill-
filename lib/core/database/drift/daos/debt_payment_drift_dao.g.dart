// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_payment_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$DebtPaymentDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomerDebtsTable get customerDebts => attachedDatabase.customerDebts;
  $DebtPaymentsTable get debtPayments => attachedDatabase.debtPayments;
  DebtPaymentDriftDaoManager get managers => DebtPaymentDriftDaoManager(this);
}

class DebtPaymentDriftDaoManager {
  final _$DebtPaymentDriftDaoMixin _db;
  DebtPaymentDriftDaoManager(this._db);
  $$CustomerDebtsTableTableManager get customerDebts =>
      $$CustomerDebtsTableTableManager(_db.attachedDatabase, _db.customerDebts);
  $$DebtPaymentsTableTableManager get debtPayments =>
      $$DebtPaymentsTableTableManager(_db.attachedDatabase, _db.debtPayments);
}
