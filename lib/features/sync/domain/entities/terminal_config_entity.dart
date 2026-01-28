/// Terminal type for multi-device sync
enum TerminalType {
  /// Master device - manages inventory and receives sales
  master,

  /// Cashier device - POS only, syncs with master
  cashier,
}

/// Domain entity representing terminal configuration
class TerminalConfigEntity {
  /// Unique terminal identifier (UUID)
  final String terminalId;

  /// Human-readable terminal name
  final String name;

  /// Terminal role (master/cashier)
  final TerminalType type;

  /// Master server IP address (for cashiers)
  final String masterIp;

  /// Master server port (for cashiers)
  final int masterPort;

  /// When this config was created
  final DateTime createdAt;

  /// When this config was last updated
  final DateTime updatedAt;

  const TerminalConfigEntity({
    required this.terminalId,
    required this.name,
    required this.type,
    this.masterIp = '',
    this.masterPort = 8080,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this terminal is the master
  bool get isMaster => type == TerminalType.master;

  /// Whether this terminal is a cashier
  bool get isCashier => type == TerminalType.cashier;

  /// Full URL to master server (for cashiers)
  String get masterUrl => 'http://$masterIp:$masterPort';

  /// Create a copy with updated fields
  TerminalConfigEntity copyWith({
    String? terminalId,
    String? name,
    TerminalType? type,
    String? masterIp,
    int? masterPort,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TerminalConfigEntity(
      terminalId: terminalId ?? this.terminalId,
      name: name ?? this.name,
      type: type ?? this.type,
      masterIp: masterIp ?? this.masterIp,
      masterPort: masterPort ?? this.masterPort,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalConfigEntity &&
          runtimeType == other.runtimeType &&
          terminalId == other.terminalId;

  @override
  int get hashCode => terminalId.hashCode;

  @override
  String toString() =>
      'TerminalConfigEntity(id: $terminalId, name: $name, type: $type)';
}
