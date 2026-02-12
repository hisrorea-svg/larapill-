import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/debts_repository_impl.dart';
import '../../domain/entities/customer_debt.dart';
import '../../domain/entities/debts_stats.dart';
import '../../domain/entities/debt_status.dart';
import '../../domain/entities/debts_search_result.dart';

// ============ Filter State ============

/// نوع الترتيب
enum DebtSortType {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
}

/// حالة الفلتر
class DebtFilterState {
  final String searchQuery;
  final DebtStatus? statusFilter;
  final DebtSortType sortType;

  const DebtFilterState({
    this.searchQuery = '',
    this.statusFilter,
    this.sortType = DebtSortType.newest,
  });

  DebtFilterState copyWith({
    String? searchQuery,
    DebtStatus? statusFilter,
    bool clearStatusFilter = false,
    DebtSortType? sortType,
  }) {
    return DebtFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      sortType: sortType ?? this.sortType,
    );
  }
}

/// حالة Pagination
class DebtPaginationState {
  final int currentPage;
  final int pageSize;
  final bool isLoadingMore;
  final bool hasMore;

  const DebtPaginationState({
    this.currentPage = 0,
    this.pageSize = 20,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  DebtPaginationState copyWith({
    int? currentPage,
    int? pageSize,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return DebtPaginationState(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ============ Providers ============

/// Provider لحالة الفلتر
final debtFilterProvider = StateProvider<DebtFilterState>((ref) {
  return const DebtFilterState();
});

/// Provider لحالة Pagination
final debtPaginationProvider = StateProvider<DebtPaginationState>((ref) {
  return const DebtPaginationState();
});

/// Provider للإحصائيات الموسعة
final debtsStatsProvider = FutureProvider<DebtsStats>((ref) async {
  final repository = ref.watch(debtsRepositoryProvider);
  return await repository.getDebtsStats();
});

/// Provider للبحث المؤجل (Debounced) - PROFESSIONAL
final _debouncedSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider لتشغيل Debounce
final debouncedSearchProvider = Provider<void>((ref) {
  final filter = ref.watch(debtFilterProvider);

  // Debounce 300ms
  Future.delayed(const Duration(milliseconds: 300), () {
    final currentFilter = ref.read(debtFilterProvider);
    if (currentFilter.searchQuery == filter.searchQuery) {
      ref.read(_debouncedSearchQueryProvider.notifier).state =
          filter.searchQuery;
      // Reset pagination when search changes
      ref.read(debtPaginationProvider.notifier).state =
          const DebtPaginationState();
    }
  });
});

/// Provider لنتائج البحث مع Pagination - PROFESSIONAL PERFORMANCE
final paginatedDebtsProvider = FutureProvider<DebtsSearchResult>((ref) async {
  // Watch debounced query
  final debouncedQuery = ref.watch(_debouncedSearchQueryProvider);
  final filter = ref.watch(debtFilterProvider);
  final pagination = ref.watch(debtPaginationProvider);
  final repository = ref.watch(debtsRepositoryProvider);

  // Perform paginated search
  return await repository.searchDebts(
    query: debouncedQuery,
    status: filter.statusFilter,
    sortType: filter.sortType,
    page: pagination.currentPage,
    pageSize: pagination.pageSize,
  );
});

/// Provider للديون الحالية (من نتيجة البحث)
final currentDebtsProvider = Provider<List<CustomerDebt>>((ref) {
  final result = ref.watch(paginatedDebtsProvider);
  return result.maybeWhen(
    data: (data) => data.debts,
    orElse: () => [],
  );
});

/// Provider لعدد الديون حسب الحالة - OPTIMIZED (Single DB Call)
final debtCountsByStatusProvider =
    FutureProvider<Map<DebtStatus, int>>((ref) async {
  final repository = ref.watch(debtsRepositoryProvider);
  return await repository.getDebtsCountsByStatus();
});

/// Provider لأعلى 5 مدينين - OPTIMIZED
final topDebtorsProvider = FutureProvider<List<CustomerDebt>>((ref) async {
  final repository = ref.watch(debtsRepositoryProvider);
  final result = await repository.searchDebts(
    sortType: DebtSortType.highestAmount,
    pageSize: 5,
  );
  return result.debts;
});

/// Provider للـ total count
final debtsTotalCountProvider = Provider<int>((ref) {
  final result = ref.watch(paginatedDebtsProvider);
  return result.maybeWhen(
    data: (data) => data.totalCount,
    orElse: () => 0,
  );
});

// ============ Actions Provider ============

/// Provider للأفعال (Actions)
final debtActionsProvider = Provider<DebtActions>((ref) {
  return DebtActions(ref);
});

class DebtActions {
  final Ref ref;

  DebtActions(this.ref);

  /// Load next page
  Future<void> loadNextPage() async {
    final pagination = ref.read(debtPaginationProvider);
    if (pagination.isLoadingMore || !pagination.hasMore) return;

    ref.read(debtPaginationProvider.notifier).state = pagination.copyWith(
      isLoadingMore: true,
    );

    // Load will happen automatically via provider
    final result = await ref.read(paginatedDebtsProvider.future);

    ref.read(debtPaginationProvider.notifier).state = pagination.copyWith(
      currentPage: pagination.currentPage + 1,
      isLoadingMore: false,
      hasMore: result.hasMore,
    );
  }

  /// Reset pagination
  void resetPagination() {
    ref.read(debtPaginationProvider.notifier).state =
        const DebtPaginationState();
  }

  /// Refresh all data
  Future<void> refresh() async {
    resetPagination();
    ref.invalidate(paginatedDebtsProvider);
    ref.invalidate(debtsStatsProvider);
    ref.invalidate(debtCountsByStatusProvider);
  }

  /// Update search query
  void setSearchQuery(String query) {
    ref.read(debtFilterProvider.notifier).state =
        ref.read(debtFilterProvider).copyWith(searchQuery: query);
    // Debounce will handle the rest
  }

  /// Set status filter
  void setStatusFilter(DebtStatus? status) {
    ref.read(debtFilterProvider.notifier).state =
        ref.read(debtFilterProvider).copyWith(
              statusFilter: status,
              clearStatusFilter: status == null,
            );
    resetPagination();
  }

  /// Set sort type
  void setSortType(DebtSortType sortType) {
    ref.read(debtFilterProvider.notifier).state =
        ref.read(debtFilterProvider).copyWith(sortType: sortType);
    resetPagination();
  }
}
