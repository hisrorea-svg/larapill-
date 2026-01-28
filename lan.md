ربط نسختين او اكثر  من برنامج Flutter عبر LAN كيبل

HTTP REST API)
1. HTTP Server Service (في الجهاز السيرفر)
dart
// lib/core/network/http_server_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HTTP Server for LAN sync - يعمل فقط على الجهاز الرئيسي
class HttpServerService {
  static const int _port = 5454;
  HttpServer? _server;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream للبيانات الواردة
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  
  /// هل السيرفع شغال؟
  bool get isRunning => _server != null;

  /// يبدأ السيرفر
  Future<void> startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      if (kDebugMode) {
        debugPrint('🖥️ HTTP Server started on port $_port');
        debugPrint('📍 IP: ${await _getLocalIp()}');
      }
      
      _server!.listen(
        (HttpRequest request) async {
          if (kDebugMode) {
            debugPrint('📨 ${request.method} ${request.uri.path}');
          }
          
          // Security: Check API key in header
          final apiKey = request.headers.value('X-API-Key');
          if (apiKey != 'larapill_2024') { // غيّر هذا لكلمة سر قوية
            request.response
              ..statusCode = HttpStatus.unauthorized
              ..write(jsonEncode({'error': 'Invalid API key'}));
            await request.response.close();
            return;
          }
          
          // معالجة الطلبات
          try {
            final body = await utf8.decoder.bind(request).join();
            final data = body.isNotEmpty ? jsonDecode(body) : {};
            
            // إرسال البيانات للـ UI
            _messageController.add({
              'method': request.method,
              'path': request.uri.path,
              'data': data,
            });
            
            // رد نجاح
            request.response
              ..statusCode = HttpStatus.ok
              ..write(jsonEncode({'success': true, 'received': data}));
          } catch (e) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write(jsonEncode({'error': e.toString()}));
          } finally {
            await request.response.close();
          }
        },
        onError: (error) {
          if (kDebugMode) debugPrint('❌ Server error: $error');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to start server: $e');
      rethrow;
    }
  }

  /// إيقاف السيرفر
  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
    await _messageController.close();
  }

  /// الحصول على IP المحلي
  static Future<String> _getLocalIp() async {
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
    return '127.0.0.1';
  }

  static Future<String> getLocalIp() async {
    return await _getLocalIp();
  }
}
2. HTTP Client Service (في الجهاز الثاني)
dart
// lib/core/network/http_client_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HTTP Client for LAN sync - يتصل بالسيرفر
class HttpClientService {
  static const String _apiKey = 'larapill_2024'; // نفس كلمة السر
  String? _serverIp;
  
  /// هل متصل؟
  bool get isConnected => _serverIp != null;

  /// الاتصال بالسيرفر
  Future<bool> connect(String serverIp) async {
    try {
      // اختبار الاتصال
      final url = Uri.http('$serverIp:5454', '/api/test');
      final request = await HttpClient().getUrl(url);
      request.headers.add('X-API-Key', _apiKey);
      
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        _serverIp = serverIp;
        if (kDebugMode) debugPrint('✅ Connected to $serverIp');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Connection failed: $e');
      return false;
    }
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
      final url = Uri.http('$_serverIp:5454', endpoint);
      final request = await HttpClient().postUrl(url);
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('X-API-Key', _apiKey);
      
      request.write(jsonEncode(data));
      final response = await request.close();
      
      final responseBody = await response.transform(utf8.decoder).join();
      final responseData = jsonDecode(responseBody);
      
      if (response.statusCode == HttpStatus.ok) {
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Unknown error');
      }
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
      final url = Uri.http('$_serverIp:5454', endpoint);
      final request = await HttpClient().getUrl(url);
      request.headers.add('X-API-Key', _apiKey);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      return jsonDecode(responseBody);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Fetch failed: $e');
      rethrow;
    }
  }

  /// قطع الاتصال
  void disconnect() {
    _serverIp = null;
  }
}
3. Riverpod Providers
dart
// lib/features/lan/presentation/providers/lan_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/http_server_service.dart';
import '../../../../core/network/http_client_service.dart';

/// Provider للـ Server
final httpServerProvider = Provider<HttpServerService>((ref) {
  return HttpServerService();
});

/// Provider للـ Client
final httpClientProvider = Provider<HttpClientService>((ref) {
  return HttpClientService();
});

/// Provider لحالة السيرفر (شغال/مشغول)
final serverStateProvider = StateProvider<bool>((ref) => false);

/// Provider لحالة الاتصال
final clientConnectionStateProvider = StateProvider<bool>((ref) => false);

/// Provider لـ IP السيرفر
final serverIpProvider = StateProvider<String>((ref) => '');

/// Provider للبيانات الواردة
final incomingDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
4. UI للسيرفر
dart
// lib/features/lan/presentation/screens/server_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lan_providers.dart';

