import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../domain/entities/entities.dart';
import 'sync_constants.dart';
import '../data/models/models.dart';

/// Interface for remote sync operations
abstract class SyncApiClient {
  // Discovery
  Future<DiscoveryResultEntity> discoverServer({
    int port,
    void Function(int current, int total)? onProgress,
  });
  Future<bool> checkServerAt(String ip, int port);

  // Sync operations
  Future<SyncResultEntity> initialSync(String masterUrl, String terminalId);
  Future<SyncResultEntity> incrementalSync(
      String masterUrl, String terminalId, DateTime? since);
  Future<SyncResultEntity> pushSales(
      String masterUrl, String terminalId, List<SyncQueueModel> sales);
  Future<double?> getRemoteStock(String masterUrl, String productId);

  // Connection monitoring
  void startConnectionMonitoring(String masterUrl);
  void stopConnectionMonitoring();
  Stream<ConnectionStatus> watchConnectionStatus();
}

/// Implementation of remote sync data source using HTTP
class SyncApiClientImpl implements SyncApiClient {
  final http.Client _client;

  // Connection monitoring
  Timer? _connectionTimer;
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  String? _monitoringUrl;

  SyncApiClientImpl({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<DiscoveryResultEntity> discoverServer({
    int port = SyncConstants.defaultPort,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      // Get local IP
      final localIp = await _getLocalIp();
      if (localIp == null) {
        return DiscoveryResultEntity.failure('لم يتم العثور على عنوان IP محلي');
      }

      // Extract base IP (e.g., 192.168.1)
      final parts = localIp.split('.');
      if (parts.length != 4) {
        return DiscoveryResultEntity.failure('صيغة IP غير صحيحة');
      }
      final baseIp = '${parts[0]}.${parts[1]}.${parts[2]}';

      // Scan range
      const startRange = 1;
      const endRange = 254;
      const total = endRange - startRange + 1;

      for (var i = startRange; i <= endRange; i++) {
        onProgress?.call(i - startRange + 1, total);

        final testIp = '$baseIp.$i';
        if (testIp == localIp) continue; // Skip self

        final found = await checkServerAt(testIp, port);
        if (found) {
          developer.log('Server found at $testIp:$port', name: 'SyncApiClient');
          return DiscoveryResultEntity.success(testIp, port);
        }
      }

      return DiscoveryResultEntity.notFound();
    } catch (e) {
      developer.log('Discovery error: $e', name: 'SyncApiClient');
      return DiscoveryResultEntity.failure(e.toString());
    }
  }

  @override
  Future<bool> checkServerAt(String ip, int port) async {
    try {
      final uri = Uri.parse('http://$ip:$port${Endpoints.health}');
      final response =
          await _client.get(uri).timeout(const Duration(milliseconds: 500));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SyncResultEntity> initialSync(
      String masterUrl, String terminalId) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$masterUrl${Endpoints.productsSnapshot}');
      final response = await _client.get(
        uri,
        headers: {SyncHeaders.terminalId: terminalId},
      ).timeout(SyncConstants.connectionTimeout);

      if (response.statusCode != 200) {
        return SyncResultEntity.failure('Server error: ${response.statusCode}');
      }

      // Decompress gzip data
      final gzipped = GZipDecoder().decodeBytes(response.bodyBytes);
      final jsonStr = utf8.decode(gzipped);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final products = data['products'] as List? ?? [];

      stopwatch.stop();

      return SyncResultEntity.success(
        productsUpdated: products.length,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('Initial sync error: $e', name: 'SyncApiClient');
      return SyncResultEntity.failure(e.toString());
    }
  }

  @override
  Future<SyncResultEntity> incrementalSync(
      String masterUrl, String terminalId, DateTime? since) async {
    final stopwatch = Stopwatch()..start();

    try {
      var uri = Uri.parse('$masterUrl${Endpoints.products}');
      if (since != null) {
        uri = uri.replace(queryParameters: {
          'since': since.toIso8601String(),
        });
      }

      final response = await _client.get(
        uri,
        headers: {SyncHeaders.terminalId: terminalId},
      ).timeout(SyncConstants.connectionTimeout);

      if (response.statusCode != 200) {
        return SyncResultEntity.failure('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List? ?? [];

      stopwatch.stop();

      return SyncResultEntity.success(
        productsUpdated: products.length,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('Incremental sync error: $e', name: 'SyncApiClient');
      return SyncResultEntity.failure(e.toString());
    }
  }

  @override
  Future<SyncResultEntity> pushSales(
      String masterUrl, String terminalId, List<SyncQueueModel> sales) async {
    if (sales.isEmpty) {
      return SyncResultEntity.success();
    }

    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$masterUrl${Endpoints.sales}');
      final salesData = sales.map((s) => jsonDecode(s.payload)).toList();

      final response = await _client
          .post(
            uri,
            headers: {
              SyncHeaders.terminalId: terminalId,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'sales': salesData}),
          )
          .timeout(SyncConstants.connectionTimeout);

      if (response.statusCode != 200) {
        return SyncResultEntity.failure('Server error: ${response.statusCode}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final received = result['received'] as int? ?? sales.length;

      stopwatch.stop();

      return SyncResultEntity.success(
        salesPushed: received,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('Push sales error: $e', name: 'SyncApiClient');
      return SyncResultEntity.failure(e.toString());
    }
  }

  @override
  Future<double?> getRemoteStock(String masterUrl, String productId) async {
    try {
      final uri = Uri.parse('$masterUrl${Endpoints.stock}/$productId');

      final response =
          await _client.get(uri).timeout(SyncConstants.connectionTimeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['stock'] as num?)?.toDouble();
    } catch (e) {
      developer.log('Get remote stock error: $e', name: 'SyncApiClient');
      return null;
    }
  }

  @override
  void startConnectionMonitoring(String masterUrl) {
    stopConnectionMonitoring();

    _monitoringUrl = masterUrl;
    _connectionController.add(ConnectionStatus.connecting);

    _connectionTimer = Timer.periodic(
      SyncConstants.healthCheckInterval,
      (_) => _checkConnection(),
    );

    // Check immediately
    _checkConnection();
  }

  @override
  void stopConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
    _monitoringUrl = null;
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return _connectionController.stream;
  }

  Future<void> _checkConnection() async {
    if (_monitoringUrl == null) return;

    try {
      final uri = Uri.parse('$_monitoringUrl${Endpoints.health}');
      final response =
          await _client.get(uri).timeout(SyncConstants.connectionTimeout);

      if (response.statusCode == 200) {
        _connectionController.add(ConnectionStatus.connected);
      } else {
        _connectionController.add(ConnectionStatus.error);
      }
    } catch (_) {
      _connectionController.add(ConnectionStatus.disconnected);
    }
  }

  Future<String?> _getLocalIp() async {
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
            return addr.address;
          }
        }
      }

      return null;
    } catch (e) {
      developer.log('Error getting local IP: $e', name: 'SyncApiClient');
      return null;
    }
  }

  void dispose() {
    stopConnectionMonitoring();
    _connectionController.close();
    _client.close();
  }
}
