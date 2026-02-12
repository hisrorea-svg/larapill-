import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../../../../core/database/drift/daos/daos.dart';
import '../../../../core/database/drift/mappers/return_mapper.dart';
import '../../domain/entities/return_entity.dart';
import 'dart:developer' as developer;

/// 📦 Repository for managing product returns
class ReturnsRepository {
  final ReturnDriftDao _returnDao;

  ReturnsRepository(this._returnDao);

  /// 🔄 Create a new return
  Future<String> createReturn(Return returnData) async {
    try {
      final companion = ReturnMapper.toCompanion(returnData);
      final itemCompanions = returnData.items
          .map((item) => ReturnMapper.toItemCompanion(returnData.id, item))
          .toList();

      return await _returnDao.createReturn(companion, itemCompanions);
    } catch (e) {
      developer.log('❌ Error creating return in repository: $e',
          name: 'ReturnsRepository');
      rethrow;
    }
  }

  /// 🔍 Get all returns
  Future<List<Return>> getAllReturns() async {
    final results = await _returnDao.findAll();
    return results
        .map((r) => ReturnMapper.fromEntry(r.returnEntry, r.items))
        .toList();
  }

  /// 🔍 Get return by ID
  Future<Return?> getReturnById(String id) async {
    final result = await _returnDao.findById(id);
    if (result == null) return null;
    return ReturnMapper.fromEntry(result.returnEntry, result.items);
  }

  /// 📝 Update return status
  Future<void> updateStatus(String returnId, ReturnStatus status) async {
    await _returnDao.updateStatus(returnId, status.name);
  }
}

/// 🔌 Providers
final returnsRepositoryProvider = Provider<ReturnsRepository>((ref) {
  final returnDao = ref.watch(returnDriftDaoProvider);
  return ReturnsRepository(returnDao);
});

final returnDriftDaoProvider = Provider<ReturnDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReturnDriftDao(db);
});
