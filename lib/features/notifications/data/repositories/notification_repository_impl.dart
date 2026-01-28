import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../models/notification_model.dart';

/// تطبيق مستودع الإشعارات - Data Layer
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource _localDataSource;

  const NotificationRepositoryImpl(this._localDataSource);

  @override
  Stream<List<NotificationEntity>> watchAll() async* {
    await for (final models in _localDataSource.watchAll()) {
      // تحويل Models إلى Entities
      yield models.map((model) => model as NotificationEntity).toList();
    }
  }

  @override
  Future<List<NotificationEntity>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map((model) => model as NotificationEntity).toList();
  }

  @override
  Future<void> add(NotificationEntity notification) async {
    final model = NotificationModel.fromEntity(notification);
    await _localDataSource.insert(model);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _localDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    await _localDataSource.markAllAsRead();
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }

  @override
  Future<void> clearRead() async {
    await _localDataSource.clearRead();
  }

  @override
  Future<int> getUnreadCount() async {
    return await _localDataSource.getUnreadCount();
  }
}
