// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_ledger_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$SupplierLedgerDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $SupplierLedgerTable get supplierLedger => attachedDatabase.supplierLedger;
  SupplierLedgerDriftDaoManager get managers =>
      SupplierLedgerDriftDaoManager(this);
}

class SupplierLedgerDriftDaoManager {
  final _$SupplierLedgerDriftDaoMixin _db;
  SupplierLedgerDriftDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$SupplierLedgerTableTableManager get supplierLedger =>
      $$SupplierLedgerTableTableManager(
          _db.attachedDatabase, _db.supplierLedger);
}
