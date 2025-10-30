// Conditional export for MarketingShowcasePage
// In debug mode: uses the real implementation
// In release mode: uses the stub implementation

export 'marketing_showcase_page_stub.dart'
    if (dart.vm.product) 'marketing_showcase_page_stub.dart'
    if (dart.library.io) '../debug_only/marketing_showcase_page.dart';
