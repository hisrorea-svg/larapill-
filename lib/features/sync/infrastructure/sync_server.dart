import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'sync_constants.dart';
import 'api_handlers.dart';

/// HTTP Server for Master terminal
class SyncServer {
  HttpServer? _server;
  final ApiHandlers _handlers;

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get server port
  int? get port => _server?.port;

  /// Get server address
  String? get address => _server?.address.address;

  SyncServer({ApiHandlers? handlers}) : _handlers = handlers ?? ApiHandlers();

  /// Start the sync server
  Future<bool> start({int port = SyncConstants.defaultPort}) async {
    if (isRunning) {
      developer.log('Server already running on port $port', name: 'SyncServer');
      return true;
    }

    try {
      final router = _createRouter();
      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        port,
      );

      final server = _server;
      if (server != null) {
        developer.log(
          '✅ Sync server running on http://${server.address.address}:${server.port}',
          name: 'SyncServer',
        );
      }

      return true;
    } catch (e, stack) {
      developer.log(
        '❌ Failed to start server: $e',
        name: 'SyncServer',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<void> stop() async {
    final server = _server;
    if (server != null) {
      await server.close(force: true);
      _server = null;
      developer.log('🛑 Sync server stopped', name: 'SyncServer');
    }
  }

  /// Create router with all endpoints
  Router _createRouter() {
    final router = Router();

    // Health check
    router.get(Endpoints.health, _handlers.health);

    // Products endpoints
    router.get(Endpoints.productsSnapshot, _handlers.productsSnapshot);
    router.get(Endpoints.products, _handlers.products);

    // Sales endpoint
    router.post(Endpoints.sales, _handlers.receiveSales);

    // Stock endpoint
    router.get('${Endpoints.stock}/<productId>', _handlers.getStock);

    // Terminal registration
    router.post(Endpoints.register, _handlers.registerTerminal);

    return router;
  }

  /// CORS middleware for cross-origin requests
  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Handle preflight requests
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, ${SyncHeaders.terminalId}',
      };
}
