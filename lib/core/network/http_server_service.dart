// lib/core/network/http_server_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_router.dart';

/// HTTP Server for LAN sync - يعمل فقط على الجهاز الرئيسي
class HttpServerService {
  static const int _port = 5454;
  static const String _apiKey = 'larapill_2024_secure_key';

  HttpServer? _server;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final List<String> _connectedClients = [];

  /// API Router لمعالجة الطلبات
  final ApiRouter _apiRouter = ApiRouter();

  /// Stream للبيانات الواردة
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// هل السيرفر شغال؟
  bool get isRunning => _server != null;

  /// عدد الأجهزة المتصلة
  int get connectedClientsCount => _connectedClients.length;

  /// قائمة الأجهزة المتصلة
  List<String> get connectedClients => List.unmodifiable(_connectedClients);

  /// يبدأ السيرفر
  Future<void> startServer() async {
    if (_server != null) {
      debugPrint('⚠️ Server already running');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      if (kDebugMode) {
        debugPrint('🖥️ HTTP Server started on port $_port');
        debugPrint('📍 IP: ${await getLocalIp()}');
      }

      _server!.listen(
        _handleRequest,
        onError: (error) {
          if (kDebugMode) debugPrint('❌ Server error: $error');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to start server: $e');
      rethrow;
    }
  }

  /// معالجة الطلبات الواردة
  Future<void> _handleRequest(HttpRequest request) async {
    // إضافة CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers
        .add('Access-Control-Allow-Headers', 'Content-Type, X-API-Key');
    request.response.headers.contentType = ContentType.json;

    // Handle preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    if (kDebugMode) {
      debugPrint(
          '📨 ${request.method} ${request.uri.path} from ${request.connectionInfo?.remoteAddress.address}');
    }

    // Security: Check API key in header
    final apiKey = request.headers.value('X-API-Key');
    if (apiKey != _apiKey) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write(jsonEncode({'error': 'Invalid API key', 'success': false}));
      await request.response.close();
      return;
    }

    // معالجة الطلبات
    try {
      final clientIp =
          request.connectionInfo?.remoteAddress.address ?? 'unknown';
      final body = await utf8.decoder.bind(request).join();
      final data = body.isNotEmpty
          ? jsonDecode(body) as Map<String, dynamic>
          : <String, dynamic>{};

      // Track connected clients
      if (!_connectedClients.contains(clientIp)) {
        _connectedClients.add(clientIp);
        if (kDebugMode) debugPrint('✅ New client connected: $clientIp');
      }

      // استخدام API Router لمعالجة الطلبات
      final response = await _apiRouter.handleRequest(
        request.method,
        request.uri.path,
        data,
      );

      // تحديد status code بناءً على النتيجة
      final statusCode = response['statusCode'] as int? ??
          (response['success'] == true ? HttpStatus.ok : HttpStatus.badRequest);

      // إرسال البيانات للـ UI
      _messageController.add({
        'method': request.method,
        'path': request.uri.path,
        'data': data,
        'clientIp': clientIp,
        'timestamp': DateTime.now().toIso8601String(),
        'response': response,
      });

      request.response
        ..statusCode = statusCode
        ..write(jsonEncode(response));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Request error: $e');
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': e.toString(), 'success': false}));
    } finally {
      await request.response.close();
    }
  }

  /// إيقاف السيرفر
  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
    _connectedClients.clear();
    if (kDebugMode) debugPrint('🛑 Server stopped');
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    await stopServer();
    await _messageController.close();
  }

  /// الحصول على IP المحلي
  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 &&
              !address.address.startsWith('127.') &&
              !address.address.startsWith('169.254.')) {
            return address.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to get local IP: $e');
    }
    return '127.0.0.1';
  }

  /// الحصول على كل الـ IPs المحلية
  static Future<List<String>> getAllLocalIps() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 &&
              !address.address.startsWith('127.')) {
            ips.add(address.address);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to get IPs: $e');
    }
    return ips;
  }
}
