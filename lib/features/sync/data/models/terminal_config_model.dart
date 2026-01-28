import '../../domain/entities/entities.dart';

/// Data model for terminal configuration (database/JSON)
class TerminalConfigModel {
  final String terminalId;
  final String name;
  final String type;
  final String masterIp;
  final int masterPort;
  final String createdAt;
  final String updatedAt;

  const TerminalConfigModel({
    required this.terminalId,
    required this.name,
    required this.type,
    this.masterIp = '',
    this.masterPort = 8080,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory TerminalConfigModel.fromMap(Map<String, dynamic> map) {
    return TerminalConfigModel(
      terminalId: map['terminal_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'cashier',
      masterIp: map['master_ip'] as String? ?? '',
      masterPort: map['master_port'] as int? ?? 8080,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'terminal_id': terminalId,
      'name': name,
      'type': type,
      'master_ip': masterIp,
      'master_port': masterPort,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create from JSON
  factory TerminalConfigModel.fromJson(Map<String, dynamic> json) {
    return TerminalConfigModel(
      terminalId: json['terminalId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'cashier',
      masterIp: json['masterIp'] as String? ?? '',
      masterPort: json['masterPort'] as int? ?? 8080,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'terminalId': terminalId,
      'name': name,
      'type': type,
      'masterIp': masterIp,
      'masterPort': masterPort,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert to domain entity
  TerminalConfigEntity toEntity() {
    return TerminalConfigEntity(
      terminalId: terminalId,
      name: name,
      type: type == 'master' ? TerminalType.master : TerminalType.cashier,
      masterIp: masterIp,
      masterPort: masterPort,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Create from domain entity
  factory TerminalConfigModel.fromEntity(TerminalConfigEntity entity) {
    return TerminalConfigModel(
      terminalId: entity.terminalId,
      name: entity.name,
      type: entity.type.name,
      masterIp: entity.masterIp,
      masterPort: entity.masterPort,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }
}
