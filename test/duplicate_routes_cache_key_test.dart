import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

/// Comprehensive tests for duplicate route handling and cache key indexing
///
/// This test suite validates that multiple instances of the same route path
/// can coexist in the navigation stack with unique cache keys.
///
/// Key Principle: Same path pushed multiple times = Indexed cache keys
/// - First instance: /path
/// - Second instance: /path-2
/// - Third instance: /path-3
/// - And so on...
///
/// Run: flutter test test/test_duplicate_routes_comprehensive.dart

void main() {
  group('Duplicate Routes - Cache Key Indexing', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('First instance of a route gets base cache key', () {
      final navigationData = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route = DefaultRoute(path: '/item');
      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      expect(cacheKey, equals('/item'),
          reason: 'First instance should get base cache key without index');
    });

    test('Second instance of same route gets indexed cache key', () {
      final navigationData = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/item');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);

      final route2 = DefaultRoute(path: '/item');
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, route2, [routeWithKey1]);

      expect(key1, equals('/item'));
      expect(key2, equals('/item-2'),
          reason: 'Second instance should get indexed cache key');
    });

    test('Multiple duplicates get incrementing indices', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final keys = <String>[];
      final routes = <DefaultRoute>[];
      for (int i = 0; i < 5; i++) {
        final route = DefaultRoute(path: '/page');
        final key =
            NavigationBuilder.generateCacheKey(navigationData, route, routes);
        keys.add(key);
        routes.add(route.copyWith(cacheKey: key));
      }

      expect(keys[0], equals('/page'));
      expect(keys[1], equals('/page-2'));
      expect(keys[2], equals('/page-3'));
      expect(keys[3], equals('/page-4'));
      expect(keys[4], equals('/page-5'));
    });

    test('Different routes maintain separate index counters', () {
      final routes = <DefaultRoute>[];
      final itemNav = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final productNav = NavigationData(
        label: 'product',
        url: '/product',
        builder: (_, __, ___) => const SizedBox(),
      );

      // Push items and products interleaved
      final item1 = DefaultRoute(path: '/item');
      final itemKey1 =
          NavigationBuilder.generateCacheKey(itemNav, item1, routes);
      routes.add(item1.copyWith(cacheKey: itemKey1));

      final prod1 = DefaultRoute(path: '/product');
      final prodKey1 =
          NavigationBuilder.generateCacheKey(productNav, prod1, routes);
      routes.add(prod1.copyWith(cacheKey: prodKey1));

      final item2 = DefaultRoute(path: '/item');
      final itemKey2 =
          NavigationBuilder.generateCacheKey(itemNav, item2, routes);
      routes.add(item2.copyWith(cacheKey: itemKey2));

      final prod2 = DefaultRoute(path: '/product');
      final prodKey2 =
          NavigationBuilder.generateCacheKey(productNav, prod2, routes);

      expect(itemKey1, equals('/item'));
      expect(prodKey1, equals('/product'));
      expect(itemKey2, equals('/item-2'));
      expect(prodKey2, equals('/product-2'));
    });

    test('Cache key with query parameters creates duplicate on second push',
        () {
      final navigationData = NavigationData(
        label: 'article',
        url: '/article',
        builder: (_, __, ___) => const SizedBox(),
      );

      // After fix, query params don't affect base cache key
      // But pushing same path twice still creates duplicate
      final route1 = DefaultRoute(
        path: '/article',
        queryParameters: {'id': '1'},
      );

      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);

      final route2 = DefaultRoute(
        path: '/article',
        queryParameters: {'id': '2'},
      );

      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, route2, [routeWithKey1]);

      // Both use /article as base, so second gets indexed
      expect(key1, equals('/article'));
      expect(key2, equals('/article-2'),
          reason:
              'Same path creates duplicate even with different query params');
    });
  });

  group('Duplicate Routes - Index Reuse After Removal', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('Removing middle indexed route allows index reuse', () {
      final navigationData = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];

      // Create three instances
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
      routes.add(route3.copyWith(cacheKey: key3));

      expect(key1, equals('/item'));
      expect(key2, equals('/item-2'));
      expect(key3, equals('/item-3'));

      // Remove the middle one (index 2) from the stack
      routes.removeAt(1);

      // Push another - should reuse index 2
      final route4 = DefaultRoute(path: '/item');
      final key4 =
          NavigationBuilder.generateCacheKey(navigationData, route4, routes);

      expect(key4, equals('/item-2'),
          reason: 'Should reuse the cleared index 2');
    });

    test('Removing base key allows it to be reused', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];

      // Create two instances
      final route1 = DefaultRoute(path: '/page');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, routes);
      routes.add(route1.copyWith(cacheKey: key1));

      final route2 = DefaultRoute(path: '/page');
      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, route2, routes);
      routes.add(route2.copyWith(cacheKey: key2));

      expect(key1, equals('/page'));
      expect(key2, equals('/page-2'));

      // Remove the base one from stack
      routes.removeAt(0);

      // Push another - should get base key back
      final route3 = DefaultRoute(path: '/page');
      final key3 =
          NavigationBuilder.generateCacheKey(navigationData, route3, routes);

      expect(key3, equals('/page'),
          reason: 'Should reuse the base key when available');
    });

    test('Removing highest index decrements counter correctly', () {
      final navigationData = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];

      // Create three instances
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
      routes.add(route3.copyWith(cacheKey: key3));

      // Remove highest index (3) from stack
      routes.removeLast();

      // Push another - should get index 3 again
      final route4 = DefaultRoute(path: '/item');
      final key4 =
          NavigationBuilder.generateCacheKey(navigationData, route4, routes);

      expect(key4, equals('/item-3'),
          reason: 'Should reuse highest index after it was cleared');
    });

    test('Multiple removals and additions maintain proper indices', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      // Create stack: /page, /page-2, /page-3, /page-4
      final routes = <DefaultRoute>[];
      final keys = <String>[];

      for (int i = 0; i < 4; i++) {
        final route = DefaultRoute(path: '/page');
        final key =
            NavigationBuilder.generateCacheKey(navigationData, route, routes);
        routes.add(route.copyWith(cacheKey: key));
        keys.add(key);
      }

      expect(keys, equals(['/page', '/page-2', '/page-3', '/page-4']));

      // Remove /page-2 and /page-3 from stack
      routes.removeWhere(
          (r) => r.cacheKey == '/page-2' || r.cacheKey == '/page-3');

      // Add two more - should fill the gaps
      final route5 = DefaultRoute(path: '/page');
      final key5 =
          NavigationBuilder.generateCacheKey(navigationData, route5, routes);
      routes.add(route5.copyWith(cacheKey: key5));

      final route6 = DefaultRoute(path: '/page');
      final key6 =
          NavigationBuilder.generateCacheKey(navigationData, route6, routes);

      expect(key5, equals('/page-2'), reason: 'Should fill first gap');
      expect(key6, equals('/page-3'), reason: 'Should fill second gap');
    });
  });

  group('Duplicate Routes - Real-World Navigation Flows', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('SCENARIO: Multiple product detail pages in stack', () {
      final productNav = NavigationData(
        label: 'product',
        url: '/product',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];

      // User browses products and opens multiple detail pages
      final product1 =
          DefaultRoute(path: '/product', queryParameters: {'id': '123'});
      final key1 =
          NavigationBuilder.generateCacheKey(productNav, product1, routes);
      routes.add(product1.copyWith(cacheKey: key1));

      final product2 =
          DefaultRoute(path: '/product', queryParameters: {'id': '456'});
      final key2 =
          NavigationBuilder.generateCacheKey(productNav, product2, routes);
      routes.add(product2.copyWith(cacheKey: key2));

      final product3 =
          DefaultRoute(path: '/product', queryParameters: {'id': '789'});
      final key3 =
          NavigationBuilder.generateCacheKey(productNav, product3, routes);

      expect(key1, equals('/product'));
      expect(key2, equals('/product-2'));
      expect(key3, equals('/product-3'));

      // All three products can coexist in the navigation stack
      // User can go back through all of them
    });

    test('SCENARIO: Article with related articles', () {
      final articleNav = NavigationData(
        label: 'article',
        url: '/article',
        builder: (_, __, ___) => const SizedBox(),
      );

      // User reads an article, then clicks related articles
      final routes = <DefaultRoute>[];
      final keys = <String>[];
      for (int articleId = 1; articleId <= 5; articleId++) {
        final route = DefaultRoute(
          path: '/article',
          queryParameters: {'id': '$articleId'},
        );
        final key =
            NavigationBuilder.generateCacheKey(articleNav, route, routes);
        routes.add(route.copyWith(cacheKey: key));
        keys.add(key);
      }

      expect(
          keys,
          equals([
            '/article',
            '/article-2',
            '/article-3',
            '/article-4',
            '/article-5',
          ]));

      // User can navigate back through entire reading history
    });

    test('SCENARIO: Search results with detail pages', () {
      final searchNav = NavigationData(
        label: 'search',
        url: '/search',
        builder: (_, __, ___) => const SizedBox(),
      );

      final itemNav = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      // User searches, views items, searches again
      final routes = <DefaultRoute>[];

      final search1 =
          DefaultRoute(path: '/search', queryParameters: {'q': 'flutter'});
      final search1Key =
          NavigationBuilder.generateCacheKey(searchNav, search1, routes);
      routes.add(search1.copyWith(cacheKey: search1Key));

      final item1 = DefaultRoute(path: '/item', queryParameters: {'id': '1'});
      final item1Key =
          NavigationBuilder.generateCacheKey(itemNav, item1, routes);
      routes.add(item1.copyWith(cacheKey: item1Key));

      final item2 = DefaultRoute(path: '/item', queryParameters: {'id': '2'});
      final item2Key =
          NavigationBuilder.generateCacheKey(itemNav, item2, routes);
      routes.add(item2.copyWith(cacheKey: item2Key));

      final search2 =
          DefaultRoute(path: '/search', queryParameters: {'q': 'dart'});
      final search2Key =
          NavigationBuilder.generateCacheKey(searchNav, search2, routes);

      expect(search1Key, equals('/search'));
      expect(item1Key, equals('/item'));
      expect(item2Key, equals('/item-2'));
      expect(search2Key, equals('/search-2'));

      // Navigation stack: /search → /item → /item-2 → /search-2
    });

    test('SCENARIO: Pop back to previous duplicate removes correct instance',
        () {
      final pageNav = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      // Build stack: /page → /page-2 → /page-3
      final routes = <DefaultRoute>[];

      final route1 = DefaultRoute(path: '/page');
      final key1 = NavigationBuilder.generateCacheKey(pageNav, route1, routes);
      routes.add(route1.copyWith(cacheKey: key1));

      final route2 = DefaultRoute(path: '/page');
      final key2 = NavigationBuilder.generateCacheKey(pageNav, route2, routes);
      routes.add(route2.copyWith(cacheKey: key2));

      final route3 = DefaultRoute(path: '/page');
      final key3 = NavigationBuilder.generateCacheKey(pageNav, route3, routes);
      routes.add(route3.copyWith(cacheKey: key3));

      // Simulate pop (remove route3)
      routes.removeLast();

      // Route 1 and 2 should still exist in stack
      // If we were to push again, we should get index 3 back
      final route4 = DefaultRoute(path: '/page');
      final key4 = NavigationBuilder.generateCacheKey(pageNav, route4, routes);

      expect(key4, equals('/page-3'),
          reason: 'After popping /page-3, pushing again reuses that index');
    });
  });

  group('Duplicate Routes - Edge Cases', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('EDGE CASE: Very deep stack (10+ duplicates)', () {
      final navigationData = NavigationData(
        label: 'deep',
        url: '/deep',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];
      final keys = <String>[];
      for (int i = 0; i < 15; i++) {
        final route = DefaultRoute(path: '/deep');
        final key =
            NavigationBuilder.generateCacheKey(navigationData, route, routes);
        routes.add(route.copyWith(cacheKey: key));
        keys.add(key);
      }

      expect(keys[0], equals('/deep'));
      expect(keys[1], equals('/deep-2'));
      expect(keys[9], equals('/deep-10'));
      expect(keys[14], equals('/deep-15'));

      // Should handle deep stacks without issue
    });

    test('EDGE CASE: Clear cache resets all indices', () {
      final navigationData = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      // Create some duplicates
      for (int i = 0; i < 3; i++) {
        NavigationBuilder.generateCacheKey(
          navigationData,
          DefaultRoute(path: '/item'),
        );
      }

      // Clear everything
      NavigationBuilder.clearCache();

      // Next key should be base again
      final route = DefaultRoute(path: '/item');
      final key = NavigationBuilder.generateCacheKey(navigationData, route);

      expect(key, equals('/item'),
          reason: 'After clearing cache, should start from base key');
    });

    test('EDGE CASE: Explicit cache key bypasses duplicate system', () {
      final navigationData = NavigationData(
        label: 'custom',
        url: '/custom',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/custom',
        cacheKey: 'my-custom-key',
      );

      final route2 = DefaultRoute(path: '/custom');

      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, route2, [routeWithKey1]);

      expect(key1, equals('my-custom-key'),
          reason: 'Explicit cache key is used as-is');
      expect(key2, equals('/custom'),
          reason: 'Auto-generated key is independent of explicit keys');

      // Note: Using explicit keys bypasses duplicate protection!
      // If you set two routes with same explicit key, Navigator will break
    });

    test('EDGE CASE: Path with hyphens doesn\'t confuse indexing', () {
      final navigationData = NavigationData(
        label: 'my-page',
        url: '/my-page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/my-page');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);

      final route2 = DefaultRoute(path: '/my-page');
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, route2, [routeWithKey1]);

      expect(key1, equals('/my-page'));
      expect(key2, equals('/my-page-2'),
          reason: 'Hyphenated paths should still get indexed correctly');
    });

    test('EDGE CASE: Numeric paths', () {
      final navigationData = NavigationData(
        label: '404',
        url: '/404',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/404');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);

      final route2 = DefaultRoute(path: '/404');
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, route2, [routeWithKey1]);

      expect(key1, equals('/404'));
      expect(key2, equals('/404-2'));
    });

    test('EDGE CASE: Root path duplicates', () {
      final navigationData = NavigationData(
        label: 'root',
        url: '/',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/');
      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);

      final route2 = DefaultRoute(path: '/');
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, route2, [routeWithKey1]);

      expect(key1, equals('/'));
      expect(key2, equals('/-2'), reason: 'Even root path can have duplicates');
    });
  });

  group('Duplicate Routes - Grouped Routes Behavior', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('Grouped routes DO NOT create duplicates', () {
      final tab1Nav = NavigationData(
        label: 'home',
        url: '/',
        group: 'tabs',
        builder: (_, __, ___) => const SizedBox(),
      );

      final tab2Nav = NavigationData(
        label: 'explore',
        url: '/explore',
        group: 'tabs',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/', group: 'tabs');
      final route2 = DefaultRoute(path: '/explore', group: 'tabs');
      final route3 = DefaultRoute(path: '/', group: 'tabs');

      final key1 = NavigationBuilder.generateCacheKey(tab1Nav, route1);
      final key2 = NavigationBuilder.generateCacheKey(tab2Nav, route2);
      final key3 = NavigationBuilder.generateCacheKey(tab1Nav, route3);

      // All use the same group name as cache key
      expect(key1, equals('tabs'));
      expect(key2, equals('tabs'));
      expect(key3, equals('tabs'));

      // Groups replace each other, they don't duplicate
    });

    test('Mixed grouped and non-grouped routes', () {
      final tabNav = NavigationData(
        label: 'home',
        url: '/',
        group: 'tabs',
        builder: (_, __, ___) => const SizedBox(),
      );

      final itemNav = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      // Stack: tab → item → tab → item
      final routes = <DefaultRoute>[];

      final tab1 = DefaultRoute(path: '/', group: 'tabs');
      final tabKey1 = NavigationBuilder.generateCacheKey(tabNav, tab1, routes);
      routes.add(tab1.copyWith(cacheKey: tabKey1));

      final item1 = DefaultRoute(path: '/item');
      final itemKey1 =
          NavigationBuilder.generateCacheKey(itemNav, item1, routes);
      routes.add(item1.copyWith(cacheKey: itemKey1));

      final tab2 = DefaultRoute(path: '/', group: 'tabs');
      final tabKey2 = NavigationBuilder.generateCacheKey(tabNav, tab2, routes);
      routes.add(tab2.copyWith(cacheKey: tabKey2));

      final item2 = DefaultRoute(path: '/item');
      final itemKey2 =
          NavigationBuilder.generateCacheKey(itemNav, item2, routes);

      expect(tabKey1, equals('tabs'));
      expect(itemKey1, equals('/item'));
      expect(tabKey2, equals('tabs')); // Same group key
      expect(itemKey2, equals('/item-2')); // Indexed non-grouped

      // Tabs don't duplicate (same group), items do duplicate
    });
  });

  group('Duplicate Routes - Label vs Path', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('Routes with same label but different paths use label for key', () {
      final nav1 = NavigationData(
        label: 'profile',
        url: '/user/:id',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/user/123', label: 'profile');
      final key1 = NavigationBuilder.generateCacheKey(nav1, route1, []);

      final route2 = DefaultRoute(path: '/user/456', label: 'profile');
      final key2 = NavigationBuilder.generateCacheKey(
          nav1, route2, [route1.copyWith(cacheKey: key1)]);

      // Both different paths but same label
      // After fix, should use path for cache key base
      // But since paths are different, they get different base keys
      expect(key1, equals('/user/123'));
      expect(key2, equals('/user/456'));
    });

    test('Routes with different labels but same path', () {
      final nav1 = NavigationData(
        label: 'view1',
        url: '/shared',
        builder: (_, __, ___) => const SizedBox(),
      );

      final nav2 = NavigationData(
        label: 'view2',
        url: '/shared',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/shared', label: 'view1');
      final key1 = NavigationBuilder.generateCacheKey(nav1, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);

      final route2 = DefaultRoute(path: '/shared', label: 'view2');
      final key2 =
          NavigationBuilder.generateCacheKey(nav2, route2, [routeWithKey1]);

      // Same path, so second gets indexed
      // (Assuming fix is applied and we use route.path)
      expect(key1, equals('/shared'));
      expect(key2, equals('/shared-2'));
    });
  });
}
