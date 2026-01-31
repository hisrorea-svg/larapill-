import 'dart:async';

import 'package:larapill/features/inventory/data/datasources/inventory_datasource_interface.dart';
import 'package:larapill/features/inventory/data/models/inventory_stats_model.dart';
import 'package:larapill/features/inventory/data/models/product_model.dart';

/// Mock implementation of InventoryLocalDataSource for testing
class MockInventoryLocalDataSource implements InventoryLocalDataSource {
  final List<ProductModel> _products = [];
  final List<Map<String, dynamic>> _syncQueue = [];
  InventoryStatsModel _stats = const InventoryStatsModel(
    totalProducts: 0,
    lowStockCount: 0,
    criticalStockCount: 0,
    outOfStockCount: 0,
    expiredCount: 0,
    expiringSoonCount: 0,
    inventoryValue: 0.0,
    totalCost: 0.0,
    expectedProfit: 0.0,
    pendingSyncCount: 0,
  );

  final _productsController = StreamController<List<ProductModel>>.broadcast();
  final Map<int, StreamController<ProductModel?>> _productControllers = {};

  bool shouldThrowCacheException = false;
  String cacheExceptionMessage = 'Cache error';

  void reset() {
    _products.clear();
    _syncQueue.clear();
    shouldThrowCacheException = false;
    cacheExceptionMessage = 'Cache error';
  }

  void setProducts(List<ProductModel> products) {
    _products.clear();
    _products.addAll(products);
    _notifyProductsChanged();
  }

  void setStats(InventoryStatsModel stats) {
    _stats = stats;
  }

  void throwCacheException(String message) {
    shouldThrowCacheException = true;
    cacheExceptionMessage = message;
  }

  void _checkForException() {
    if (shouldThrowCacheException) {
      throw CacheException(cacheExceptionMessage);
    }
  }

  void _notifyProductsChanged() {
    if (!_productsController.isClosed) {
      _productsController.add(List.unmodifiable(_products));
    }
  }

  void _notifyProductChanged(int id, ProductModel? product) {
    final controller = _productControllers[id];
    if (controller != null && !controller.isClosed) {
      controller.add(product);
    }
  }

