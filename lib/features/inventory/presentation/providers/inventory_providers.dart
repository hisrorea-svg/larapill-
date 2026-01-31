import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/meds_data_service.dart';
import '../../domain/usecases/add_product_usecase.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/filter_products_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/entities/add_product_params.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/validators/product_validator.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/datasources/inventory_local_datasource.dart';
import '../../../../database/database_helper.dart';
import '../../../pos/presentation/providers/pos_providers.dart'; // ✅ ربط مع نقطة البيع

// ============ Infrastructure ============

/// Database helper provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Local data source provider
final inventoryLocalDataSourceProvider =
    Provider<InventoryLocalDataSourceImpl>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return InventoryLocalDataSourceImpl(dbHelper);
});

// ============ Repository ============

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final localDataSource = ref.watch(inventoryLocalDataSourceProvider);
  return InventoryRepositoryImpl(localDataSource, null);
});

// ============ Validator ============

final productValidatorProvider = Provider<ProductValidator>((ref) {
  return ProductValidator();
});

// ============ UseCases ============

final addProductUseCaseProvider = Provider<AddProductUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final validator = ref.watch(productValidatorProvider);
  return AddProductUseCase(repo, validator);
});

final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return GetAllProductsUseCase(repo);
});

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final validator = ref.watch(productValidatorProvider);
  return UpdateProductUseCase(repo, validator);
});

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return DeleteProductUseCase(repo);
});

final getProductByIdUseCaseProvider = Provider<GetProductByIdUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return GetProductByIdUseCase(repo);
});

final filterProductsUseCaseProvider = Provider<FilterProductsUseCase>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return FilterProductsUseCase(repo);
});

// ============ إعدادات الفلترة ============

const int _kPageSize = 50;

/// البحث النصي
final searchQueryProvider = StateProvider<String>((ref) => '');

/// تصفية حسب الفئة (arabicName من UI)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// فلترة متقدمة (low_stock, expired, etc.)
final advancedFilterProvider = StateProvider<String?>((ref) => null);

/// الصفحة الحالية (تبدأ من 0)
final currentPageProvider = StateProvider<int>((ref) => 0);

// ============ Filter Params Provider ============

/// Converts UI filter selections to InventoryFilterParams for database query
final inventoryFilterParamsProvider = Provider<InventoryFilterParams>((ref) {
  final searchQuery = ref.watch(searchQueryProvider).trim();
  final advancedFilter = ref.watch(advancedFilterProvider);
  final currentPage = ref.watch(currentPageProvider);

  return InventoryFilterParams(
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
    categoryEnumName: null, // Category feature removed
    stockFilter: advancedFilter,
    page: currentPage,
    pageSize: _kPageSize,
  );
});

// ============ مصدر البيانات الرئيسي (Database-Level Filtering) ============

// ============ مصدر البيانات الرئيسي (Database-Level Filtering) ============

/// Controller المسؤول عن إدارة حالة المخزون (قائمة المنتجات) والعمليات عليها
/// يحل محل FutureProvider لتوفير تفاعلية حقيقية (Reactivity)
final inventoryControllerProvider = AsyncNotifierProvider.autoDispose<
    ReactiveInventoryController,
    PaginatedResult<ProductEntity>>(ReactiveInventoryController.new);

