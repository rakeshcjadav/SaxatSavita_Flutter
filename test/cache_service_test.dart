import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/services/cache_service.dart';

void main() {
  group('CacheService Tests', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService();
    });

    testWidgets('clearAllLocalCache should complete without error', (
      WidgetTester tester,
    ) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'test_key': 'test_value',
        'another_key': 'another_value',
      });

      // Test that clearAllLocalCache completes without throwing
      expect(() => cacheService.clearAllLocalCache(), returnsNormally);
    });

    testWidgets('clearLocalCacheOnly should complete without error', (
      WidgetTester tester,
    ) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({'test_key': 'test_value'});

      // Test that clearLocalCacheOnly completes without throwing
      expect(() => cacheService.clearLocalCacheOnly(), returnsNormally);
    });

    testWidgets('getCacheInfo should return cache information', (
      WidgetTester tester,
    ) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'test_key': 'test_value',
        'another_key': 'another_value',
      });

      final cacheInfo = await cacheService.getCacheInfo();

      expect(cacheInfo, isA<Map<String, dynamic>>());
      expect(cacheInfo['sharedPreferences'], isNotNull);
      expect(cacheInfo['inMemory'], isNotNull);
    });
  });
}
