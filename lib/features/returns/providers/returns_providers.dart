import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/return_service.dart';
import '../../../models/return.dart';

// ===== الخدمة =====
final returnServiceProvider = Provider<ReturnService>((ref) {
  return ReturnService();
});

// ===== المرتجعات الأساسية =====
final returnsProvider = FutureProvider<List<Return>>((ref) async {
  final service = ref.read(returnServiceProvider);
  return await service.getAllReturns();
});

// ===== البحث =====
final returnSearchQueryProvider = StateProvider<String>((ref) => '');

// ===== فلترة الحالة =====
final returnStatusFilterProvider = StateProvider<ReturnStatus?>((ref) => null);

// ===== المرتجعات المفلترة =====
final filteredReturnsProvider = FutureProvider<List<Return>>((ref) async {
  final service = ref.read(returnServiceProvider);
  final searchQuery = ref.watch(returnSearchQueryProvider);
  final statusFilter = ref.watch(returnStatusFilterProvider);

  List<Return> returns = await service.getAllReturns();

  // البحث
  if (searchQuery.trim().isNotEmpty) {
    returns = returns
        .where(
            (r) => r.id.contains(searchQuery) || r.saleId.contains(searchQuery))
        .toList();
  }

  // فلترة الحالة
  if (statusFilter != null) {
    returns = returns.where((r) => r.status == statusFilter).toList();
  }

  return returns;
});

// ===== 🆕 Pagination =====
const int returnsPerPage = 50;

final currentReturnPageProvider = StateProvider<int>((ref) => 0);

final paginatedReturnsProvider = Provider<List<Return>>((ref) {
  final allReturnsAsync = ref.watch(filteredReturnsProvider);
  final currentPage = ref.watch(currentReturnPageProvider);

  if (!allReturnsAsync.hasValue) return [];

  final allReturns = allReturnsAsync.value ?? [];

  final startIndex = currentPage * returnsPerPage;
  final endIndex = (startIndex + returnsPerPage).clamp(0, allReturns.length);

  if (startIndex >= allReturns.length) return [];

  return allReturns.sublist(startIndex, endIndex);
});

final totalReturnPagesProvider = Provider<int>((ref) {
  final allReturnsAsync = ref.watch(filteredReturnsProvider);

  if (!allReturnsAsync.hasValue) return 0;

  final allReturns = allReturnsAsync.value ?? [];
  if (allReturns.isEmpty) return 0;

  return (allReturns.length / returnsPerPage).ceil();
});

final totalReturnsCountProvider = Provider<int>((ref) {
  final allReturnsAsync = ref.watch(filteredReturnsProvider);

  if (!allReturnsAsync.hasValue) return 0;

  return allReturnsAsync.value?.length ?? 0;
});
