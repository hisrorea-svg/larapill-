/// Inventory Sync API Implementation
///
/// Uses the SyncServer API for remote product synchronization.
/// This implementation connects to the Master terminal in a multi-device setup.
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../data/models/product_model.dart';
import 'inventory_sync_interface.dart';

/// Exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException($statusCode): $message';
}

/// Implementation of [InventorySyncApi] using HTTP
///
/// Communicates with the SyncServer running on the Master terminal.
/// All operations include automatic retry with exponential backoff.
class InventorySyncApiImpl implements InventorySyncApi {
  final String _baseUrl;
  final http.Client _client;

  /// Maximum retry attempts for failed requests
  static const int _maxRetries = 3;

  /// Base delay for exponential backoff (milliseconds)
  static const int _baseDelayMs = 500;

  /// Creates a new [InventorySyncApiImpl]
  ///
  /// [baseUrl] should be the full URL including port (e.g., 'http://192.168.1.10:8080')
  InventorySyncApiImpl({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl.replaceAll(r'/$', ''), // Remove trailing slash
        _client = client ?? http.Client();

  // ============ Helper Methods ============

  /// Execute a request with retry logic
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await request();
        if (response.statusCode < 500) {
          return response; // Don't retry 4xx errors (client errors)
        }
        // Server error (5xx), retry with backoff
        if (attempt < _maxRetries - 1) {
          final delay = _baseDelayMs * (1 << attempt); // Exponential backoff
          await Future.delayed(Duration(milliseconds: delay));
        }
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          throw NetworkException(
              'Network error after $_maxRetries attempts: $e');
        }
        final delay = _baseDelayMs * (1 << attempt);
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    throw const NetworkException('Max retries exceeded');
  }

  /// Parse response and handle errors
  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ServerException(
      'Server returned ${response.statusCode}: ${response.body}',
      response.statusCode,
    );
  }

  // ============ CRUD Operations ============

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      developer.log(
        'Creating product on remote: ${product.name}',
        name: 'InventorySyncApi',
      );

      final response = await _executeWithRetry(() => _client.post(
            Uri.parse('$_baseUrl/api/products'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(product.toJson()),
          ));

      final data = _parseResponse(response);
      return ProductModel.fromJson(data);
    } catch (e) {
      developer.log(
        'Failed to create product: $e',
        name: 'InventorySyncApi',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      developer.log(
        'Updating product on remote: ${product.id}',
        name: 'InventorySyncApi',
      );

      final response = await _executeWithRetry(() => _client.put(
            Uri.parse('$_baseUrl/api/products/${product.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(product.toJson()),
          ));

      final data = _parseResponse(response);
      return ProductModel.fromJson(data);
    } catch (e) {
      developer.log(
        'Failed to update product: $e',
        name: 'InventorySyncApi',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      developer.log(
        'Deleting product on remote: $id',
        name: 'InventorySyncApi',
      );

      final response = await _executeWithRetry(() => _client.delete(
            Uri.parse('$_baseUrl/api/products/$id'),
          ));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Failed to delete product: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        'Failed to delete product: $e',
        name: 'InventorySyncApi',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> fetchAllProducts() async {
    try {
      developer.log(
        'Fetching all products from remote',
        name: 'InventorySyncApi',
      );

      final response = await _executeWithRetry(() => _client.get(
            Uri.parse('$_baseUrl/api/products'),
          ));

      final data = _parseResponse(response);
      final products = (data['products'] as List<dynamic>)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      developer.log(
        'Fetched ${products.length} products from remote',
        name: 'InventorySyncApi',
      );

      return products;
    } catch (e) {
      developer.log(
        'Failed to fetch products: $e',
        name: 'InventorySyncApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Fetch products updated since a specific date (for incremental sync)
  ///
  /// [since] - ISO8601 formatted datetime string
  Future<List<ProductModel>> fetchProductsSince(String since) async {
    try {
      developer.log(
        'Fetching products since: $since',
        name: 'InventorySyncApi',
      );

      final response = await _executeWithRetry(() => _client.get(
            Uri.parse('$_baseUrl/api/products?since=$since'),
          ));

      final data = _parseResponse(response);
      final products = (data['products'] as List<dynamic>)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      developer.log(
        'Fetched ${products.length} updated products from remote',
        name: 'InventorySyncApi',
      );

      return products;
    } catch (e) {
      developer.log(
        'Failed to fetch updated products: $e',
        name: 'InventorySyncApi',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<int> syncChanges(List<Map<String, dynamic>> operations) async {
    try {
      developer.log(
        'Syncing ${operations.length} changes to remote',
        name: 'InventorySyncApi',
      );

      final response = await _executeWithRetry(() => _client.post(
            Uri.parse('$_baseUrl/api/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'operations': operations}),
          ));

      final data = _parseResponse(response);
      final syncedCount = data['syncedCount'] as int? ?? 0;

      developer.log(
        'Successfully synced $syncedCount changes',
        name: 'InventorySyncApi',
      );

      return syncedCount;
    } catch (e) {
      developer.log(
        'Failed to sync changes: $e',
        name: 'InventorySyncApi',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<bool> isServerReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      developer.log(
        'Server not reachable: $e',
        name: 'InventorySyncApi',
      );
      return false;
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}
