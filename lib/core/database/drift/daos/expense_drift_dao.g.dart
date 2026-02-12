// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_drift_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpenseDriftDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpenseCategoriesTable get expenseCategories =>
      attachedDatabase.expenseCategories;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  ExpenseDriftDaoManager get managers => ExpenseDriftDaoManager(this);
}

class ExpenseDriftDaoManager {
  final _$ExpenseDriftDaoMixin _db;
  ExpenseDriftDaoManager(this._db);
  $$ExpenseCategoriesTableTableManager get expenseCategories =>
      $$ExpenseCategoriesTableTableManager(
          _db.attachedDatabase, _db.expenseCategories);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
}
