import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/filter_products_usecase.dart';
import '../providers/inventory_providers.dart';
import '../states/inventory_state.dart';

/// Controller for the inventory list screen
/// Uses AsyncNotifier pattern for clean state management
class InventoryController extends AsyncNotifier<InventoryState> {
  @override
  Future<InventoryState> build() async {
    return _loadProducts();
  }

  /// Load products with current filter
  Future<InventoryState> _loadProducts([ProductFilterParams? filter]) async {
    final filterUseCase = ref.read(filterProductsUseCaseProvider);
    final params = filter ?? const ProductFilterParams.empty();

    final result = await filterUseCase(params);

    return result.fold(
      (failure) => InventoryError(failure.message),
      (products) => InventoryLoaded(
        products: products,
        filter: params,
      ),
    );
  }

  /// Refresh products
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProducts(_currentFilter));
  }

  /// Apply search query
  Future<void> search(String query) async {
    final newFilter = _currentFilter.copyWith(searchQuery: query);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProducts(newFilter));
    _resetPage();
  }

  /// Apply category filter
  Future<void> filterByCategory(String? category) async {
    final newFilter = _currentFilter.copyWith(category: category);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProducts(newFilter));
    _resetPage();
  }

  /// Apply advanced filter
  Future<void> applyAdvancedFilter(String? filter) async {
    final newFilter = _currentFilter.copyWith(advancedFilter: filter);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProducts(newFilter));
    _resetPage();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _loadProducts(const ProductFilterParams.empty()));
    _resetPage();
  }

  /// Go to next page
  void nextPage() {
    final currentState = state.valueOrNull;
    if (currentState is InventoryLoaded) {
      if (currentState.currentPage < currentState.totalPages - 1) {
        state = AsyncValue.data(
          currentState.copyWith(currentPage: currentState.currentPage + 1),
        );
      }
    }
  }

  /// Go to previous page
  void previousPage() {
    final currentState = state.valueOrNull;
    if (currentState is InventoryLoaded) {
      if (currentState.currentPage > 0) {
        state = AsyncValue.data(
          currentState.copyWith(currentPage: currentState.currentPage - 1),
        );
      }
    }
  }

  /// Go to specific page
  void goToPage(int page) {
    final currentState = state.valueOrNull;
    if (currentState is InventoryLoaded) {
      if (page >= 0 && page < currentState.totalPages) {
        state = AsyncValue.data(
          currentState.copyWith(currentPage: page),
        );
      }
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    developer.log('🗑️ Controller: Starting delete for ID: $id',
        name: 'InventoryController');

    final deleteUseCase = ref.read(deleteProductUseCaseProvider);
    final result = await deleteUseCase(id);

    result.fold(
      (failure) {
        developer.log('❌ Controller: Delete FAILED: ${failure.message}',
            name: 'InventoryController');
        // Rethrow to show error in UI
        throw Exception(failure.message);
      },
      (_) {
        developer.log('✅ Controller: Delete SUCCESS for ID: $id',
            name: 'InventoryController');
        // Refresh the list
        refresh();
      },
    );
  }

  // Helper to get current filter
  ProductFilterParams get _currentFilter {
    final currentState = state.valueOrNull;
    if (currentState is InventoryLoaded) {
      return currentState.filter;
    }
    return const ProductFilterParams.empty();
  }

  // Reset to first page
  void _resetPage() {
    final currentState = state.valueOrNull;
    if (currentState is InventoryLoaded && currentState.currentPage != 0) {
      state = AsyncValue.data(currentState.copyWith(currentPage: 0));
    }
  }
}

/// Extension for ProductFilterParams
extension ProductFilterParamsExt on ProductFilterParams {
  ProductFilterParams copyWith({
    String? searchQuery,
    String? category,
    String? advancedFilter,
  }) {
    return ProductFilterParams(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      advancedFilter: advancedFilter ?? this.advancedFilter,
      sortBy: sortBy,
      ascending: ascending,
    );
  }
}
