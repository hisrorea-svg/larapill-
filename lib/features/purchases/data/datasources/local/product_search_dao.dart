import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/database_helper.dart';

/// نموذج المنتج للبحث
class ProductSearchItem {
  final int id;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double sellPrice;
  final int currentStock;
  final String? unit;

  const ProductSearchItem({
    required this.id,
    required this.name,
    this.barcode,
    this.purchasePrice = 0,
    this.sellPrice = 0,
    this.currentStock = 0,
    this.unit,
  });

  factory ProductSearchItem.fromMap(Map<String, dynamic> map) {
    return ProductSearchItem(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      barcode: map['barcode'] as String?,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
      sellPrice: (map['sell_price'] as num?)?.toDouble() ?? 0,
      currentStock: (map['current_stock'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String?,
    );
  }
}

/// DAO للبحث عن المنتجات
class ProductSearchDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<ProductSearchItem>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT id, name, barcode, purchase_price, sell_price, current_stock, unit
      FROM products
      WHERE is_active = 1 
        AND (name LIKE ? OR barcode LIKE ?)
      ORDER BY name ASC
      LIMIT 20
    ''', ['%$query%', '%$query%']);

    return result.map((e) => ProductSearchItem.fromMap(e)).toList();
  }

  Future<ProductSearchItem?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ProductSearchItem.fromMap(result.first);
  }

  Future<ProductSearchItem?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ProductSearchItem.fromMap(result.first);
  }
}

/// حالة البحث
class ProductSearchState {
  final String query;
  final List<ProductSearchItem> results;
  final bool isLoading;
  final ProductSearchItem? selectedProduct;

  const ProductSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.selectedProduct,
  });

  ProductSearchState copyWith({
    String? query,
    List<ProductSearchItem>? results,
    bool? isLoading,
    ProductSearchItem? selectedProduct,
  }) {
    return ProductSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      selectedProduct: selectedProduct ?? this.selectedProduct,
    );
  }
}

/// Notifier للبحث عن المنتجات
class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  final ProductSearchDao _dao = ProductSearchDao();

  ProductSearchNotifier() : super(const ProductSearchState());

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true);
    final results = await _dao.searchProducts(query);
    state = state.copyWith(results: results, isLoading: false);
  }

  void selectProduct(ProductSearchItem product) {
    state = state.copyWith(selectedProduct: product);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedProduct: null,
      query: '',
      results: [],
    );
  }
}

/// Provider للبحث عن المنتجات
final productSearchProvider =
    StateNotifierProvider<ProductSearchNotifier, ProductSearchState>((ref) {
  return ProductSearchNotifier();
});
