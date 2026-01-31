import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database_helper.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/clear_read_notifications_usecase.dart';
import '../../domain/usecases/create_low_stock_notification_usecase.dart';
import '../../domain/usecases/create_near_expiry_notification_usecase.dart';
import '../../domain/usecases/create_sale_notification_usecase.dart';
import '../../domain/usecases/startup_notification_check_usecase.dart';
import '../../../../features/inventory/data/repositories/product_repository.dart';
import '../controllers/notification_controller.dart';
import '../controllers/notification_state.dart';

// ======================================================================
// Data Layer Providers
// ======================================================================

/// Database Helper Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Local DataSource Provider
final notificationLocalDataSourceProvider =
    Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource(
    ref.watch(databaseHelperProvider),
  );
});

/// Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationLocalDataSourceProvider),
  );
});

// ======================================================================
// Domain Layer Providers - UseCases
// ======================================================================

final getNotificationsUseCaseProvider =
    Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

final markNotificationAsReadUseCaseProvider =
    Provider<MarkNotificationAsReadUseCase>((ref) {
  return MarkNotificationAsReadUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

final markAllNotificationsAsReadUseCaseProvider =
    Provider<MarkAllNotificationsAsReadUseCase>((ref) {
  return MarkAllNotificationsAsReadUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

final clearReadNotificationsUseCaseProvider =
    Provider<ClearReadNotificationsUseCase>((ref) {
  return ClearReadNotificationsUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

final createLowStockNotificationUseCaseProvider =
    Provider<CreateLowStockNotificationUseCase>((ref) {
  return CreateLowStockNotificationUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

final createNearExpiryNotificationUseCaseProvider =
    Provider<CreateNearExpiryNotificationUseCase>((ref) {
  return CreateNearExpiryNotificationUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

final createSaleNotificationUseCaseProvider =
    Provider<CreateSaleNotificationUseCase>((ref) {
  return CreateSaleNotificationUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

// ======================================================================
// Presentation Layer Providers
// ======================================================================

/// Notification Controller Provider
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController(
    getNotifications: ref.watch(getNotificationsUseCaseProvider),
    markAsRead: ref.watch(markNotificationAsReadUseCaseProvider),
    markAllAsRead: ref.watch(markAllNotificationsAsReadUseCaseProvider),
    clearRead: ref.watch(clearReadNotificationsUseCaseProvider),
  );
});

/// Stream Provider للإشعارات اللحظية
final notificationsStreamProvider =
    StreamProvider<List<NotificationEntity>>((ref) {
  final useCase = ref.watch(getNotificationsUseCaseProvider);
  return useCase.watch();
});

/// Provider للإشعارات غير المقروءة فقط
final unreadNotificationsProvider = Provider<List<NotificationEntity>>((ref) {
  return ref
      .watch(notificationControllerProvider)
      .notifications
      .where((n) => !n.isRead)
      .toList();
});

/// Provider لعدد الإشعارات غير المقروءة
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationControllerProvider).unreadCount;
});

/// Provider للإشعارات المجمعة حسب التاريخ
final groupedNotificationsProvider =
    Provider<Map<String, List<NotificationEntity>>>((ref) {
  return ref.watch(notificationControllerProvider).groupedNotifications;
});

// ======================================================================
// Startup Notification Check
// ======================================================================

/// Provider لـ StartupNotificationCheckUseCase
final startupNotificationCheckUseCaseProvider =
    Provider<StartupNotificationCheckUseCase>((ref) {
  return StartupNotificationCheckUseCase(
    productRepository: ProductRepository(),
    createLowStockNotification:
        ref.watch(createLowStockNotificationUseCaseProvider),
    createNearExpiryNotification:
        ref.watch(createNearExpiryNotificationUseCaseProvider),
  );
});

/// Provider لتنفيذ الفحص التلقائي عند بدء التطبيق
/// يتم تفعيله تلقائياً عند أول قراءة له
final startupNotificationCheckProvider =
    FutureProvider<NotificationCheckResult>((ref) async {
  final useCase = ref.watch(startupNotificationCheckUseCaseProvider);
  return useCase();
});
