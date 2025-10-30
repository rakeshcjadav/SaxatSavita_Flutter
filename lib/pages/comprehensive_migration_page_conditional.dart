// Conditional export for ComprehensiveMigrationPage
// In debug mode: uses the real implementation
// In release mode: uses the stub implementation

export 'comprehensive_migration_page_stub.dart'
    if (dart.vm.product) 'comprehensive_migration_page_stub.dart'
    if (dart.library.io) '../debug_only/comprehensive_migration_page.dart';
