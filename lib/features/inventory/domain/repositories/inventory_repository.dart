import '../entities/add_product_params.dart';
import '../entities/product_entity.dart';
import '../entities/inventory_stats.dart';
import '../entities/paginated_result.dart';
import '../failures/inventory_failure.dart';

/// Either type for functional error handling
/// Left = Failure, Right = Success value
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isRight;

  const Either.left(L value)
      : _left = value,
        _right = null,
        _isRight = false;

  const Either.right(R value)
      : _left = null,
        _right = value,
        _isRight = true;

  bool get isLeft => !_isRight;
  bool get isRight => _isRight;

  L get left {
    if (_isRight) throw StateError('Cannot get left from Right');
    return _left as L;
  }

  R get right {
    if (!_isRight) throw StateError('Cannot get right from Left');
    return _right as R;
  }

  /// Fold the Either into a single value
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    return _isRight ? onRight(_right as R) : onLeft(_left as L);
  }

  /// Map the right value
  Either<L, T> map<T>(T Function(R) mapper) {
    return _isRight
        ? Either.right(mapper(_right as R))
        : Either.left(_left as L);
  }

  /// FlatMap the right value
  Either<L, T> flatMap<T>(Either<L, T> Function(R) mapper) {
    return _isRight ? mapper(_right as R) : Either.left(_left as L);
  }

  /// Get right value or default
  R getOrElse(R defaultValue) => _isRight ? _right as R : defaultValue;

  /// Get right value or compute default
  R getOrDefault(R Function() defaultFn) =>
      _isRight ? _right as R : defaultFn();
}

/// Unit type for void operations
class Unit {
  const Unit._();
  static const Unit unit = Unit._();
}

/// Repository interface for inventory operations
/// All methods return Either for typed error handling
abstract class InventoryRepository {
  // ============ CRUD Operations ============

  /// Add a new product to inventory
  /// Returns the created product with assigned ID
  Future<Either<InventoryFailure, ProductEntity>> addProduct(
      AddProductParams params);

  /// Update an existing product
  /// Returns the updated product
  Future<Either<InventoryFailure, ProductEntity>> updateProduct(
      ProductEntity product);

  /// Delete a product by ID
  /// Returns Unit on success
  Future<Either<InventoryFailure, Unit>> deleteProduct(int id);

  /// Get a product by ID
  /// Returns null if not found (not an error)
  Future<Either<InventoryFailure, ProductEntity?>> getProductById(int id);

  /// Get a product by barcode
  /// Returns null if not found (not an error)
  Future<Either<InventoryFailure, ProductEntity?>> getProductByBarcode(
      String barcode);

  // ============ Query Operations ============

  /// Get all products
  Future<Either<InventoryFailure, List<ProductEntity>>> getAllProducts();

  /// Search products by query (name, company, barcode)
  Future<Either<InventoryFailure, List<ProductEntity>>> searchProducts(
      String query);

  /// Get products by category
  Future<Either<InventoryFailure, List<ProductEntity>>> getProductsByCategory(
      String category);

  /// Get low stock products (quantity < threshold)
  Future<Either<InventoryFailure, List<ProductEntity>>> getLowStockProducts(
      {int threshold = 20});

  /// Get expired products
  Future<Either<InventoryFailure, List<ProductEntity>>> getExpiredProducts();

  /// Get products expiring soon (within days)
  Future<Either<InventoryFailure, List<ProductEntity>>> getExpiringSoonProducts(
      {int days = 90});

  /// Get products with filtering and pagination (scalable for large datasets)
  /// Filtering happens at database level for better performance
  Future<Either<InventoryFailure, PaginatedResult<ProductEntity>>>
      getProductsFiltered(InventoryFilterParams params);

  // ============ Statistics ============

  /// Get inventory statistics
  Future<Either<InventoryFailure, InventoryStatsEntity>> getInventoryStats();

  // ============ Offline-First / Sync ============

  /// Sync pending changes to remote server
  /// Returns number of synced items
  Future<Either<InventoryFailure, int>> syncPendingChanges();

  /// Get count of pending sync operations
  Future<Either<InventoryFailure, int>> getPendingSyncCount();

  /// Watch products for real-time updates
  Stream<List<ProductEntity>> watchProducts();

  /// Watch a single product for real-time updates
  Stream<ProductEntity?> watchProduct(int id);
}
