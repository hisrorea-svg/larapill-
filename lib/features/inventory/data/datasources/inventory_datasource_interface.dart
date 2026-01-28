import '../models/product_model.dart';
import '../models/inventory_stats_model.dart';

/// Enum for sync actions in offline-first queue
enum SyncAction {
  create,
  update,
  delete,
}

/// Exception thrown by cache/local operations
class CacheException implements Exception {
  final String message;
  final String? code;

  const CacheException(this.message, [this.code]);

  @override
  String toString() => 'CacheException($code): $message';
}

/// Exception thrown by server/remote operations
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Interface for local data source (SQLite)
abstract class InventoryLocalDataSource {
  // ============ CRUD ============

  /// Insert a new product and return the inserted model with ID
  Future<ProductModel> insertProduct(ProductModel product);

  /// Update an existing product
  Future<ProductModel> updateProduct(ProductModel product);

  /// Delete a product by ID
  Future<void> deleteProduct(int id);

  /// Get a product by ID
  Future<ProductModel?> getProductById(int id);

  /// Get a product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode);

  // ============ Queries ============

  /// Get all products
  Future<List<ProductModel>> getAllProducts();

  /// Search products by query
  Future<List<ProductModel>> searchProducts(String query);

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category);

  /// Get products with low stock
  Future<List<ProductModel>> getLowStockProducts(int threshold);

  /// Get expired products
  Future<List<ProductModel>> getExpiredProducts();

  /// Get products expiring within days
  Future<List<ProductModel>> getExpiringSoonProducts(int days);

  /// Get products with filtering and pagination (scalable query)
  /// Returns tuple of (products, totalCount)
  Future<(List<ProductModel>, int)> getProductsFiltered({
    String? searchQuery,
    String? categoryEnumName,
    String? stockFilter,
    int limit = 50,
    int offset = 0,
  });

  // ============ Statistics ============

  /// Calculate inventory statistics from local data
  Future<InventoryStatsModel> calculateStats();

  // ============ Sync Queue ============

  /// Mark a product as synced
  Future<void> markAsSynced(int productId);

  /// Add an operation to the sync queue
  Future<void> addToSyncQueue(int productId, SyncAction action);

  /// Get pending sync operations
  Future<List<Map<String, dynamic>>> getPendingSyncOperations();

  /// Remove an operation from sync queue after successful sync
  Future<void> removeSyncOperation(int operationId);

  /// Get count of pending sync operations
  Future<int> getPendingSyncCount();

  // ============ Streams ============

  /// Watch all products for changes
  Stream<List<ProductModel>> watchProducts();

  /// Watch a single product for changes
  Stream<ProductModel?> watchProduct(int id);
}

/// Interface for remote data source (API)
/// Implemented when server sync is needed
abstract class InventoryRemoteDataSource {
  /// Create a product on the server
  Future<ProductModel> createProduct(ProductModel product);

  /// Update a product on the server
  Future<ProductModel> updateProduct(ProductModel product);

  /// Delete a product on the server
  Future<void> deleteProduct(int id);

  /// Fetch all products from server
  Future<List<ProductModel>> fetchAllProducts();

  /// Sync local changes to server
  /// Returns number of successfully synced items
  Future<int> syncChanges(List<Map<String, dynamic>> operations);

  /// Check if server is reachable
  Future<bool> isServerReachable();
}