class ReactiveInventoryController
    extends AutoDisposeAsyncNotifier<PaginatedResult<ProductEntity>> {
  @override
  Future<PaginatedResult<ProductEntity>> build() async {
    // 1. مراقبة متغيرات الفلترة - أي تغيير هنا سيؤدي لإعادة بناء الحالة تلقائياً
    final params = ref.watch(inventoryFilterParamsProvider);
    final repo = ref.read(inventoryRepositoryProvider);

    // 2. جلب البيانات
    final result = await repo.getProductsFiltered(params);

    // 3. إرجاع النتيجة أو حالة فارغة عند الخطأ
    return result.fold(
      (failure) => PaginatedResult.empty(pageSize: 50),
      (paginatedResult) => paginatedResult,
    );
  }

  /// حذف منتج
  Future<void> deleteProduct(int productId) async {
    final deleteUseCase = ref.read(deleteProductUseCaseProvider);

    // تنفيذ الحذف
    final result = await deleteUseCase(productId);

    result.fold(
      (failure) =>
          throw Exception(failure.message), // يمكن معالجة الخطأ بشكل أفضل
      (success) {
        // ✅ النقطة الجوهرية: نطلب من الـ Provider تحديث نفسه
        // هذا سيؤدي لإعادة جلب البيانات تلقائياً وتحديث الواجهة
        ref.invalidateSelf();
        // ✅ تحديث نقطة البيع أيضاً لتنعكس التغييرات فوراً
        ref.invalidate(posControllerProvider);
      },
    );
  }

  /// إضافة منتج
  Future<void> addProduct(AddProductParams params) async {
    final addUseCase = ref.read(addProductUseCaseProvider);
    final result = await addUseCase(params);

    result.fold(
      (failure) => throw Exception(failure.message),
      (success) {
        ref.invalidateSelf(); // تحديث القائمة فوراً
        ref.invalidate(posControllerProvider); // ✅ تحديث POS
      },
    );
  }

  /// تحديث منتج
  Future<void> updateProduct(ProductEntity product) async {
    final updateUseCase = ref.read(updateProductUseCaseProvider);

    // تغليف المنتج في Params
    final params = UpdateProductParams(
      id: product.id,
      name: product.name,
      company: product.company,
      category: product.category,
      barcode: product.barcode,
      quantity: product.quantity,
      price: product.price,
      costPrice: product.costPrice,
      expiryDate: product.expiryDate,
    );

    final result = await updateUseCase(params);

    result.fold(
      (failure) => throw Exception(failure.message),
      (success) {
        ref.invalidateSelf();
        ref.invalidate(posControllerProvider); // ✅ تحديث POS
      },
    );
  }
}

/// Provides paginated and filtered products directly from the controller
/// (Alias for backward compatibility or easier reading)
final paginatedProductsResultProvider =
    Provider.autoDispose<AsyncValue<PaginatedResult<ProductEntity>>>((ref) {
  return ref.watch(inventoryControllerProvider);
});

/// For backwards compatibility - returns list of products from current page
final filteredProductsProvider = Provider<List<ProductEntity>>((ref) {
  final asyncResult = ref.watch(paginatedProductsResultProvider);
  return asyncResult.maybeWhen(
    data: (result) => result.items,
    orElse: () => const [],
  );
});

/// For backwards compatibility - returns paginated products (same as filtered now)
final paginatedProductsProvider = Provider<List<ProductEntity>>((ref) {
  return ref.watch(filteredProductsProvider);
});

/// Total count of filtered products (not just current page)
final totalProductsCountProvider = Provider<int>((ref) {
  final asyncResult = ref.watch(paginatedProductsResultProvider);
  return asyncResult.maybeWhen(
    data: (result) => result.totalCount,
    orElse: () => 0,
  );
});

/// Total pages based on filter
final totalPagesProvider = Provider<int>((ref) {
  final asyncResult = ref.watch(paginatedProductsResultProvider);
  return asyncResult.maybeWhen(
    data: (result) => result.totalPages,
    orElse: () => 1,
  );
});

/// Is loading products
final isLoadingProductsProvider = Provider<bool>((ref) {
  final asyncResult = ref.watch(paginatedProductsResultProvider);
  return asyncResult.isLoading;
});

/// Has error loading products
final productsErrorProvider = Provider<String?>((ref) {
  final asyncResult = ref.watch(paginatedProductsResultProvider);
  return asyncResult.maybeWhen(
    error: (e, _) => e.toString(),
    orElse: () => null,
  );
});

// ============ Legacy: All Products (for screens that need all) ============

final productsProvider =
    AsyncNotifierProvider.autoDispose<ProductsNotifier, List<ProductEntity>>(
        ProductsNotifier.new);

class ProductsNotifier extends AutoDisposeAsyncNotifier<List<ProductEntity>> {
  @override
  Future<List<ProductEntity>> build() async {
    final getAll = ref.watch(getAllProductsUseCaseProvider);
    final result = await getAll();
    return result.fold(
      (failure) => [],
      (products) => products,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getAll = ref.read(getAllProductsUseCaseProvider);
      final result = await getAll();
      return result.fold(
        (failure) => [],
        (products) => products,
      );
    });
  }
}

// ============ Helper: Refresh Providers ============

/// Call this after adding/updating/deleting a product
void invalidateProductProviders(WidgetRef ref) {
  ref.invalidate(paginatedProductsResultProvider);
  ref.invalidate(productsProvider);
}

// ============ Meds Data Service (for smart add) ============

final medsSearchProvider =
    StateProvider.family<List<Map<String, dynamic>>, String>((ref, query) {
  return MedsDataService.searchMeds(query);
});

final medsLoadingProvider = FutureProvider<void>((ref) async {
  await MedsDataService.loadMeds();
});
