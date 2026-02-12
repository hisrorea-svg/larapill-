import '../data/models/product_model.dart';

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

/// Interface for inventory sync API
/// Used for server synchronization in multi-terminal setup
abstract class InventorySyncApi {
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
