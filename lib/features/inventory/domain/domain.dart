/// Inventory Domain Layer Exports
library inventory_domain;

// Entities
export 'entities/product_entity.dart';
export 'entities/add_product_params.dart';
export 'entities/inventory_stats.dart';

// Repositories
export 'repositories/inventory_repository.dart';

// Use Cases
export 'usecases/add_product_usecase.dart';
export 'usecases/get_all_products_usecase.dart';
export 'usecases/update_product_usecase.dart';
export 'usecases/delete_product_usecase.dart';
export 'usecases/search_products_usecase.dart';
