/// Users Drift DAO - Type-safe database access for user management
library users_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_database.dart';
import '../database_provider.dart';

part 'users_drift_dao.g.dart';

/// DAO for Users, UserSessions, and UserActivities tables with type-safe queries
@DriftAccessor(tables: [Users, UserSessions, UserActivities])
class UsersDriftDao extends DatabaseAccessor<AppDatabase>
    with _$UsersDriftDaoMixin {
  UsersDriftDao(super.db);

  // ─────────────────────────────────────────────────────────────────────────
  // USER CRUD OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get user by ID
  Future<UserEntry?> findById(String id) {
    return (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get user by username
  Future<UserEntry?> findByUsername(String username) {
    return (select(users)..where((t) => t.username.equals(username)))
        .getSingleOrNull();
  }

  /// Get all users
  Future<List<UserEntry>> getAllUsers({bool activeOnly = false}) {
    if (activeOnly) {
      return (select(users)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
    }
    return (select(users)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get all active users
  Future<List<UserEntry>> getActiveUsers() {
    return (select(users)..where((t) => t.isActive.equals(true))).get();
  }

  /// Watch active users (reactive)
  Stream<List<UserEntry>> watchActiveUsers() {
    return (select(users)..where((t) => t.isActive.equals(true))).watch();
  }

  /// Create a new user
  Future<void> createUser(UsersCompanion user) async {
    await into(users).insert(user);
  }

  /// Update user with named parameters
  Future<void> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? phone,
    String? role,
    List<String>? permissions,
    bool? isActive,
  }) async {
    final companion = UsersCompanion(
      fullName: fullName != null ? Value(fullName) : const Value.absent(),
      email: email != null ? Value(email) : const Value.absent(),
      phone: phone != null ? Value(phone) : const Value.absent(),
      role: role != null ? Value(role) : const Value.absent(),
      permissions: permissions != null
          ? Value(permissions.join(','))
          : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await (update(users)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Soft delete user (set isActive = false)
  Future<void> softDeleteUser(String id) async {
    await (update(users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard delete user
  Future<void> deleteUser(String id) async {
    await (delete(users)..where((t) => t.id.equals(id))).go();
  }

  /// Check if username exists
  Future<bool> usernameExists(String username) async {
    final user = await findByUsername(username);
    return user != null;
  }

  /// Update user password
  Future<void> updatePassword(
    String userId,
    String newPasswordHash, {
    bool forceChange = false,
  }) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(newPasswordHash),
        forcePasswordChange: Value(forceChange),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update user permissions
  Future<void> updatePermissions(
      String userId, List<String> permissions) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        permissions: Value(permissions.join(',')),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update last login time
  Future<void> updateLastLogin(String userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        lastLogin: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    final totalQuery = selectOnly(users)..addColumns([users.id.count()]);
    final totalResult = await totalQuery.getSingle();
    final totalUsers = totalResult.read(users.id.count()) ?? 0;

    final activeQuery = selectOnly(users)
      ..addColumns([users.id.count()])
      ..where(users.isActive.equals(true));
    final activeResult = await activeQuery.getSingle();
    final activeUsers = activeResult.read(users.id.count()) ?? 0;

    final sessionQuery = selectOnly(userSessions)
      ..addColumns([userSessions.id.count()])
      ..where(userSessions.isActive.equals(true));
    final sessionResult = await sessionQuery.getSingle();
    final activeSessions = sessionResult.read(userSessions.id.count()) ?? 0;

    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'active_sessions': activeSessions,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a new session
  Future<void> createSession(UserSessionsCompanion session) async {
    await into(userSessions).insert(session);
  }

  /// Get session by token
  Future<UserSessionEntry?> getSession(String sessionToken) {
    return (select(userSessions)
          ..where((t) => t.sessionToken.equals(sessionToken))
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Get active session by ID
  Future<UserSessionEntry?> getSessionById(String sessionId) {
    return (select(userSessions)
          ..where((t) => t.id.equals(sessionId))
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Get user's active sessions
  Future<List<UserSessionEntry>> getUserSessions(String userId) {
    return (select(userSessions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.loginTime)]))
        .get();
  }

  /// Update session activity
  Future<void> updateSessionActivity(String sessionToken) async {
    await (update(userSessions)
          ..where((t) => t.sessionToken.equals(sessionToken)))
        .write(UserSessionsCompanion(lastActivity: Value(DateTime.now())));
  }

  /// Invalidate session by token
  Future<void> invalidateSession(String sessionToken) async {
    await (update(userSessions)
          ..where((t) => t.sessionToken.equals(sessionToken)))
        .write(const UserSessionsCompanion(isActive: Value(false)));
  }

  /// Invalidate all sessions for a user
  Future<void> invalidateAllUserSessions(String userId) async {
    await (update(userSessions)..where((t) => t.userId.equals(userId))).write(
      const UserSessionsCompanion(isActive: Value(false)),
    );
  }

  /// Delete all sessions for a user
  Future<void> deleteUserSessions(String userId) async {
    await (delete(userSessions)..where((t) => t.userId.equals(userId))).go();
  }

  /// Cleanup expired sessions
  Future<int> cleanupExpiredSessions() async {
    final now = DateTime.now();
    return await (delete(userSessions)
          ..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER ACTIVITIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Log user activity
  Future<void> logUserActivity(UserActivitiesCompanion activity) async {
    await into(userActivities).insert(activity);
  }

  /// Get user activities
  Future<List<UserActivityEntry>> getUserActivities(String userId,
      {int limit = 50}) {
    return (select(userActivities)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BATCH OPERATIONS (للأداء الأمثل)
  // ─────────────────────────────────────────────────────────────────────────

  /// ✅ إدخال متعدد في عملية واحدة (Batch Insert)
  /// 
  /// يستخدم لإنشاء المستخدمين الافتراضيين بشكل سريع
  Future<void> batchInsertUsers(List<UsersCompanion> usersList) async {
    await batch((batch) {
      batch.insertAll(
        users,
        usersList,
        mode: InsertMode.insertOrIgnore,
      );
    });
  }
}

/// Provider for UsersDriftDao
final usersDriftDaoProvider = Provider<UsersDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return UsersDriftDao(db);
});
