import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larapill/services/meds_data_service.dart';
import '../domain/usecases/add_product_usecase.dart';
import '../domain/usecases/get_all_products_usecase.dart';
import '../domain/usecases/update_product_usecase.dart';
import '../domain/usecases/delete_product_usecase.dart';
import '../domain/usecases/get_product_by_id_usecase.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/entities/product_entity.dart';
import '../data/repositories/inventory_repository_impl.dart';
import '../../../database/daos/product_dao_provider.dart';

// Repository
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dao = ref.watch(productDaoProvider);
  return InventoryRepositoryImpl(dao);
});

// UseCases
final addProductUseCaseProvider = Provider<AddProductUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return AddProductUseCase(repo);
});

final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return GetAllProductsUseCase(repo);
});

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return UpdateProductUseCase(repo);
});

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return DeleteProductUseCase(repo);
});

final getProductByIdUseCaseProvider = Provider<GetProductByIdUseCase>((ref) {
  final repo = ref.read(inventoryRepositoryProvider);
  return GetProductByIdUseCase(repo);
});

// Provider للحصول على منتج واحد للتعديل
final getProductByIdProvider =
    FutureProvider.family<ProductEntity?, int>((ref, id) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return await repo.getProductById(id);
});

// ---------- إعدادات عامة ----------
const int _kPageSize = 20;

// query البحث
final searchQueryProvider = StateProvider<String>((ref) => '');

// تصفية حسب الصنف/الفئة
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// فلترة متقدمة
final advancedFilterProvider = StateProvider<String?>((ref) => null);

// الصفحة الحالية (تبدأ من 0)
final currentPageProvider = StateProvider<int>((ref) => 0);

// Provider للبحث عن الأدوية
final medsSearchProvider =
    StateProvider.family<List<Map<String, dynamic>>, String>((ref, query) {
  return MedsDataService.searchMeds(query);
});

// Provider لتحميل بيانات الأدوية
final medsLoadingProvider = FutureProvider<void>((ref) async {
  await MedsDataService.loadMeds();
});

// ---------- مصدر البيانات الأساسي ----------
// ---------- مصدر البيانات الأساسي ----------
final productsProvider =
    AsyncNotifierProvider.autoDispose<ProductsNotifier, List<ProductEntity>>(
        ProductsNotifier.new);

class ProductsNotifier extends AutoDisposeAsyncNotifier<List<ProductEntity>> {
  @override
  Future<List<ProductEntity>> build() async {
    final getAll = ref.watch(getAllProductsUseCaseProvider);
    return await getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getAll = ref.read(getAllProductsUseCaseProvider);
      return await getAll();
    });
  }
}

// ---------- التصفية ----------
final filteredProductsProvider = Provider<List<ProductEntity>>((ref) {
  final asyncProducts = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final advancedFilter = ref.watch(advancedFilterProvider);

  return asyncProducts.maybeWhen(
    data: (products) {
      Iterable<ProductEntity> list = products;

      // تصفية بالبحث
      if (query.isNotEmpty) {
        list = list.where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.company.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query));
      }

      // تصفية بالفئة
      if (selectedCategory != null && selectedCategory.isNotEmpty) {
        list = list.where((p) => p.category == selectedCategory);
      }

      // الفلترة المتقدمة
      if (advancedFilter != null && advancedFilter.isNotEmpty) {
        final now = DateTime.now();
        switch (advancedFilter) {
          case 'low_stock':
            // كمية أقل من 20
            list = list.where((p) => p.quantity > 0 && p.quantity < 20);
            break;
          case 'critical_stock':
            // كمية أقل من 10
            list = list.where((p) => p.quantity > 0 && p.quantity < 10);
            break;
          case 'expired':
            // منتهية الصلاحية
            list = list.where(
                (p) => p.expiryDate != null && p.expiryDate!.isBefore(now));
            break;
          case 'expiring_soon':
            // تنتهي خلال 3 أشهر
            final threeMonthsLater = now.add(const Duration(days: 90));
            list = list.where((p) =>
                p.expiryDate != null &&
                p.expiryDate!.isAfter(now) &&
                p.expiryDate!.isBefore(threeMonthsLater));
            break;
          case 'high_price':
            // ترتيب من الأغلى للأرخص
            final sorted = list.toList()
              ..sort((a, b) => b.price.compareTo(a.price));
            return sorted;
          case 'low_price':
            // ترتيب من الأرخص للأغلى
            final sorted = list.toList()
              ..sort((a, b) => a.price.compareTo(b.price));
            return sorted;
          case 'best_selling':
            // الأكثر مبيعاً (حسب الكمية المباعة إذا متوفر)
            // يمكن تحسينه لاحقاً بناءً على بيانات المبيعات الفعلية
            final sorted = list.toList()
              ..sort((a, b) => b.quantity.compareTo(a.quantity));
            return sorted;
          case 'recently_added':
            // المضافة حديثاً (حسب ID - الأحدث أولاً)
            final sorted = list.toList()..sort((a, b) => b.id.compareTo(a.id));
            return sorted;
        }
      }

      return List<ProductEntity>.from(list);
    },
    orElse: () => const [],
  );
});

// ---------- العدّاد الكلي ----------
final totalProductsCountProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredProductsProvider);
  return filtered.length;
});

// ---------- عدد الصفحات ----------
final totalPagesProvider = Provider<int>((ref) {
  final total = ref.watch(totalProductsCountProvider);
  if (total == 0) return 1;
  return ((total - 1) / _kPageSize).floor() + 1;
});

// ---------- تقطيع حسب الصفحة ----------
final paginatedProductsProvider = Provider<List<ProductEntity>>((ref) {
  final filtered = ref.watch(filteredProductsProvider);
  final page = ref.watch(currentPageProvider);
  final start = page * _kPageSize;
  final end = (start + _kPageSize) > filtered.length
      ? filtered.length
      : (start + _kPageSize);
  if (start >= filtered.length || start < 0) return const <ProductEntity>[];
  return filtered.sublist(start, end);
});
