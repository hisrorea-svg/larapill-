/// Constants for multi-terminal sync configuration
class SyncConstants {
  SyncConstants._();

  // ============ Network Settings ============

  /// Default port for sync server
  static const int defaultPort = 8080;

  /// Connection timeout
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Read timeout for large data transfers
  static const Duration readTimeout = Duration(seconds: 30);

  /// Health check interval
  static const Duration healthCheckInterval = Duration(seconds: 30);

  /// Auto-sync interval
  static const Duration autoSyncInterval = Duration(minutes: 5);

  // ============ Sync Settings ============

  /// Batch size for sales push
  static const int salesBatchSize = 50;

  /// Max retry attempts for failed items
  static const int maxRetryAttempts = 5;

  /// Delay between retries (exponential backoff base)
  static const Duration retryBaseDelay = Duration(seconds: 2);

  /// Max age for synced items before cleanup (days)
  static const int syncedItemMaxAgeDays = 7;

  // ============ Discovery Settings ============

  /// IP range start for discovery
  static const int discoveryRangeStart = 1;

  /// IP range end for discovery
  static const int discoveryRangeEnd = 254;

  /// Timeout for each discovery probe
  static const Duration discoveryProbeTimeout = Duration(milliseconds: 500);
}

/// API endpoint constants
class Endpoints {
  Endpoints._();

  static const String health = '/api/health';
  static const String productsSnapshot = '/api/products/snapshot';
  static const String products = '/api/products';
  static const String sales = '/api/sales';
  static const String stock = '/api/stock';
  static const String register = '/api/register';
}

/// Header constants
class SyncHeaders {
  SyncHeaders._();

  static const String terminalId = 'X-Terminal-ID';
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
}
