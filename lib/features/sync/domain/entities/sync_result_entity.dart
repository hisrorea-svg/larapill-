/// Result of a sync operation
class SyncResultEntity {
  /// Whether the sync was successful
  final bool success;

  /// Number of products updated/synced
  final int productsUpdated;

  /// Number of sales pushed to master
  final int salesPushed;

  /// When the sync completed
  final DateTime completedAt;

  /// Error message if failed
  final String? errorMessage;

  /// Duration of the sync operation
  final Duration duration;

  const SyncResultEntity({
    required this.success,
    this.productsUpdated = 0,
    this.salesPushed = 0,
    required this.completedAt,
    this.errorMessage,
    this.duration = Duration.zero,
  });

  /// Create a successful result
  factory SyncResultEntity.success({
    int productsUpdated = 0,
    int salesPushed = 0,
    Duration duration = Duration.zero,
  }) {
    return SyncResultEntity(
      success: true,
      productsUpdated: productsUpdated,
      salesPushed: salesPushed,
      completedAt: DateTime.now(),
      duration: duration,
    );
  }

  /// Create a failed result
  factory SyncResultEntity.failure(String errorMessage) {
    return SyncResultEntity(
      success: false,
      completedAt: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  /// Human-readable summary
  String get summary {
    if (!success) return 'فشلت المزامنة: $errorMessage';

    final parts = <String>[];
    if (productsUpdated > 0) {
      parts.add('$productsUpdated منتج');
    }
    if (salesPushed > 0) {
      parts.add('$salesPushed مبيعة');
    }

    if (parts.isEmpty) {
      return 'تمت المزامنة (لا يوجد تغييرات)';
    }

    return 'تمت مزامنة ${parts.join(' و ')}';
  }

  @override
  String toString() =>
      'SyncResultEntity(success: $success, products: $productsUpdated, sales: $salesPushed)';
}
