// lib/features/network/domain/entities/network_settings_entity.dart
import 'package:equatable/equatable.dart';

/// وضع الشبكة
enum NetworkMode {
  /// جهاز سيرفر (رئيسي)
  server,

  /// جهاز كلاينت (ثانوي)
  client
}

/// كيان إعدادات الشبكة
class NetworkSettingsEntity extends Equatable {
  /// وضع الجهاز (سيرفر أو كلاينت)
  final NetworkMode mode;

  /// IP السيرفر (للكلاينت فقط)
  final String? serverIp;

  /// رقم المنفذ
  final int port;

  /// مفتاح API للتحقق
  final String apiKey;

  /// هل الجهاز له صلاحية الكتابة؟
  final bool isMaster;

  /// هل يتم الاتصال تلقائياً؟
  final bool autoConnect;

  /// هل يتم إعادة الاتصال تلقائياً؟
  final bool autoReconnect;

  const NetworkSettingsEntity({
    required this.mode,
    this.serverIp,
    required this.port,
    required this.apiKey,
    required this.isMaster,
    this.autoConnect = true,
    this.autoReconnect = true,
  });

  /// إعدادات افتراضية للسيرفر (الجهاز الرئيسي)
  ///
  /// NOTE: apiKey يجب تهيئته من SecureStorage عند أول تشغيل
  factory NetworkSettingsEntity.serverDefaults() {
    return const NetworkSettingsEntity(
      mode: NetworkMode.server,
      port: 5454,
      apiKey: '', // يتم تهيئته لاحقاً من SecureStorage
      isMaster: true,
      autoConnect: true,
      autoReconnect: true,
    );
  }

  /// إعدادات افتراضية للكلاينت (الجهاز الثانوي)
  ///
  /// NOTE: apiKey يجب تهيئته من SecureStorage عند أول تشغيل
  factory NetworkSettingsEntity.clientDefaults() {
    return const NetworkSettingsEntity(
      mode: NetworkMode.client,
      serverIp: '',
      port: 5454,
      apiKey: '', // يتم تهيئته لاحقاً من SecureStorage
      isMaster: false,
      autoConnect: true,
      autoReconnect: true,
    );
  }

  /// نسخ مع تعديلات
  NetworkSettingsEntity copyWith({
    NetworkMode? mode,
    String? serverIp,
    int? port,
    String? apiKey,
    bool? isMaster,
    bool? autoConnect,
    bool? autoReconnect,
  }) {
    return NetworkSettingsEntity(
      mode: mode ?? this.mode,
      serverIp: serverIp ?? this.serverIp,
      port: port ?? this.port,
      apiKey: apiKey ?? this.apiKey,
      isMaster: isMaster ?? this.isMaster,
      autoConnect: autoConnect ?? this.autoConnect,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'serverIp': serverIp,
      'port': port,
      'apiKey': apiKey,
      'isMaster': isMaster,
      'autoConnect': autoConnect,
      'autoReconnect': autoReconnect,
    };
  }

  /// إنشاء من JSON
  factory NetworkSettingsEntity.fromJson(Map<String, dynamic> json) {
    return NetworkSettingsEntity(
      mode: NetworkMode.values.byName(json['mode'] as String),
      serverIp: json['serverIp'] as String?,
      port: json['port'] as int,
      apiKey: json['apiKey'] as String,
      isMaster: json['isMaster'] as bool,
      autoConnect: json['autoConnect'] as bool? ?? true,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
    );
  }

  /// هل الجهاز سيرفر؟
  bool get isServer => mode == NetworkMode.server;

  /// هل الجهاز كلاينت؟
  bool get isClient => mode == NetworkMode.client;

  @override
  List<Object?> get props => [
        mode,
        serverIp,
        port,
        apiKey,
        isMaster,
        autoConnect,
        autoReconnect,
      ];
}
