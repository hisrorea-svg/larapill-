import 'customer_debt.dart';

/// نتيجة البحث مع Pagination
class DebtsSearchResult {
  final List<CustomerDebt> debts;
  final int totalCount;
  final bool hasMore;

  const DebtsSearchResult({
    required this.debts,
    required this.totalCount,
    required this.hasMore,
  });

  /// Empty result
  factory DebtsSearchResult.empty() => const DebtsSearchResult(
        debts: [],
        totalCount: 0,
        hasMore: false,
      );

  /// Calculate total pages
  int getTotalPages(int pageSize) => (totalCount / pageSize).ceil();

  /// Check if has debts
  bool get isEmpty => debts.isEmpty;
  bool get isNotEmpty => debts.isNotEmpty;

  DebtsSearchResult copyWith({
    List<CustomerDebt>? debts,
    int? totalCount,
    bool? hasMore,
  }) {
    return DebtsSearchResult(
      debts: debts ?? this.debts,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
