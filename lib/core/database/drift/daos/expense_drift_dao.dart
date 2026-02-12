/// Expense Drift DAO - Type-safe database access for expenses
///
/// This DAO handles all expense and expense category operations.
library expense_drift_dao;

import 'package:drift/drift.dart';
import '../../../../../core/database/drift/app_database.dart';
import 'package:uuid/uuid.dart';

part 'expense_drift_dao.g.dart';

@DriftAccessor(tables: [Expenses, ExpenseCategories])
class ExpenseDriftDao extends DatabaseAccessor<AppDatabase>
    with _$ExpenseDriftDaoMixin {
  ExpenseDriftDao(super.db);

  // ============ Categories ============

  /// Get all categories
  Future<List<ExpenseCategoryEntry>> getAllCategories() {
    return (select(expenseCategories)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Insert a new category
  Future<void> insertCategory({
    required String name,
    String icon = '0xe1d5',
    int color = 0xFF5BA3A3,
  }) async {
    await into(expenseCategories).insert(
      ExpenseCategoriesCompanion.insert(
        id: const Uuid().v4(),
        name: name,
        icon: Value(icon),
        color: Value(color),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Update a category
  Future<void> updateCategory({
    required String id,
    required String name,
    required String icon,
    required int color,
  }) async {
    await (update(expenseCategories)..where((c) => c.id.equals(id))).write(
      ExpenseCategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        color: Value(color),
      ),
    );
  }

  /// Delete a category and its expenses
  Future<void> deleteCategory(String id) async {
    // Delete related expenses first
    await (delete(expenses)..where((e) => e.categoryId.equals(id))).go();
    await (delete(expenseCategories)..where((c) => c.id.equals(id))).go();
  }

  /// Seed default categories if none exist
  Future<void> seedDefaultCategories() async {
    final existing = await getAllCategories();
    if (existing.isNotEmpty) return;

    final defaults = [
      {'name': 'إيجار', 'icon': '0xe6b2', 'color': 0xFF5BA3A3},
      {'name': 'كهرباء وماء', 'icon': '0xe601', 'color': 0xFF2C5F8D},
      {'name': 'رواتب', 'icon': '0xe7ef', 'color': 0xFFF39C12},
      {'name': 'نواقص', 'icon': '0xe59a', 'color': 0xFFE74C3C},
      {'name': 'أخرى', 'icon': '0xe5d3', 'color': 0xFF95A5A6},
    ];

    for (final cat in defaults) {
      await insertCategory(
        name: cat['name'] as String,
        icon: cat['icon'] as String,
        color: cat['color'] as int,
      );
    }
  }

  // ============ Expenses ============

  /// Insert a new expense
  Future<void> insertExpense({
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    int? recurringDay,
  }) async {
    final now = DateTime.now();
    await into(expenses).insert(
      ExpensesCompanion.insert(
        id: const Uuid().v4(),
        categoryId: categoryId,
        amount: amount,
        date: date,
        note: Value(note),
        isRecurring: Value(isRecurring),
        recurringDay: Value(recurringDay),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Update an expense
  Future<void> updateExpense({
    required String id,
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
    bool isRecurring = false,
    int? recurringDay,
  }) async {
    await (update(expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        date: Value(date),
        note: Value(note),
        isRecurring: Value(isRecurring),
        recurringDay: Value(recurringDay),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    await (delete(expenses)..where((e) => e.id.equals(id))).go();
  }

  /// Get expenses by date range
  Future<List<ExpenseEntry>> getExpensesByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(expenses)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(from) &
              e.date.isSmallerOrEqualValue(to))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  /// Get expenses for a specific month
  Future<List<ExpenseEntry>> getExpensesByMonth(int year, int month) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    return getExpensesByDateRange(from, to);
  }

  /// Get total expenses for a date range
  Future<double> getTotalExpenses(DateTime from, DateTime to) async {
    final result = await (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.date.isBiggerOrEqualValue(from) &
              expenses.date.isSmallerOrEqualValue(to)))
        .getSingle();
    return result.read<double>(expenses.amount.sum()) ?? 0.0;
  }

  /// Get expenses grouped by category for a date range
  /// Returns a list of maps with categoryId, categoryName, color, icon, totalAmount
  Future<List<Map<String, dynamic>>> getExpensesGroupedByCategory(
    DateTime from,
    DateTime to,
  ) async {
    final query = select(expenses).join([
      innerJoin(
        expenseCategories,
        expenseCategories.id.equalsExp(expenses.categoryId),
      ),
    ]);

    query.where(
      expenses.date.isBiggerOrEqualValue(from) &
          expenses.date.isSmallerOrEqualValue(to),
    );

    final rows = await query.get();

    // Group manually
    final grouped = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final expense = row.readTable(expenses);
      final category = row.readTable(expenseCategories);

      if (grouped.containsKey(category.id)) {
        grouped[category.id]!['totalAmount'] =
            (grouped[category.id]!['totalAmount'] as double) + expense.amount;
      } else {
        grouped[category.id] = {
          'categoryId': category.id,
          'categoryName': category.name,
          'color': category.color,
          'icon': category.icon,
          'totalAmount': expense.amount,
        };
      }
    }

    return grouped.values.toList()
      ..sort((a, b) =>
          (b['totalAmount'] as double).compareTo(a['totalAmount'] as double));
  }

  /// Watch all expenses (live updates)
  Stream<List<ExpenseEntry>> watchAllExpenses() {
    return (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  /// Get an expense by ID
  Future<ExpenseEntry?> findById(String id) {
    return (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
  }
}
