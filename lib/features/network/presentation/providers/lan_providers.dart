// lib/features/network/presentation/providers/lan_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/http_server_service.dart';
import '../../../../core/network/http_client_service.dart';
import '../../../../core/network/remote_database_service.dart';
import '../../domain/entities/network_settings_entity.dart';
import 'network_settings_notifier.dart';

/// Provider للـ HTTP Server
final httpServerProvider = Provider<HttpServerService>((ref) {
  final service = HttpServerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider للـ HTTP Client
final httpClientProvider = Provider<HttpClientService>((ref) {
  final service = HttpClientService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider للـ Remote Database Service
/// يُستخدم للتواصل مع قاعدة بيانات السيرفر
final remoteDatabaseProvider = Provider<RemoteDatabaseService>((ref) {
  final client = ref.watch(httpClientProvider);
  return RemoteDatabaseService(client);
});

/// Provider لحالة السيرفر (شغال/متوقف)
final serverRunningProvider = StateProvider<bool>((ref) => false);

/// Provider لحالة الاتصال (متصل/غير متصل)
final clientConnectedProvider = StateProvider<bool>((ref) => false);

/// Provider لـ IP السيرفر المتصل به
final connectedServerIpProvider = StateProvider<String?>((ref) => null);

/// Provider للبيانات الواردة
final incomingDataProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Provider لقائمة الأجهزة المتصلة (للسيرفر)
final connectedClientsProvider = StateProvider<List<String>>((ref) => []);

/// Provider لحالة الاكتشاف التلقائي
final isDiscoveringProvider = StateProvider<bool>((ref) => false);

/// Provider لنتيجة الاكتشاف التلقائي
final discoveredServerIpProvider = StateProvider<String?>((ref) => null);

/// Provider لـ IP المحلي
final localIpProvider = FutureProvider<String>((ref) async {
  return await HttpServerService.getLocalIp();
});

/// Provider لكل الـ IPs المحلية
final allLocalIpsProvider = FutureProvider<List<String>>((ref) async {
  return await HttpServerService.getAllLocalIps();
});

/// Provider للتحقق هل الجهاز سيرفر؟
final isServerModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(networkSettingsNotifierProvider);
  return settings.mode == NetworkMode.server;
});

/// Provider للتحقق هل الجهاز كلاينت متصل؟
final isConnectedClientProvider = Provider<bool>((ref) {
  final settings = ref.watch(networkSettingsNotifierProvider);
  final isConnected = ref.watch(clientConnectedProvider);
  return settings.mode == NetworkMode.client && isConnected;
});

/// Provider للتحقق: هل يجب استخدام قاعدة البيانات عن بعد؟
final shouldUseRemoteDatabaseProvider = Provider<bool>((ref) {
  return ref.watch(isConnectedClientProvider);
});
