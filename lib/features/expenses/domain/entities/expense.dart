/// كيان المصروف
class Expense {
  final String id;
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final String categoryIcon;
  final double amount;
  final DateTime date;
  final String? note;
  final bool isRecurring;
  final int? recurringDay;

  const Expense({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.amount,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringDay,
  });
}
