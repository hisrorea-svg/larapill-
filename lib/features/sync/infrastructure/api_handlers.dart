import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:shelf/shelf.dart';

import '../../../database/daos/product_dao.dart';
import '../../../services/sales_service.dart';
import '../../../features/pos/domain/entities/sale.dart';
import 'sync_constants.dart';

/// API handlers for sync server endpoints
class ApiHandlers {
  final ProductDAO _productDao;
  final SalesService _salesService;

  // Track registered terminals
  final _registeredTerminals = <String, DateTime>{};

  ApiHandlers({
    ProductDAO? productDao,
    SalesService? salesService,
  })  : _productDao = productDao ?? ProductDAO(),
        _salesService = salesService ?? SalesService();

  /// Health check endpoint
  Future<Response> health(Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
        'connectedTerminals': _registeredTerminals.length,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Get compressed product snapshot
  Future<Response> productsSnapshot(Request request) async {
    try {
      final products = await _productDao.findAll();

      // Convert to JSON
      final productsJson = products.map((p) => p.toMap()).toList();
      final jsonStr = jsonEncode({
        'products': productsJson,
        'timestamp': DateTime.now().toIso8601String(),
        'count': products.length,
      });

      // Compress with gzip
      final bytes = utf8.encode(jsonStr);
      final compressed = GZipEncoder().encode(bytes);

      if (compressed == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Compression failed'}),
        );
      }

      developer.log(
        'Sending snapshot: ${products.length} products, ${(compressed.length / 1024).toStringAsFixed(1)} KB',
        name: 'ApiHandlers',
      );

      return Response.ok(
        compressed,
        headers: {
          'Content-Type': 'application/gzip',
          'Content-Encoding': 'gzip',
        },
      );
    } catch (e, stack) {
      developer.log('Error in productsSnapshot: $e',
          name: 'ApiHandlers', stackTrace: stack);
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Get products with optional filtering (incremental sync)
  Future<Response> products(Request request) async {
    try {
      final sinceParam = request.url.queryParameters['since'];
      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];

      final limit = int.tryParse(limitParam ?? '') ?? 100;
      final offset = int.tryParse(offsetParam ?? '') ?? 0;
      final since = sinceParam != null ? DateTime.tryParse(sinceParam) : null;

      // Get all products (filtering would be applied if updatedAt exists)
      var products = await _productDao.findAll();

      // TODO: Filter by since date when updatedAt is available
      // Currently not used but will be needed for incremental sync
      // ignore: unused_local_variable
      final sinceFilter = since;
      // if (since != null) {
      //   products = products.where((p) => p.updatedAt.isAfter(since)).toList();
      // }

      // Apply pagination
      final paginated = products.skip(offset).take(limit).toList();

      return Response.ok(
        jsonEncode({
          'products': paginated.map((p) => p.toMap()).toList(),
          'total': products.length,
          'limit': limit,
          'offset': offset,
          'hasMore': offset + paginated.length < products.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      developer.log('Error in products: $e',
          name: 'ApiHandlers', stackTrace: stack);
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Receive sales from terminals
  Future<Response> receiveSales(Request request) async {
    try {
      final terminalId = request.headers[SyncHeaders.terminalId] ?? 'unknown';
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final salesData = data['sales'] as List? ?? [];
      var receivedCount = 0;
      var errorCount = 0;

      for (final saleJson in salesData) {
        try {
          // Parse and save sale
          if (saleJson is Map<String, dynamic>) {
            final sale = Sale.fromMap(saleJson);
            await _salesService.saveSale(sale);
            receivedCount++;
          }
        } catch (e) {
          developer.log('Error processing sale: $e', name: 'ApiHandlers');
          errorCount++;
        }
      }

      developer.log(
        'Received $receivedCount sales from terminal $terminalId (errors: $errorCount)',
        name: 'ApiHandlers',
      );

      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'received': receivedCount,
          'errors': errorCount,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      developer.log('Error in receiveSales: $e',
          name: 'ApiHandlers', stackTrace: stack);
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Get stock for a product
  Future<Response> getStock(Request request, String productId) async {
    try {
      final product = await _productDao.findById(productId);

      if (product == null) {
        return Response.notFound(
          jsonEncode({'error': 'Product not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'productId': productId,
          'stock': product.currentStock,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      developer.log('Error in getStock: $e',
          name: 'ApiHandlers', stackTrace: stack);
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Register a terminal
  Future<Response> registerTerminal(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final terminalId = data['terminalId'] as String?;
      final terminalName = data['name'] as String?;
      final terminalType = data['type'] as String?;

      if (terminalId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'terminalId is required'}),
        );
      }

      // Register terminal
      _registeredTerminals[terminalId] = DateTime.now();

      developer.log(
        'Terminal registered: $terminalName ($terminalId) as $terminalType',
        name: 'ApiHandlers',
      );

      // Get local IP for response
      String? serverIp;
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
          includeLoopback: false,
        );

        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.')) {
              serverIp = addr.address;
              break;
            }
          }
          if (serverIp != null) break;
        }
      } catch (_) {}

      return Response.ok(
        jsonEncode({
          'status': 'registered',
          'terminalId': terminalId,
          'serverIp': serverIp,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      developer.log('Error in registerTerminal: $e',
          name: 'ApiHandlers', stackTrace: stack);
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }
}
