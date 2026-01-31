// lib/features/network/presentation/providers/network_settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/network_settings_entity.dart';
import '../../domain/usecases/get_network_settings_usecase.dart';
import '../../domain/usecases/save_network_settings_usecase.dart';
import '../../data/repositories/network_settings_repository.dart';

/// Notifier لإدارة إعدادات الشبكة
class NetworkSettingsNotifier extends StateNotifier<NetworkSettingsEntity> {
  final GetNetworkSettingsUseCase _getUseCase;
  final SaveNetworkSettingsUseCase _saveUseCase;
  final NetworkSettingsRepository _repository;

  NetworkSettingsNotifier(
    this._getUseCase,
    this._saveUseCase,
    this._repository,
  ) : super(NetworkSettingsEntity.serverDefaults()) {
    _loadSettings();
  }

  /// تحميل الإعدادات من التخزين
  void _loadSettings() {
    state = _getUseCase();
  }

  /// تغيير وضع الجهاز
  Future<void> setMode(NetworkMode mode) async {
    state = state.copyWith(mode: mode);
    await _saveUseCase(state);
  }

  /// تعيين IP السيرفر
  Future<void> setServerIp(String ip) async {
    state = state.copyWith(serverIp: ip);
    await _saveUseCase(state);
  }

  /// تعيين صلاحية الكتابة
  Future<void> setMaster(bool isMaster) async {
    state = state.copyWith(isMaster: isMaster);
    await _saveUseCase(state);
  }

  /// تعيين الاتصال التلقائي
  Future<void> setAutoConnect(bool autoConnect) async {
    state = state.copyWith(autoConnect: autoConnect);
    await _saveUseCase(state);
  }

  /// تعيين إعادة الاتصال التلقائي
  Future<void> setAutoReconnect(bool autoReconnect) async {
    state = state.copyWith(autoReconnect: autoReconnect);
    await _saveUseCase(state);
  }

  /// إعداد كسيرفر
  Future<void> setupAsServer() async {
    state = NetworkSettingsEntity.serverDefaults();
    await _saveUseCase(state);
    await _repository.markAsLaunched();
  }

  /// إعداد ككلاينت
  Future<void> setupAsClient(String serverIp) async {
    state = NetworkSettingsEntity.clientDefaults().copyWith(serverIp: serverIp);
    await _saveUseCase(state);
    await _repository.markAsLaunched();
  }

  /// هل أول إطلاق؟
  bool isFirstLaunch() {
    return _repository.isFirstLaunch();
  }

  /// تحديد أنه تم الإطلاق
  Future<void> markAsLaunched() async {
    await _repository.markAsLaunched();
  }

  /// إعادة ضبط الإعدادات
  Future<void> resetSettings() async {
    await _repository.clearSettings();
    state = NetworkSettingsEntity.serverDefaults();
  }

  // Getters مساعدة
  bool get isMaster => state.isMaster;
  bool get isServer => state.mode == NetworkMode.server;
  bool get isClient => state.mode == NetworkMode.client;
  String? get serverIp => state.serverIp;
}

// =========== Providers ===========

/// Provider للـ Repository (HiveStorage-based)
final networkSettingsRepositoryProvider =
    Provider<NetworkSettingsRepository>((ref) {
  return const NetworkSettingsRepositoryImpl();
});

/// Provider للـ Notifier
final networkSettingsNotifierProvider =
    StateNotifierProvider<NetworkSettingsNotifier, NetworkSettingsEntity>(
        (ref) {
  final repository = ref.watch(networkSettingsRepositoryProvider);
  final getUseCase = GetNetworkSettingsUseCase(repository);
  final saveUseCase = SaveNetworkSettingsUseCase(repository);
  return NetworkSettingsNotifier(getUseCase, saveUseCase, repository);
});

/// Provider لفحص أول إطلاق
final isFirstLaunchProvider = Provider<bool>((ref) {
  final repository = ref.watch(networkSettingsRepositoryProvider);
  return repository.isFirstLaunch();
});
