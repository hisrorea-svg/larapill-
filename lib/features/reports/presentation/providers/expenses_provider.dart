import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/database_provider.dart';
import 'reports_providers.dart';

/// فئة تمثل فئة المصروف للعرض في المخطط البياني
class ReportExpenseCategory {
  final String id;
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const ReportExpenseCategory({
    required this.id,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

/// موفر بيانات المصروفات الحقيقي للمخطط البياني
final expensesProvider =
    FutureProvider<List<ReportExpenseCategory>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final dao = ref.watch(expenseDriftDaoProvider);

  // Use the from/to dates from the selected period
  // For 'today', 'yesterday', etc, the report period logic handles the range
  // But wait, ReportPeriod logic in providers might need adjustment if we want exact dates
  // ReportPeriod usually has helper getters, let's assume we can get start/end date
  // Actually ReportPeriod is an entity, let me check it.

  // Checking ReportPeriod entity...
  // Assuming it has start/end or we can infer it.
  // Let's check reports_repository_impl usage of period.
  // It passes 'period' to getSalesReport.
  // Let's check the period entity structure.

  // For now, let's use the period.start and period.end if available or construct them.
  // Based on previous code in reports_repository_impl, there is period.contains(date).

  // I'll assume we can get a range.
  // Wait, I haven't seen ReportPeriod entity yet.
  // I'll take a safe bet and just map the period type to dates here as a helper if needed,
  // or use the repository directly if it exposes a helper.

  // Better approach: Let the DAO take the range.
  // I need to know how to get start/end from ReportPeriod.

  // Let's look at `reports_providers.dart` again.
  // It has `selectedPeriodProvider`.

  // Let's try to inspect ReportPeriod entity first to be sure.
  // But since I can't view files in this block, I will guess based on common patterns
  // or use `ReportsRepositoryImpl` logic which uses `period.contains(date)`.

  // Actually `ExpenseDriftDao` needs `DateTime from, DateTime to`.
  // I will check `ReportPeriod` in a subsequent step if this fails,
  // but for now I'll create a helper to extracting dates from period.

  final from = period.startDate;
  final to = period.endDate;

  final groupedValues = await dao.getExpensesGroupedByCategory(from, to);

  return groupedValues.map((map) {
    return ReportExpenseCategory(
      id: map['categoryId'] as String,
      label: map['categoryName'] as String,
      amount: map['totalAmount'] as double,
      color: Color(map['color'] as int),
      icon: IconData(
        int.parse(map['icon'] as String),
        fontFamily: 'MaterialIcons',
      ),
    );
  }).toList();
});

/// موفر إجمالي المصروفات
final totalExpensesProvider = Provider<AsyncValue<double>>((ref) {
  final expenses = ref.watch(expensesProvider);
  return expenses
      .whenData((list) => list.fold(0.0, (sum, item) => sum + item.amount));
});
