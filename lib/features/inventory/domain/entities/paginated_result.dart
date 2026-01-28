/// Paginated result wrapper for efficient data loading
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  /// Total pages based on pageSize
  int get totalPages => (totalCount / pageSize).ceil();

  /// Has more pages
  bool get hasNextPage => currentPage < totalPages - 1;

  /// Has previous pages
  bool get hasPreviousPage => currentPage > 0;

  /// Is empty result
  bool get isEmpty => items.isEmpty;

  /// Create empty result
  factory PaginatedResult.empty({int pageSize = 50}) => PaginatedResult(
        items: const [],
        totalCount: 0,
        currentPage: 0,
        pageSize: pageSize,
      );
}

/// Filter parameters for inventory queries
/// Works with both local SQLite and remote API
class InventoryFilterParams {
  final String? searchQuery;
  final String? categoryEnumName; // e.g., "tablets", "syrups"
  final String?
      stockFilter; // "low_stock", "critical_stock", "out_of_stock", "expired", "expiring_soon"
  final int page;
  final int pageSize;

  const InventoryFilterParams({
    this.searchQuery,
    this.categoryEnumName,
    this.stockFilter,
    this.page = 0,
    this.pageSize = 50,
  });

  /// Calculate SQL OFFSET
  int get offset => page * pageSize;

  /// Check if any filter is active
  bool get hasActiveFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      (categoryEnumName?.isNotEmpty ?? false) ||
      (stockFilter?.isNotEmpty ?? false);

  /// Create copy with modifications
  InventoryFilterParams copyWith({
    String? searchQuery,
    String? categoryEnumName,
    String? stockFilter,
    int? page,
    int? pageSize,
  }) {
    return InventoryFilterParams(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryEnumName: categoryEnumName ?? this.categoryEnumName,
      stockFilter: stockFilter ?? this.stockFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Convert to API query params (for future remote sync)
  Map<String, dynamic> toQueryParams() {
    return {
      if (searchQuery != null && searchQuery!.isNotEmpty) 'search': searchQuery,
      if (categoryEnumName != null && categoryEnumName!.isNotEmpty)
        'category': categoryEnumName,
      if (stockFilter != null && stockFilter!.isNotEmpty) 'filter': stockFilter,
      'page': page,
      'limit': pageSize,
    };
  }

  @override
  String toString() =>
      'InventoryFilterParams(search: $searchQuery, category: $categoryEnumName, filter: $stockFilter, page: $page)';
}
