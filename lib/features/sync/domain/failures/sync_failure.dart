/// Base class for sync-related failures
sealed class SyncFailure {
  final String message;
  final String? technicalMessage;

  const SyncFailure(this.message, {this.technicalMessage});

  @override
  String toString() => 'SyncFailure: $message';
}

/// Network connection failure
class ConnectionFailure extends SyncFailure {
  final String? url;

  const ConnectionFailure(
    super.message, {
    super.technicalMessage,
    this.url,
  });
}

/// Server not found during discovery
class ServerNotFoundFailure extends SyncFailure {
  const ServerNotFoundFailure()
      : super('لم يتم العثور على سيرفر في الشبكة المحلية');
}

/// Server returned an error response
class ServerErrorFailure extends SyncFailure {
  final int? statusCode;
  final String? body;

  const ServerErrorFailure(
    super.message, {
    super.technicalMessage,
    this.statusCode,
    this.body,
  });
}

/// Timeout during operation
class TimeoutFailure extends SyncFailure {
  final Duration timeout;

  const TimeoutFailure(
    super.message, {
    required this.timeout,
    super.technicalMessage,
  });
}

/// Database operation failure
class DatabaseFailure extends SyncFailure {
  final String? operation;

  const DatabaseFailure(
    super.message, {
    super.technicalMessage,
    this.operation,
  });
}

/// Data parsing/format failure
class DataFormatFailure extends SyncFailure {
  const DataFormatFailure(
    super.message, {
    super.technicalMessage,
  });
}

/// Configuration error
class ConfigurationFailure extends SyncFailure {
  const ConfigurationFailure(
    super.message, {
    super.technicalMessage,
  });
}

/// Sync queue is empty (not really a failure)
class NoDataToSyncFailure extends SyncFailure {
  const NoDataToSyncFailure() : super('لا توجد بيانات للمزامنة');
}

/// Terminal not configured yet
class NotConfiguredFailure extends SyncFailure {
  const NotConfiguredFailure() : super('لم يتم إعداد الجهاز بعد');
}

/// Unknown/unexpected failure
class UnknownSyncFailure extends SyncFailure {
  final Object? originalError;
  final StackTrace? stackTrace;

  const UnknownSyncFailure(
    super.message, {
    super.technicalMessage,
    this.originalError,
    this.stackTrace,
  });
}