class ServerScreen extends ConsumerWidget {
  const ServerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(serverStateProvider);
    final incomingData = ref.watch(incomingDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Mode'),
        actions: [
          Switch(
            value: isRunning,
            onChanged: (value) => _toggleServer(ref, value),
          ),
        ],
      ),
      body: Column(
        children: [
          // معلومات الاتصال
          if (isRunning) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: FutureBuilder<String>(
                future: HttpServerService.getLocalIp(),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Server IP: ${snapshot.data ?? 'Loading...'}'),
                      const Text('Port: 5454'),
                      const Text('API Key: larapill_2024'),
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ تأكد من تعطيل Firewall في Windows',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          
          // البيانات الواردة
          Expanded(
            child: incomingData == null
                ? const Center(child: Text('No data received yet'))
                : ListView(
                    children: [
                      ListTile(
                        title: const Text('Last Request'),
                        subtitle: Text(incomingData.toString()),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServer(WidgetRef ref, bool start) async {
    final service = ref.read(httpServerProvider);
    
    if (start) {
      try {
        await service.startServer();
        ref.read(serverStateProvider.notifier).state = true;
        
        // استمع للبيانات الواردة
        service.messages.listen((data) {
          ref.read(incomingDataProvider.notifier).state = data;
        });
        
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(content: Text('✅ Server started')),
        );
      } catch (e) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } else {
      await service.stopServer();
      ref.read(serverStateProvider.notifier).state = false;
    }
  }
}
5. UI للكلاينت
dart
// lib/features/lan/presentation/screens/client_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lan_providers.dart';

class ClientScreen extends ConsumerWidget {
  ClientScreen({Key? key}) : super(key: key);

  final _ipController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(clientConnectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Mode'),
        actions: [
          IconButton(
            icon: Icon(isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // إدخال IP
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'Server IP (مثال: 192.168.1.1)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isConnected,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: isConnected ? null : () => _connect(ref),
                  icon: const Icon(Icons.connect_without_contact),
                  label: const Text('Connect'),
                ),
              ],
            ),
          ),
          
          // إرسال بيانات
          if (isConnected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Send Data (JSON)',
                      hintText: '{"action": "sync_settings", "data": {}}',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _sendData(ref),
                    icon: const Icon(Icons.send),
                    label: const Text('Send to Server'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connect(WidgetRef ref) async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text('❌ أدخل IP السيرفر')),
      );
      return;
    }

    final client = ref.read(httpClientProvider);
    final success = await client.connect(ip);
    
    if (success) {
      ref.read(clientConnectionStateProvider.notifier).state = true;
      ref.read(serverIpProvider.notifier).state = ip;
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text('✅ Connected successfully')),
      );
    } else {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text('❌ Connection failed - تأكد من IP والـ Firewall')),
      );
    }
  }

  Future<void> _sendData(WidgetRef ref) async {
    final jsonString = _messageController.text.trim();
    if (jsonString.isEmpty) return;

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final client = ref.read(httpClientProvider);
      
      await client.sendData('/api/sync', data);
      
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text('✅ Data sent successfully')),
      );
      _
إنشاء ملف إعدادات خاص بالشبكة يحدد دور كل جهاز.

📋 الحل المثالي: إعدادات الشبكة
1. إنشاء Model للإعدادات
dart
// lib/features/network/domain/entities/network_settings_entity.dart
import 'package:equatable/equatable.dart';

enum NetworkMode { server, client }

class NetworkSettingsEntity extends Equatable {
  final NetworkMode mode;
  final String? serverIp; // يُستخدم فقط في وضع Client
  final int port;
  final String apiKey;
  final bool isMaster; // هل هذا الجهاز له صلاحية الكتابة؟

  const NetworkSettingsEntity({
    required this.mode,
    this.serverIp,
    required this.port,
    required this.apiKey,
    required this.isMaster,
  });

  /// إعدادات افتراضية للسيرفر (الجهاز الرئيسي)
  factory NetworkSettingsEntity.serverDefaults() {
    return const NetworkSettingsEntity(
      mode: NetworkMode.server,
      port: 5454,
      apiKey: 'larapill_2024_secure_key',
      isMaster: true, // السيرفر له كل الصلاحيات
    );
  }

  /// إعدادات افتراضية للكلاينت (الجهاز الثانوي)
  factory NetworkSettingsEntity.clientDefaults() {
    return const NetworkSettingsEntity(
      mode: NetworkMode.client,
      serverIp: '192.168.1.1',
      port: 5454,
      apiKey: 'larapill_2024_secure_key',
      isMaster: false, // الكلاينت للقراءة فقط افتراضياً
    );
  }

