import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';

// ============ State Classes ============

/// State for expense management
class ExpensesManagementState {
  final DateTime selectedMonth;
  final AsyncValue<List<Expense>> expenses;
  final AsyncValue<List<ExpenseCategory>> categories;
  final double totalExpenses;

  ExpensesManagementState({
    required this.selectedMonth,
    required this.expenses,
    required this.categories,
    this.totalExpenses = 0,
  });

  ExpensesManagementState copyWith({
    DateTime? selectedMonth,
    AsyncValue<List<Expense>>? expenses,
    AsyncValue<List<ExpenseCategory>>? categories,
    double? totalExpenses,
  }) {
    return ExpensesManagementState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }
}

// ============ Providers ============

/// Main provider for expenses management screen
final expensesManagementProvider =
    StateNotifierProvider<ExpensesManagementNotifier, ExpensesManagementState>(
        (ref) {
  return ExpensesManagementNotifier(ref);
});

class ExpensesManagementNotifier
    extends StateNotifier<ExpensesManagementState> {
  final Ref _ref;

  ExpensesManagementNotifier(this._ref)
      : super(ExpensesManagementState(
          selectedMonth: DateTime.now(),
          expenses: const AsyncValue.loading(),
          categories: const AsyncValue.loading(),
        )) {
    _init();
  }

  // DAO Accessor
  // We use the provider here to ensure we get the correct instance
  // but accessing it lazily via ref.read inside methods is also fine
  // or storing it in the constructor if we watched it.
  // Using ref.read for actions is standard.

  Future<void> _init() async {
    await loadCategories();
    await loadExpenses();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    try {
      final dao = _ref.read(expenseDriftDaoProvider);
      // Ensure defaults exist
      await dao.seedDefaultCategories();

      final cats = await dao.getAllCategories();
      final domainCats = cats
          .map((c) => ExpenseCategory(
                id: c.id,
                name: c.name,
                icon: c.icon,
                color: c.color,
              ))
          .toList();

      state = state.copyWith(categories: AsyncValue.data(domainCats));
    } catch (e, st) {
      state = state.copyWith(categories: AsyncValue.error(e, st));
    }
  }

  /// Load expenses for the selected month
  Future<void> loadExpenses() async {
    state = state.copyWith(expenses: const AsyncValue.loading());
    try {
      final dao = _ref.read(expenseDriftDaoProvider);
      final from =
          DateTime(state.selectedMonth.year, state.selectedMonth.month, 1);
      final to = DateTime(state.selectedMonth.year,
          state.selectedMonth.month + 1, 0, 23, 59, 59);

      final entries = await dao.getExpensesByDateRange(from, to);
      final cats = state.categories.value ?? [];

      // We need to map entries to domain entities, joining with categories
      // Ideally DAO does this join, but for now we map manually since we have loaded categories
      // Or we could have used a join query in DAO.
      // The implemented DAO `getExpensesByDateRange` returns `ExpenseEntry`.
      // The DAO also has `getExpensesGroupedByCategory` but that's for charts.

      // Let's rely on categories being loaded.
      if (cats.isEmpty && !state.categories.isLoading) {
        await loadCategories();
      }

      // Re-fetch categories synchronously from current state or map
      final currentCats = state.categories.value ?? [];
      final catMap = {for (var c in currentCats) c.id: c};

      final domainExpenses = <Expense>[];
      double total = 0;

      for (final entry in entries) {
        final cat = catMap[entry.categoryId];
        // If category deleted, we might have an issue if FK set to CASCADE or similar
        // or just display "Unknown". For now assume category exists.

        domainExpenses.add(Expense(
          id: entry.id,
          categoryId: entry.categoryId,
          categoryName: cat?.name ?? 'Unknown',
          categoryColor: cat?.color ?? 0xFF9E9E9E,
          categoryIcon: cat?.icon ?? '0xe88f', // help icon default
          amount: entry.amount,
          date: entry.date,
          note: entry.note,
          isRecurring: entry.isRecurring,
          recurringDay: entry.recurringDay,
        ));
        total += entry.amount;
      }

      state = state.copyWith(
        expenses: AsyncValue.data(domainExpenses),
        totalExpenses: total,
      );
    } catch (e, st) {
      state = state.copyWith(expenses: AsyncValue.error(e, st));
    }
  }

  /// Change selected month
  void changeMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
    loadExpenses();
  }

  /// Add new expense
  Future<void> addExpense({
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
    bool isRecurring = false,
  }) async {
    try {
      final dao = _ref.read(expenseDriftDaoProvider);
      await dao.insertExpense(
        categoryId: categoryId,
        amount: amount,
        date: date,
        note: note,
        isRecurring: isRecurring,
        recurringDay: isRecurring ? date.day : null,
      );
      await loadExpenses();
    } catch (e) {
      // Handle error (show snackbar in UI)
      rethrow;
    }
  }

  /// Update an existing expense
  Future<void> updateExpense({
    required String id,
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
    bool isRecurring = false,
  }) async {
    try {
      final dao = _ref.read(expenseDriftDaoProvider);
      await dao.updateExpense(
        id: id,
        categoryId: categoryId,
        amount: amount,
        date: date,
        note: note,
        isRecurring: isRecurring,
        recurringDay: isRecurring ? date.day : null,
      );
      await loadExpenses();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      final dao = _ref.read(expenseDriftDaoProvider);
      await dao.deleteExpense(id);
      await loadExpenses();
    } catch (e) {
      rethrow;
    }
  }

  /// Add new category
  Future<void> addCategory({
    required String name,
    required int color,
    String icon = '0xe1d5',
  }) async {
    try {
      final dao = _ref.read(expenseDriftDaoProvider);
      await dao.insertCategory(name: name, color: color, icon: icon);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}