  @override
  Future<ProductModel> insertProduct(ProductModel product) async {
    _checkForException();
    // Use the provided id if it's not empty, otherwise generate one
    final String newId = product.id.isNotEmpty
        ? product.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final newProduct = ProductModel(
      id: newId,
      name: product.name,
      scientificName: product.scientificName,
      company: product.company,
      category: product.category,
      barcode: product.barcode,
      baseUnit: product.baseUnit,
      currentStock: product.currentStock,
      minStockLevel: product.minStockLevel,
      expiryDate: product.expiryDate,
      productionDate: product.productionDate,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      isActive: product.isActive,
      sellingPrice: product.sellingPrice,
      costPrice: product.costPrice,
    );
    _products.add(newProduct);
    _notifyProductsChanged();
    _notifyProductChanged(int.tryParse(newId) ?? 0, newProduct);
    return newProduct;
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    _checkForException();
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw CacheException('Product not found');
    }
    final updatedProduct = ProductModel(
      id: product.id,
      name: product.name,
      scientificName: product.scientificName,
      company: product.company,
      category: product.category,
      barcode: product.barcode,
      baseUnit: product.baseUnit,
      currentStock: product.currentStock,
      minStockLevel: product.minStockLevel,
      expiryDate: product.expiryDate,
      productionDate: product.productionDate,
      createdAt: _products[index].createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      isActive: product.isActive,
      sellingPrice: product.sellingPrice,
      costPrice: product.costPrice,
    );
    _products[index] = updatedProduct;
    _notifyProductsChanged();
    final productIdInt = int.tryParse(product.id);
    if (productIdInt != null) {
      _notifyProductChanged(productIdInt, updatedProduct);
    }
    return updatedProduct;
  }

  @override
  Future<void> deleteProduct(int id) async {
    _checkForException();
    _products.removeWhere((p) => p.id == id.toString());
    _notifyProductsChanged();
    _notifyProductChanged(id, null);
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    _checkForException();
    try {
      return _products.firstWhere((p) => p.id == id.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    _checkForException();
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    _checkForException();
    return List.unmodifiable(_products);
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    _checkForException();
    final lowerQuery = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            p.company.toLowerCase().contains(lowerQuery) ||
            p.barcode.toLowerCase().contains(lowerQuery) ||
            p.category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    _checkForException();
    return _products.where((p) => p.category == category).toList();
  }

  @override
  Future<List<ProductModel>> getLowStockProducts(int threshold) async {
    _checkForException();
    return _products.where((p) => p.currentStock <= threshold).toList();
  }

  @override
  Future<List<ProductModel>> getExpiredProducts() async {
    _checkForException();
    final now = DateTime.now();
    return _products.where((p) {
      if (p.expiryDate == null) return false;
      final expiry = DateTime.tryParse(p.expiryDate!);
      return expiry != null && expiry.isBefore(now);
    }).toList();
  }

  @override
  Future<List<ProductModel>> getExpiringSoonProducts(int days) async {
    _checkForException();
    final now = DateTime.now();
    final warningDate = now.add(Duration(days: days));
    return _products.where((p) {
      if (p.expiryDate == null) return false;
      final expiry = DateTime.tryParse(p.expiryDate!);
      return expiry != null &&
          expiry.isAfter(now) &&
          expiry.isBefore(warningDate);
    }).toList();
  }

  @override
  Future<(List<ProductModel>, int)> getProductsFiltered({
    String? searchQuery,
    String? categoryEnumName,
    String? stockFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    _checkForException();
    var filtered = _products.toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              p.company.toLowerCase().contains(lowerQuery) ||
              p.barcode.toLowerCase().contains(lowerQuery))
          .toList();
    }

    if (categoryEnumName != null && categoryEnumName.isNotEmpty) {
      filtered = filtered.where((p) => p.category == categoryEnumName).toList();
    }

    if (stockFilter != null && stockFilter.isNotEmpty) {
      switch (stockFilter) {
        case 'low_stock':
          filtered = filtered.where((p) => p.currentStock <= 20).toList();
          break;
        case 'critical_stock':
          filtered = filtered.where((p) => p.currentStock <= 10).toList();
          break;
        case 'out_of_stock':
          filtered = filtered.where((p) => p.currentStock == 0).toList();
          break;
      }
    }

    final totalCount = filtered.length;
    final paginated = filtered.skip(offset).take(limit).toList();
    return (paginated, totalCount);
  }

  @override
  Future<InventoryStatsModel> calculateStats() async {
    _checkForException();
    return _stats;
  }

  @override
  Future<void> markAsSynced(int productId) async {
    _checkForException();
  }

  @override
  Future<void> addToSyncQueue(int productId, SyncAction action) async {
    _checkForException();
    _syncQueue.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'product_id': productId,
      'action': action.name,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    _checkForException();
    return List.unmodifiable(_syncQueue);
  }

  @override
  Future<void> removeSyncOperation(int operationId) async {
    _checkForException();
    _syncQueue.removeWhere((op) => op['id'] == operationId);
  }

  @override
  Future<int> getPendingSyncCount() async {
    _checkForException();
    return _syncQueue.length;
  }

  @override
  Stream<List<ProductModel>> watchProducts() {
    return _productsController.stream;
  }

  @override
  Stream<ProductModel?> watchProduct(int id) {
    if (!_productControllers.containsKey(id)) {
      _productControllers[id] = StreamController<ProductModel?>.broadcast();
    }
    return _productControllers[id]!.stream;
  }

  void dispose() {
    _productsController.close();
    for (final controller in _productControllers.values) {
      controller.close();
    }
    _productControllers.clear();
  }
}

/// Mock implementation of InventoryRemoteDataSource for testing
class MockInventoryRemoteDataSource implements InventoryRemoteDataSource {
  final List<ProductModel> _remoteProducts = [];
  bool _isServerReachable = true;
  bool shouldThrowServerException = false;
  String serverExceptionMessage = 'Server error';
  int _syncedCount = 0;

  void reset() {
    _remoteProducts.clear();
    _isServerReachable = true;
    shouldThrowServerException = false;
    serverExceptionMessage = 'Server error';
    _syncedCount = 0;
  }

  void setServerReachable(bool reachable) {
    _isServerReachable = reachable;
  }

  void setRemoteProducts(List<ProductModel> products) {
    _remoteProducts.clear();
    _remoteProducts.addAll(products);
  }

  void throwServerException(String message) {
    shouldThrowServerException = true;
    serverExceptionMessage = message;
  }

  void _checkForException() {
    if (shouldThrowServerException) {
      throw ServerException(serverExceptionMessage);
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    _checkForException();
    _remoteProducts.add(product);
    return product;
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    _checkForException();
    final index = _remoteProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _remoteProducts[index] = product;
    }
    return product;
  }

  @override
  Future<void> deleteProduct(int id) async {
    _checkForException();
    _remoteProducts.removeWhere((p) => p.id == id.toString());
  }

  @override
  Future<List<ProductModel>> fetchAllProducts() async {
    _checkForException();
    return List.unmodifiable(_remoteProducts);
  }

  @override
  Future<int> syncChanges(List<Map<String, dynamic>> operations) async {
    _checkForException();
    _syncedCount = operations.length;
    return _syncedCount;
  }

  @override
  Future<bool> isServerReachable() async {
    _checkForException();
    return _isServerReachable;
  }

  int get syncedCount => _syncedCount;
}