  NetworkSettingsEntity copyWith({
    NetworkMode? mode,
    String? serverIp,
    int? port,
    String? apiKey,
    bool? isMaster,
  }) {
    return NetworkSettingsEntity(
      mode: mode ?? this.mode,
      serverIp: serverIp ?? this.serverIp,
      port: port ?? this.port,
      apiKey: apiKey ?? this.apiKey,
      isMaster: isMaster ?? this.isMaster,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'serverIp': serverIp,
      'port': port,
      'apiKey': apiKey,
      'isMaster': isMaster,
    };
  }

  factory NetworkSettingsEntity.fromJson(Map<String, dynamic> json) {
    return NetworkSettingsEntity(
      mode: NetworkMode.values.byName(json['mode']),
      serverIp: json['serverIp'],
      port: json['port'],
      apiKey: json['apiKey'],
      isMaster: json['isMaster'],
    );
  }

  @override
  List<Object?> get props => [mode, serverIp, port, apiKey, isMaster];
}
2. Repository للإعدادات
dart
// lib/features/network/data/repositories/network_settings_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/network_settings_entity.dart';

abstract class NetworkSettingsRepository {
  Future<NetworkSettingsEntity> getSettings();
  Future<void> saveSettings(NetworkSettingsEntity settings);
  Future<bool> isFirstLaunch();
}

class NetworkSettingsRepositoryImpl implements NetworkSettingsRepository {
  static const String _key = 'network_settings';
  static const String _firstLaunchKey = 'network_first_launch';
  final SharedPreferences _prefs;

  const NetworkSettingsRepositoryImpl(this._prefs);

  @override
  Future<NetworkSettingsEntity> getSettings() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) {
      // أول إطلاق - افترض السيرفر
      return NetworkSettingsEntity.serverDefaults();
    }
    return NetworkSettingsEntity.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<void> saveSettings(NetworkSettingsEntity settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  @override
  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> markAsLaunched() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }
}
3. Use Cases
dart
// lib/features/network/domain/usecases/get_network_settings_usecase.dart
import '../entities/network_settings_entity.dart';
import '../repositories/network_settings_repository.dart';

class GetNetworkSettingsUseCase {
  final NetworkSettingsRepository _repository;

  const GetNetworkSettingsUseCase(this._repository);

  Future<NetworkSettingsEntity> call() async {
    return await _repository.getSettings();
  }
}

// lib/features/network/domain/usecases/save_network_settings_usecase.dart
import '../entities/network_settings_entity.dart';
import '../repositories/network_settings_repository.dart';

class SaveNetworkSettingsUseCase {
  final NetworkSettingsRepository _repository;

  const SaveNetworkSettingsUseCase(this._repository);

  Future<void> call(NetworkSettingsEntity settings) async {
    await _repository.saveSettings(settings);
  }
}
4. Notifiers + Providers
dart
// lib/features/network/presentation/providers/network_settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/network_settings_entity.dart';
import '../../domain/usecases/get_network_settings_usecase.dart';
import '../../domain/usecases/save_network_settings_usecase.dart';
import '../../data/repositories/network_settings_repository.dart';

class NetworkSettingsNotifier extends StateNotifier<NetworkSettingsEntity> {
  final GetNetworkSettingsUseCase _getUseCase;
  final SaveNetworkSettingsUseCase _saveUseCase;

  NetworkSettingsNotifier(this._getUseCase, this._saveUseCase)
      : super(const NetworkSettingsEntity(
          mode: NetworkMode.server,
          port: 5454,
          apiKey: 'larapill_2024_secure_key',
          isMaster: true,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _getUseCase();
  }

  Future<void> setMode(NetworkMode mode) async {
    state = state.copyWith(mode: mode);
    await _saveUseCase(state);
  }

  Future<void> setServerIp(String ip) async {
    state = state.copyWith(serverIp: ip);
    await _saveUseCase(state);
  }

  Future<void> setMaster(bool isMaster) async {
    state = state.copyWith(isMaster: isMaster);
    await _saveUseCase(state);
  }

  bool get isMaster => state.isMaster;
  bool get isServer => state.mode == NetworkMode.server;
  String? get serverIp => state.serverIp;
}

// Providers
final networkSettingsRepositoryProvider = Provider<NetworkSettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value!;
  return NetworkSettingsRepositoryImpl(prefs);
});

final networkSettingsNotifierProvider = StateNotifierProvider<NetworkSettingsNotifier, NetworkSettingsEntity>((ref) {
  final getUseCase = GetNetworkSettingsUseCase(ref.watch(networkSettingsRepositoryProvider));
  final saveUseCase = SaveNetworkSettingsUseCase(ref.watch(networkSettingsRepositoryProvider));
  return NetworkSettingsNotifier(getUseCase, saveUseCase);
});
5. UI الإعدادات
dart
// lib/features/network/presentation/screens/network_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_settings_notifier.dart';

