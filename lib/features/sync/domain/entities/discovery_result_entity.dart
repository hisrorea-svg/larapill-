/// Result of network discovery
class DiscoveryResultEntity {
  /// Whether a server was found
  final bool found;

  /// IP address of discovered server
  final String? ip;

  /// Port of discovered server
  final int port;

  /// Error message if discovery failed
  final String? errorMessage;

  const DiscoveryResultEntity({
    required this.found,
    this.ip,
    this.port = 8080,
    this.errorMessage,
  });

  /// Create a successful discovery result
  factory DiscoveryResultEntity.success(String ip, int port) {
    return DiscoveryResultEntity(
      found: true,
      ip: ip,
      port: port,
    );
  }

  /// Create a not-found result
  factory DiscoveryResultEntity.notFound() {
    return const DiscoveryResultEntity(
      found: false,
      errorMessage: 'لم يتم العثور على سيرفر في الشبكة',
    );
  }

  /// Create a failure result
  factory DiscoveryResultEntity.failure(String error) {
    return DiscoveryResultEntity(
      found: false,
      errorMessage: error,
    );
  }

  /// Full server URL
  String? get serverUrl => found && ip != null ? 'http://$ip:$port' : null;

  @override
  String toString() =>
      'DiscoveryResultEntity(found: $found, ip: $ip, port: $port)';
}
