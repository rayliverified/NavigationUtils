import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('NavigationBuilder Cache Key Direct Tests', () {
    // Reset cache between tests
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('Generate cache key for basic route', () {
      final navigationData = NavigationData(
        label: 'home',
        url: '/home',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route = DefaultRoute(
        path: '/home',
        label: 'home',
      );

      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      // Should use name or path for non-grouped routes
      expect(cacheKey, '/home');
    });

    test('Generate cache key for grouped route', () {
      final navigationData = NavigationData(
        label: 'tab1',
        url: '/tabs/1',
        builder: (_, __, ___) => const SizedBox(),
        group: 'tabs',
      );

      final route = DefaultRoute(
        path: '/tabs/1',
        label: 'tab1',
        group: 'tabs',
      );

      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      // Should use group name for grouped routes
      expect(cacheKey, 'tabs');
    });

    test('Generate cache keys for duplicate routes', () {
      final navigationData = NavigationData(
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/item');
      final route2 = DefaultRoute(path: '/item');
      final route3 = DefaultRoute(path: '/item');

      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);
      final key3 = NavigationBuilder.generateCacheKey(navigationData, route3);

      // First key should be the base path
      expect(key1, '/item');

      // Subsequent keys should have incremented indices
      expect(key2, '/item-2');
      expect(key3, '/item-3');
    });

    test('Clear cached route with indexed suffix', () {
      final navigationData = NavigationData(
        url: '/product',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/product');
      final route2 = DefaultRoute(path: '/product');

      // Generate keys with indices
      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);

      // Clear the highest indexed route
      NavigationBuilder.clearCachedRoute(
          DefaultRoute(path: '/product', cacheKey: key2));

      // Create another route and check its key
      final route3 = DefaultRoute(path: '/product');
      final key3 = NavigationBuilder.generateCacheKey(navigationData, route3);

      // Should reuse the index 2 since it was cleared
      expect(key3, '/product-2');
    });

    test('Handle route without cache key', () {
      final route = DefaultRoute(path: '/settings');

      // Shouldn't throw when clearing a route without cache key
      expect(() => NavigationBuilder.clearCachedRoute(route), returnsNormally);
    });

    test('Clear cache for grouped route', () {
      final route = DefaultRoute(
        path: '/tab/1',
        group: 'tabs',
      );

      // Shouldn't throw when clearing a grouped route
      expect(() => NavigationBuilder.clearCachedRoute(route), returnsNormally);
    });

    test('Generate cache key preserves route instance', () {
      final navigationData = NavigationData(
        url: '/details',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route = DefaultRoute(
        path: '/details',
        label: 'details',
        arguments: {'id': 123},
      );

      // Generate a cache key
      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      // Create a new route with the cache key
      final routeWithKey = route.copyWith(cacheKey: cacheKey);

      // Original route should remain unchanged
      expect(route.cacheKey, isNull);

      // New route should have the cache key but retain all other properties
      expect(routeWithKey.cacheKey, cacheKey);
      expect(routeWithKey.path, route.path);
      expect(routeWithKey.label, route.label);
      expect(routeWithKey.arguments, route.arguments);
    });

    test('Cache key for routes with same path but different labels', () {
      final navigationData1 = NavigationData(
        label: 'settings1',
        url: '/settings',
        builder: (_, __, ___) => const SizedBox(),
      );

      final navigationData2 = NavigationData(
        label: 'settings2',
        url: '/settings',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/settings',
        label: 'settings1',
      );

      final route2 = DefaultRoute(
        path: '/settings',
        label: 'settings2',
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData1, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData2, route2);

      // Should generate different cache keys due to different labels
      expect(key1, '/settings');
      expect(key2, '/settings-2');
    });

    test('Clear entire cache', () {
      final navigationData = NavigationData(
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/page1');
      final route2 = DefaultRoute(path: '/page2');

      // Generate some cache keys
      NavigationBuilder.generateCacheKey(navigationData, route1);
      NavigationBuilder.generateCacheKey(navigationData, route2);

      // Clear entire cache
      NavigationBuilder.clearCache();

      // Next key should be back to base path
      final route3 = DefaultRoute(path: '/page1');
      final key3 = NavigationBuilder.generateCacheKey(navigationData, route3);
      expect(key3, '/page1');
    });

    test('Cache behavior with multiple grouped routes in same group', () {
      final commonGroup = 'tabGroup';

      final navigationData1 = NavigationData(
        label: 'tab1',
        url: '/tabs/1',
        builder: (_, __, ___) => const SizedBox(),
        group: commonGroup,
      );

      final navigationData2 = NavigationData(
        label: 'tab2',
        url: '/tabs/2',
        builder: (_, __, ___) => const SizedBox(),
        group: commonGroup,
      );

      final route1 = DefaultRoute(
        path: '/tabs/1',
        label: 'tab1',
        group: commonGroup,
      );

      final route2 = DefaultRoute(
        path: '/tabs/2',
        label: 'tab2',
        group: commonGroup,
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData1, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData2, route2);

      // Both should use the group name as cache key
      expect(key1, commonGroup);
      expect(key2, commonGroup);
      expect(key1, equals(key2));
    });

    test('Clear cached route from one group doesn\'t affect other groups', () {
      final navigationData1 = NavigationData(
        url: '/tab1',
        builder: (_, __, ___) => const SizedBox(),
        group: 'group1',
      );

      final navigationData2 = NavigationData(
        url: '/tab2',
        builder: (_, __, ___) => const SizedBox(),
        group: 'group2',
      );

      final route1 = DefaultRoute(
        path: '/tab1',
        group: 'group1',
      );

      final route2 = DefaultRoute(
        path: '/tab2',
        group: 'group2',
      );

      // Generate cache keys
      final key1 = NavigationBuilder.generateCacheKey(navigationData1, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData2, route2);

      // Clear the first route
      NavigationBuilder.clearCachedRoute(route1.copyWith(cacheKey: key1));

      // Create another route in second group
      final route3 = DefaultRoute(
        path: '/tab3',
        group: 'group2',
      );

      final key3 = NavigationBuilder.generateCacheKey(navigationData2, route3);

      // Should still use group2 as the key
      expect(key3, 'group2');
    });
  });
}
