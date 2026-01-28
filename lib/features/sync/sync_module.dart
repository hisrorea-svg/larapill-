/// Multi-Terminal Sync Module
///
/// Clean Architecture structure:
/// - domain/ - Business logic (entities, failures, repositories, usecases)
/// - data/ - Data layer (models, mappers, datasources, repositories)
/// - infrastructure/ - Server and constants
/// - presentation/ - UI (providers, screens, widgets)
library;

// Domain
export 'domain/domain.dart';

// Data
export 'data/data.dart';

// Infrastructure
export 'infrastructure/infrastructure.dart';

// Presentation
export 'presentation/presentation.dart';
