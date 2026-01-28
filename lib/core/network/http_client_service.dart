// lib/core/network/http_client_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HTTP Client for LAN sync - يتصل بالسيرفر
class HttpClientService {
  static const String _apiKey = 'larapill_2024_secure_key';
  static const int _port = 5454;
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  String? _serverIp;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  final _connectionController = StreamController<bool>.broadcast();

  /// هل متصل؟
  bool get isConnected => _serverIp != null;

  /// IP السيرفر المتصل به
  String? get serverIp => _serverIp;

  /// Stream لحالة الاتصال
  Stream<bool> get connectionStream => _connectionController.stream;

  /// الاتصال بالسيرفر
  Future<bool> connect(String serverIp) async {
    if (_isConnecting) return false;
    _isConnecting = true;

    try {
      // اختبار الاتصال
      final url = Uri.http('$serverIp:$_port', '/api/ping');
      final client = HttpClient();
      client.connectionTimeout = _timeout;

      final request = await client.getUrl(url);
      request.headers.add('X-API-Key', _apiKey);

      final response = await request.close().timeout(_timeout);

      if (response.statusCode == HttpStatus.ok) {
        _serverIp = serverIp;
        _connectionController.add(true);
        if (kDebugMode) debugPrint('✅ Connected to $serverIp');
        return true;
      }

      if (kDebugMode) {
        debugPrint('❌ Connection failed: HTTP ${response.statusCode}');
      }
      return false;
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('❌ Socket error: ${e.message}');
      return false;
    } on TimeoutException {
      if (kDebugMode) debugPrint('❌ Connection timeout');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Connection failed: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// إعادة الاتصال التلقائي
  void enableAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(_reconnectDelay, (_) async {
      if (!isConnected && _serverIp != null) {
        final lastIp = _serverIp!;
        _serverIp = null;
        await connect(lastIp);
      }
    });
  }

  /// إيقاف إعادة الاتصال التلقائي
  void disableAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// إرسال بيانات للسيرفر
  Future<Map<String, dynamic>> sendData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    if (_serverIp == null) {
      throw Exception('Not connected to server. Call connect() first.');
    }

    try {
      final url = Uri.http('$_serverIp:$_port', endpoint);
      final client = HttpClient();
      client.connectionTimeout = _timeout;

      final request = await client.postUrl(url);
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('X-API-Key', _apiKey);

      request.write(jsonEncode(data));
      final response = await request.close().timeout(_timeout);

      final responseBody = await response.transform(utf8.decoder).join();
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == HttpStatus.ok) {
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Unknown error');
      }
    } on SocketException catch (e) {
      _handleConnectionLost();
      throw Exception('Connection lost: ${e.message}');
    } on TimeoutException {
      _handleConnectionLost();
      throw Exception('Request timeout');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Send failed: $e');
      rethrow;
    }
  }

  /// جلب بيانات من السيرفر
  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    if (_serverIp == null) {
      throw Exception('Not connected to server. Call connect() first.');
    }

    try {
      final url = Uri.http('$_serverIp:$_port', endpoint);
      final client = HttpClient();
      client.connectionTimeout = _timeout;

      final request = await client.getUrl(url);
      request.headers.add('X-API-Key', _apiKey);

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      return jsonDecode(responseBody) as Map<String, dynamic>;
    } on SocketException catch (e) {
      _handleConnectionLost();
      throw Exception('Connection lost: ${e.message}');
    } on TimeoutException {
      _handleConnectionLost();
      throw Exception('Request timeout');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Fetch failed: $e');
      rethrow;
    }
  }

  /// التعامل مع فقدان الاتصال
  void _handleConnectionLost() {
    final wasConnected = isConnected;
    // Don't clear serverIp to allow reconnection
    if (wasConnected) {
      _connectionController.add(false);
      if (kDebugMode) debugPrint('⚠️ Connection lost');
    }
  }

  /// اختبار الاتصال
  Future<bool> ping() async {
    if (_serverIp == null) return false;

    try {
      final result = await fetchData('/api/ping');
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// قطع الاتصال
  void disconnect() {
    _serverIp = null;
    _connectionController.add(false);
    disableAutoReconnect();
    if (kDebugMode) debugPrint('🔌 Disconnected');
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    disconnect();
    await _connectionController.close();
  }

  /// البحث عن السيرفر في الشبكة (اكتشاف تلقائي)
  static Future<String?> discoverServer({
    String subnet = '192.168.1',
    int startRange = 1,
    int endRange = 254,
  }) async {
    if (kDebugMode) {
      debugPrint('🔍 Scanning network for server...');
    }

    final futures = <Future<String?>>[];

    for (var i = startRange; i <= endRange; i++) {
      final ip = '$subnet.$i';
      futures.add(_tryConnect(ip));
    }

    final results = await Future.wait(futures);
    final serverIp = results.firstWhere(
      (ip) => ip != null,
      orElse: () => null,
    );

    if (serverIp != null && kDebugMode) {
      debugPrint('✅ Server found at: $serverIp');
    }

    return serverIp;
  }

  static Future<String?> _tryConnect(String ip) async {
    try {
      final url = Uri.http('$ip:$_port', '/api/ping');
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 500);

      final request = await client.getUrl(url);
      request.headers.add('X-API-Key', _apiKey);

      final response = await request.close().timeout(
            const Duration(milliseconds: 500),
          );

      if (response.statusCode == HttpStatus.ok) {
        return ip;
      }
    } catch (_) {
      // Ignore errors during discovery
    }
    return null;
  }
}
