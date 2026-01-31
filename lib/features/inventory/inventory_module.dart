// Inventory Feature Module
// Barrel export file for clean imports

// ============ Domain Layer ============

// Entities
export 'domain/entities/product_entity.dart';
export 'domain/entities/inventory_stats.dart';

// Enums
export 'domain/enums/stock_status.dart';
export 'domain/enums/product_sort_type.dart';

// Failures
export 'domain/failures/inventory_failure.dart';

// Validators
export 'domain/validators/product_validator.dart';

// Repository Interface
export 'domain/repositories/inventory_repository.dart';

// Use Cases
export 'domain/usecases/add_product_usecase.dart';
export 'domain/usecases/update_product_usecase.dart';
export 'domain/usecases/delete_product_usecase.dart';
export 'domain/usecases/get_all_products_usecase.dart';
export 'domain/usecases/get_product_by_id_usecase.dart';
export 'domain/usecases/get_inventory_stats_use_case.dart';
export 'domain/usecases/search_products_usecase.dart';
export 'domain/usecases/filter_products_usecase.dart';

// ============ Data Layer ============

// Models
export 'data/models/product_model.dart';
export 'data/models/inventory_stats_model.dart';

// Mappers
export 'data/mappers/product_mapper.dart';
export 'data/mappers/inventory_stats_mapper.dart';

// Datasources
export 'data/datasources/inventory_datasource_interface.dart';
export 'data/datasources/inventory_local_datasource.dart';

// Repository Implementation
export 'data/repositories/inventory_repository_impl.dart';

// ============ Presentation Layer ============

// States
export 'presentation/states/inventory_state.dart';

// Controllers
export 'presentation/controllers/inventory_controller.dart';

// Providers
export 'presentation/providers/inventory_providers.dart';

// Screens
export 'presentation/screens/inventory_screen.dart'
    hide DecorativeCurvesPainter;

// Widgets
export 'presentation/widgets/add_product_dialog.dart';
export 'presentation/widgets/professional_edit_product_dialog.dart';
export 'presentation/widgets/inventory_filters.dart';
export 'presentation/widgets/inventory_stats_widget.dart';
export 'presentation/widgets/barcode_preview_widget.dart';
export 'presentation/widgets/decorative_curves_painter.dart';
