import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_dao.dart';

/// Provider لـ ProductDAO
final productDaoProvider = Provider<ProductDAO>((ref) {
  return ProductDAO();
});
