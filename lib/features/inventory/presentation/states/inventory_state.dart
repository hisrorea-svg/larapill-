import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/filter_products_usecase.dart';

/// State for the inventory list screen
/// Using sealed class for type-safe state handling
sealed class InventoryState {
  const InventoryState();
}

/// Initial state before loading
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Loading state
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// Loaded state with products and filter
class InventoryLoaded extends InventoryState {
  final List<ProductEntity> products;
  final ProductFilterParams filter;
  final int currentPage;
  final int pageSize;

  const InventoryLoaded({
    required this.products,
    this.filter = const ProductFilterParams.empty(),
    this.currentPage = 0,
    this.pageSize = 20,
  });

  /// Get paginated products for current page
  List<ProductEntity> get paginatedProducts {
    final start = currentPage * pageSize;
    final end = (start + pageSize) > products.length
        ? products.length
        : (start + pageSize);
    if (start >= products.length || start < 0) return [];
    return products.sublist(start, end);
  }

  /// Total pages
  int get totalPages {
    if (products.isEmpty) return 1;
    return ((products.length - 1) / pageSize).floor() + 1;
  }

  /// Create copy with modified fields
  InventoryLoaded copyWith({
    List<ProductEntity>? products,
    ProductFilterParams? filter,
    int? currentPage,
    int? pageSize,
  }) {
    return InventoryLoaded(
      products: products ?? this.products,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

/// Error state
class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);
}
