import '../entities/product_entity.dart';
import '../enums/product_sort_type.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Filter parameters for products
class ProductFilterParams {
  final String? searchQuery;
  final String? category;
  final String? advancedFilter; // 'low_stock', 'expired', 'expiring_soon', etc.
  final ProductSortType sortBy;
  final bool ascending;

  const ProductFilterParams({
    this.searchQuery,
    this.category,
    this.advancedFilter,
    this.sortBy = ProductSortType.name,
    this.ascending = true,
  });

  /// Create empty filter
  const ProductFilterParams.empty()
      : searchQuery = null,
        category = null,
        advancedFilter = null,
        sortBy = ProductSortType.name,
        ascending = true;
}

/// Use case for filtering and sorting products
/// Encapsulates all filtering business rules
class FilterProductsUseCase {
  final InventoryRepository _repository;

  const FilterProductsUseCase(this._repository);

  /// Execute the use case
  Future<Either<InventoryFailure, List<ProductEntity>>> call(
      ProductFilterParams params) async {
    // 1. Get base list
    List<ProductEntity> products;

    // Get products based on search or category
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      final result = await _repository.searchProducts(params.searchQuery!);
      if (result.isLeft) return result;
      products = result.right;
    } else if (params.category != null && params.category!.isNotEmpty) {
      final result = await _repository.getProductsByCategory(params.category!);
      if (result.isLeft) return result;
      products = result.right;
    } else {
      final result = await _repository.getAllProducts();
      if (result.isLeft) return result;
      products = result.right;
    }

    // 2. Apply advanced filter
    if (params.advancedFilter != null) {
      products = _applyAdvancedFilter(products, params.advancedFilter!);
    }

    // 3. Sort
    products = _sortProducts(products, params.sortBy, params.ascending);

    return Either.right(products);
  }

  /// Apply advanced filter rules
  List<ProductEntity> _applyAdvancedFilter(
      List<ProductEntity> products, String filter) {
    switch (filter) {
      case 'low_stock':
        return products.where((p) => p.isLowStock).toList();

      case 'critical_stock':
        return products.where((p) => p.isCriticalStock).toList();

      case 'out_of_stock':
        return products.where((p) => p.isOutOfStock).toList();

      case 'expired':
        return products.where((p) => p.isExpired).toList();

      case 'expiring_soon':
        return products.where((p) => p.isExpiringSoon).toList();

      case 'high_price':
        // Return all, will be sorted by price descending
        return products;

      case 'low_price':
        // Return all, will be sorted by price ascending
        return products;

      case 'recently_added':
        // Return all, will be sorted by createdAt descending
        return products;

      case 'not_synced':
        return products.where((p) => !p.isSynced).toList();

      default:
        return products;
    }
  }

  /// Sort products by specified field
  List<ProductEntity> _sortProducts(
    List<ProductEntity> products,
    ProductSortType sortBy,
    bool ascending,
  ) {
    final sorted = List<ProductEntity>.from(products);

    sorted.sort((a, b) {
      int comparison;

      switch (sortBy) {
        case ProductSortType.name:
          comparison = a.name.compareTo(b.name);
        case ProductSortType.price:
          comparison = a.price.compareTo(b.price);
        case ProductSortType.quantity:
          comparison = a.quantity.compareTo(b.quantity);
        case ProductSortType.expiry:
          // Null expiry dates go to the end
          if (a.expiryDate == null && b.expiryDate == null) {
            comparison = 0;
          } else if (a.expiryDate == null) {
            comparison = 1;
          } else if (b.expiryDate == null) {
            comparison = -1;
          } else {
            comparison = a.expiryDate!.compareTo(b.expiryDate!);
          }
        case ProductSortType.category:
          comparison = a.category.compareTo(b.category);
        case ProductSortType.createdAt:
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
        case ProductSortType.updatedAt:
          final aDate = a.updatedAt ?? DateTime(1970);
          final bDate = b.updatedAt ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
      }

      return ascending ? comparison : -comparison;
    });

    return sorted;
  }
}
