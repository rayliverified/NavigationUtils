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

      final routes = <DefaultRoute>[];

      final route1 = DefaultRoute(path: '/item');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, routes);
      routes.add(route1.copyWith(cacheKey: key1));

      final route2 = DefaultRoute(path: '/item');
      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, route2, routes);
      routes.add(route2.copyWith(cacheKey: key2));

      final route3 = DefaultRoute(path: '/item');
      final key3 =
          NavigationBuilder.generateCacheKey(navigationData, route3, routes);

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

      final routes = <DefaultRoute>[];

      final route1 = DefaultRoute(path: '/product');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, routes);
      routes.add(route1.copyWith(cacheKey: key1));

      final route2 = DefaultRoute(path: '/product');
      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, route2, routes);
      routes.add(route2.copyWith(cacheKey: key2));

      // Remove the highest indexed route from stack
      routes.removeLast();

      // Create another route and check its key
      final route3 = DefaultRoute(path: '/product');
      final key3 =
          NavigationBuilder.generateCacheKey(navigationData, route3, routes);

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

      final key1 =
          NavigationBuilder.generateCacheKey(navigationData1, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData2, route2, [routeWithKey1]);

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
      // ignore: unused_local_variable
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

    test('set() method clears all cached pages', () {
      // Setup initial routes and router delegate
      final routes = [
        NavigationData(
          label: 'home',
          url: '/home',
          builder: (_, __, ___) => const SizedBox(),
        ),
        NavigationData(
          label: 'details',
          url: '/details',
          builder: (_, __, ___) => const SizedBox(),
        ),
        NavigationData(
          label: 'profile',
          url: '/profile',
          builder: (_, __, ___) => const SizedBox(),
        ),
      ];

      // Create router delegate
      final routerDelegate =
          DefaultRouterDelegate(navigationDataRoutes: routes);

      final simulatedRoutes = <DefaultRoute>[];

      // Create some route entries and generate cache keys
      final route1 = DefaultRoute(path: '/home', label: 'home');
      final key1 = NavigationBuilder.generateCacheKey(
          routes[0], route1, simulatedRoutes);
      simulatedRoutes.add(route1.copyWith(cacheKey: key1));

      final route2 = DefaultRoute(path: '/details', label: 'details');
      final key2 = NavigationBuilder.generateCacheKey(
          routes[1], route2, simulatedRoutes);
      simulatedRoutes.add(route2.copyWith(cacheKey: key2));

      // Add duplicate route to create an indexed cache entry
      final route3 = DefaultRoute(path: '/home', label: 'home');
      final key3 = NavigationBuilder.generateCacheKey(
          routes[0], route3, simulatedRoutes);
      expect(key3, '/home-2', reason: 'Should have created indexed cache key');

      // Call set() method which should clear the cache
      routerDelegate.set(['profile'], apply: false);

      // After set(), simulate starting fresh with empty route stack
      simulatedRoutes.clear();

      // Check if cache was properly cleared by attempting to create a new key
      final route4 = DefaultRoute(path: '/home', label: 'home');
      final key4 = NavigationBuilder.generateCacheKey(
          routes[0], route4, simulatedRoutes);

      // If cache was cleared, we should get the base key again, not an indexed one
      expect(key4, '/home', reason: 'Cache should be cleared after set() call');

      // Create another route to verify indices were reset properly
      simulatedRoutes.add(route4.copyWith(cacheKey: key4));
      final route5 = DefaultRoute(path: '/home', label: 'home');
      final key5 = NavigationBuilder.generateCacheKey(
          routes[0], route5, simulatedRoutes);

      // Should now be the first index after base
      expect(key5, '/home-2',
          reason: 'Index counter should start from 1 after cache clear');
    });

    test('Generate cache key for removed and re-added routes', () {
      final navigationData = NavigationData(
        label: 'downloads',
        url: '/downloads',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];

      // Add the route first time
      final route1 = DefaultRoute(path: '/downloads', label: 'downloads');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, routes);
      routes.add(route1.copyWith(cacheKey: key1));
      expect(key1, '/downloads');

      // Remove the route from stack
      routes.clear();

      // Add the route second time - should get base key again since stack is empty
      final route2 = DefaultRoute(path: '/downloads', label: 'downloads');
      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, route2, routes);
      routes.add(route2.copyWith(cacheKey: key2));
      expect(key2, '/downloads');

      // Add same route again (duplicate) - should get index 2
      final route3 = DefaultRoute(path: '/downloads', label: 'downloads');
      final key3 =
          NavigationBuilder.generateCacheKey(navigationData, route3, routes);
      expect(key3, '/downloads-2',
          reason: 'Second instance in stack should get indexed key');
    });

    test('Navigation scenario: Home -> Downloads -> Pop -> Downloads', () {
      // Clear any existing cache
      NavigationBuilder.clearCache();

      final routes = [
        NavigationData(
          label: 'start',
          url: '/',
          builder: (_, __, ___) => const SizedBox(),
        ),
        NavigationData(
          label: 'downloads',
          url: '/downloads',
          builder: (_, __, ___) => const SizedBox(),
        ),
      ];

      // Create router delegate
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: routes,
        debugLog: true,
      );

      // Step 1: Start with home page - use set() instead of direct assignment
      routerDelegate.set(['/'], apply: false); // Initialize with home route

      // Get the home page route from the delegate
      final homePage = routerDelegate.routes.first;
      final homeKey = homePage.cacheKey ?? '';
      expect(homeKey.isNotEmpty, true,
          reason: 'Home page should have a cache key');

      // Step 2: Add downloads page
      routerDelegate.push('/downloads');

      // Get the downloads page from the routes
      expect(routerDelegate.routes.length, 2,
          reason: 'Should have 2 routes after push');
      final downloadsPage1 = routerDelegate.routes.last;
      final downloadKey1 = downloadsPage1.cacheKey ?? '';
      expect(downloadKey1.isNotEmpty, true,
          reason: 'Downloads page should have a cache key');
      expect(downloadKey1, '/downloads',
          reason: 'First downloads page should have base key');

      // Step 3: Pop downloads page
      routerDelegate.pop();
      expect(routerDelegate.routes.length, 1,
          reason: 'Should have 1 route after pop');

      // Step 4: Add downloads page again
      routerDelegate.push('/downloads');
      expect(routerDelegate.routes.length, 2,
          reason: 'Should have 2 routes after second push');

      // Get the new downloads page
      final downloadsPage2 = routerDelegate.routes.last;
      final downloadKey2 = downloadsPage2.cacheKey ?? '';

      // Check that the key for the second addition is NOT incremented
      expect(downloadKey2, '/downloads',
          reason:
              'When re-adding a previously popped page, it should reuse the base key');

      // Step 5: Let's directly create a new route for the same path
      // to test the cache key generation with the current route stack
      final downloadsPage3 =
          DefaultRoute(path: '/downloads', label: 'downloads');
      final downloadKey3 = NavigationBuilder.generateCacheKey(
          routes[1], downloadsPage3, routerDelegate.routes);

      // Since there's already one downloads page in the stack,
      // this should get an incremented key
      expect(downloadKey3, '/downloads-2',
          reason: 'Adding another page with same path should use indexed key');
    });

    test('Initial route in DefaultRouterDelegate has cache key', () {
      final routes = [
        NavigationData(
          label: 'start',
          url: '/',
          builder: (_, __, ___) => const SizedBox(),
        ),
      ];

      // Create router delegate with initial route using set()
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: routes,
      );

      // Set the initial route properly
      routerDelegate.set(['/'], apply: false);

      // Check that initial route has a cache key
      expect(routerDelegate.routes.first.cacheKey, isNotNull,
          reason: 'Initial route should have a cache key');
    });
  });
}