class NetworkSettingsScreen extends ConsumerWidget {
  const NetworkSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(networkSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الشبكة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // اختيار الوضع
          Card(
            child: ListTile(
              title: const Text('وضع الجهاز'),
              subtitle: Text(settings.mode == NetworkMode.server ? 'سيرفر (رئيسي)' : 'كلاينت (ثانوي)'),
              trailing: Switch(
                value: settings.mode == NetworkMode.server,
                onChanged: (value) async {
                  await ref.read(networkSettingsNotifierProvider.notifier).setMode(
                    value ? NetworkMode.server : NetworkMode.client,
                  );
                },
              ),
            ),
          ),
          
          // إعدادات الكلاينت فقط
          if (settings.mode == NetworkMode.client) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'IP السيرفر',
                hintText: '192.168.1.1',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: settings.serverIp),
              onChanged: (value) async {
                await ref.read(networkSettingsNotifierProvider.notifier).setServerIp(value);
              },
            ),
          ],
          
          // صلاحيات الكتابة
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('صلاحية الكتابة'),
              subtitle: const Text('هل هذا الجهاز يمكنه تعديل البيانات؟'),
              trailing: Switch(
                value: settings.isMaster,
                onChanged: (value) async {
                  await ref.read(networkSettingsNotifierProvider.notifier).setMaster(value);
                },
              ),
            ),
          ),
          
          // معلومات
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('ملاحظات مهمة'),
              subtitle: Text(
                '• السيرفر يجب أن يكون شغال دائماً\n'
                '• الكلاينت يتصل بالسيرفر تلقائياً\n'
                '• الجهاز "الرئيسي" هو اللي يكتب البيانات\n'
                '• الجهاز "الثانوي" يقرأ فقط',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
6. شاشة اختيار الوضع عند أول إطلاق
dart
// lib/features/network/presentation/screens/network_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_settings_notifier.dart';
import 'network_settings_screen.dart';

class NetworkSetupScreen extends ConsumerStatefulWidget {
  const NetworkSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NetworkSetupScreen> createState() => _NetworkSetupScreenState();
}

class _NetworkSetupScreenState extends ConsumerState<NetworkSetupScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('network_first_launch') ?? true;
    
    if (!isFirst) {
      // Skip to main app
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
      return;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            const Icon(Icons.network_check, size: 80, color: Colors.blue),
            const Text(
              'إعداد أولي للشبكة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'هل هذا الجهاز هو الجهاز الرئيسي (السيرفر)؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            ElevatedButton.icon(
              onPressed: () => _setupAsServer(),
              icon: const Icon(Icons.computer),
              label: const Text('نعم، هذا الجهاز الرئيسي'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.blue,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _setupAsClient(),
              icon: const Icon(Icons.phone_android),
              label: const Text('لا، جهاز ثانوي'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupAsServer() async {
    final notifier = ref.read(networkSettingsNotifierProvider.notifier);
    await notifier.setMode(NetworkMode.server);
    await notifier.setMaster(true);
    await _markAsConfigured();
  }

  Future<void> _setupAsClient() async {
    final notifier = ref.read(networkSettingsNotifierProvider.notifier);
    await notifier.setMode(NetworkMode.client);
    await notifier.setMaster(false);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClientConfigScreen()),
      );
    }
  }

  Future<void> _markAsConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('network_first_launch', false);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyApp()),
      );
    }
  }
}

// شاشة إعداد الكلاينت
class ClientConfigScreen extends ConsumerWidget {
  const ClientConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('إعداد الكلاينت')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل IP السيرفر:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server IP',
                hintText: '192.168.1.1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final ip = controller.text.trim();
                if (ip.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ أدخل IP صحيح')),
                  );
                  return;
                }
                
                await ref.read(networkSettingsNotifierProvider.notifier).setServerIp(ip);
                
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('network_first_launch', false);
                
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MyApp()),
                  );
                }
              },
              child: const Text('حفظ والمتابعة'),
            ),
          ],
        ),
      ),
    );
  }
}
7. كيفية الاستخدام في التطبيق
في main.dart، بدل ما تُطلق التطبيق مباشرة، افحص الإعدادات أولاً:

dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('network_first_launch') ?? true;

  runApp(
    ProviderScope(
      child: MaterialApp(
        home: isFirstLaunch 
          ? const NetworkSetupScreen()
          : const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(networkSettingsNotifierProvider);
    
    // اعرض واجهة مختلفة حسب الوضع
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.mode == NetworkMode.server ? 'السيرفر' : 'الكلاينت'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('الوضع: ${settings.mode.name}'),
            Text('الصلاحية: ${settings.isMaster ? "رئيسي" : "ثانوي"}'),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NetworkSettingsScreen()),
              ),
              child: const Text('تعديل الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}