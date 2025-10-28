import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

/// Comprehensive tests for cache key generation with query parameters
///
/// This test file validates the EXPECTED behavior where query parameter changes
/// should NOT affect cache keys, allowing pages to be updated instead of recreated.
///
/// Key Principle: Same path + different query params = SAME cache key
///
/// Run: flutter test test/test_cache_query_parameters.dart

void main() {
  group('Cache Keys - Query Parameter Handling', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test(
        'EXPECTED: Same path with different query params should have SAME cache key',
        () {
      final navigationData = NavigationData(
        label: 'product',
        url: '/product',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/product',
        queryParameters: {'id': '1'},
      );

      final route2 = DefaultRoute(
        path: '/product',
        queryParameters: {'id': '2'},
      );

      final cacheKey1 =
          NavigationBuilder.generateCacheKey(navigationData, route1);
      final cacheKey2 =
          NavigationBuilder.generateCacheKey(navigationData, route2);

      // Both should use path-based cache key, ignoring query params
      expect(cacheKey1, equals('/product'),
          reason: 'Cache key should be based on path only');
      expect(cacheKey2, equals('/product'),
          reason: 'Cache key should be based on path only');
      expect(cacheKey1, equals(cacheKey2),
          reason:
              'Same path should produce same cache key regardless of query params');
    });

    test('EXPECTED: Query params added or removed should not change cache key',
        () {
      final navigationData = NavigationData(
        label: 'search',
        url: '/search',
        builder: (_, __, ___) => const SizedBox(),
      );

      // No query params
      final route1 = DefaultRoute(path: '/search');

      // With query params
      final route2 = DefaultRoute(
        path: '/search',
        queryParameters: {'q': 'flutter'},
      );

      // Multiple query params
      final route3 = DefaultRoute(
        path: '/search',
        queryParameters: {'q': 'flutter', 'filter': 'recent'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);
      final key3 = NavigationBuilder.generateCacheKey(navigationData, route3);

      // All should have the same cache key
      expect(key1, equals('/search'));
      expect(key2, equals('/search'));
      expect(key3, equals('/search'));
    });

    test('EXPECTED: Different query param values should not affect cache key',
        () {
      final navigationData = NavigationData(
        label: 'article',
        url: '/article',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = [
        DefaultRoute(path: '/article', queryParameters: {'id': '1'}),
        DefaultRoute(path: '/article', queryParameters: {'id': '2'}),
        DefaultRoute(path: '/article', queryParameters: {'id': '999'}),
        DefaultRoute(
            path: '/article', queryParameters: {'id': '1', 'comment': '42'}),
      ];

      final keys = routes
          .map((r) => NavigationBuilder.generateCacheKey(navigationData, r))
          .toList();

      // All should be the same
      for (var key in keys) {
        expect(key, equals('/article'),
            reason: 'All variations should use path-based cache key');
      }
    });

    test(
        'EXPECTED: Duplicate routes with different query params get indexed keys',
        () {
      final navigationData = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      // First route with query params
      final route1 = DefaultRoute(
        path: '/item',
        queryParameters: {'id': '1'},
      );

      // Second route with different query params (duplicate path)
      final route2 = DefaultRoute(
        path: '/item',
        queryParameters: {'id': '2'},
      );

      // Third route with yet different query params
      final route3 = DefaultRoute(
        path: '/item',
        queryParameters: {'id': '3'},
      );

      final routes = <DefaultRoute>[];

      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, route1, routes);
      routes.add(route1.copyWith(cacheKey: key1));

      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, route2, routes);
      routes.add(route2.copyWith(cacheKey: key2));

      final key3 =
          NavigationBuilder.generateCacheKey(navigationData, route3, routes);

      // First gets base key, subsequent duplicates get indexed
      expect(key1, equals('/item'));
      expect(key2, equals('/item-2'));
      expect(key3, equals('/item-3'));
    });

    test('EXPECTED: Grouped routes ignore query params in cache key', () {
      final navigationData1 = NavigationData(
        label: 'tab1',
        url: '/tab1',
        group: 'home',
        builder: (_, __, ___) => const SizedBox(),
      );

      final navigationData2 = NavigationData(
        label: 'tab2',
        url: '/tab2',
        group: 'home',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/tab1',
        group: 'home',
        queryParameters: {'filter': 'recent'},
      );

      final route2 = DefaultRoute(
        path: '/tab2',
        group: 'home',
        queryParameters: {'sort': 'date'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData1, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData2, route2);

      // Both should use group name, query params don't matter
      expect(key1, equals('home'));
      expect(key2, equals('home'));
    });

    test('EXPECTED: route.name includes query params but cache key should not',
        () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route = DefaultRoute(
        path: '/page',
        queryParameters: {'id': '123', 'tab': 'overview'},
      );

      // route.name includes query parameters (this is the source of the bug)
      expect(route.name, contains('?'),
          reason: 'route.name includes query parameters');
      expect(route.name, contains('id=123'));

      // But cache key should be path-only
      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      expect(cacheKey, equals('/page'),
          reason: 'Cache key should be path-only, not include query params');
      expect(cacheKey, isNot(contains('?')),
          reason: 'Cache key should not include query param markers');
      expect(cacheKey, isNot(contains('id')),
          reason: 'Cache key should not include query param names');
    });

    test('EXPECTED: Complex query strings should not affect cache key', () {
      final navigationData = NavigationData(
        label: 'results',
        url: '/results',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = [
        DefaultRoute(path: '/results'),
        DefaultRoute(path: '/results', queryParameters: {
          'q': 'flutter navigation',
          'page': '1',
          'sort': 'relevance'
        }),
        DefaultRoute(path: '/results', queryParameters: {
          'q': 'dart programming',
          'page': '2',
          'sort': 'date',
          'filter': 'tutorial'
        }),
      ];

      final keys = routes
          .map((r) => NavigationBuilder.generateCacheKey(navigationData, r))
          .toList();

      // All should produce the same cache key
      expect(keys[0], equals('/results'));
      expect(keys[1], equals('/results'));
      expect(keys[2], equals('/results'));
    });

    test('EXPECTED: Path parameters vs query parameters - different handling',
        () {
      // Path parameters are part of the path structure: /user/:id
      // Query parameters are appended: /user?id=123

      final navigationData = NavigationData(
        label: 'user',
        url: '/user/:userId',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routeWithPathParam = DefaultRoute(
        path: '/user/123',
        pathParameters: {'userId': '123'},
      );

      final routeWithQueryParam = DefaultRoute(
        path: '/user/123',
        queryParameters: {'tab': 'profile'},
      );

      final key1 = NavigationBuilder.generateCacheKey(
          navigationData, routeWithPathParam);
      final key2 = NavigationBuilder.generateCacheKey(
          navigationData, routeWithQueryParam);

      // Both should use the path (which includes path param values)
      expect(key1, equals('/user/123'));
      expect(key2, equals('/user/123'));
    });
  });

  group('Cache Keys - Query Parameters with Labels', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('EXPECTED: Routes with labels should use label, ignoring query params',
        () {
      final navigationData = NavigationData(
        label: 'product_detail',
        url: '/product',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/product',
        label: 'product_detail',
        queryParameters: {'id': '1'},
      );

      final route2 = DefaultRoute(
        path: '/product',
        label: 'product_detail',
        queryParameters: {'id': '2'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);

      // Should use label as base key (though current impl might use route.name)
      // The important part is they should be the same
      expect(key1, equals(key2),
          reason:
              'Same label routes should have same cache key regardless of query params');
    });

    test('EXPECTED: Different labels with same path get different cache keys',
        () {
      final navData1 = NavigationData(
        label: 'view1',
        url: '/shared',
        builder: (_, __, ___) => const SizedBox(),
      );

      final navData2 = NavigationData(
        label: 'view2',
        url: '/shared',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/shared',
        label: 'view1',
        queryParameters: {'mode': 'edit'},
      );

      final route2 = DefaultRoute(
        path: '/shared',
        label: 'view2',
        queryParameters: {'mode': 'view'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navData1, route1, []);
      final routeWithKey1 = route1.copyWith(cacheKey: key1);
      final key2 =
          NavigationBuilder.generateCacheKey(navData2, route2, [routeWithKey1]);

      // Same path should produce indexed keys (labels don't affect cache key)
      expect(key1, equals('/shared'));
      expect(key2, equals('/shared-2'),
          reason: 'Same path should create duplicate with indexed key');
    });
  });

  group('Cache Keys - Real World Scenarios', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('SCENARIO: Deeplink navigation with changing IDs', () {
      // User receives deeplink: /article?id=1
      // Then clicks another link: /article?id=2
      // Expected: Same page, updated content

      final navigationData = NavigationData(
        label: 'article',
        url: '/article',
        builder: (_, __, ___) => const SizedBox(),
      );

      final deeplink1 = DefaultRoute.fromUrl('/article?id=1');
      final deeplink2 = DefaultRoute.fromUrl('/article?id=2');

      final key1 =
          NavigationBuilder.generateCacheKey(navigationData, deeplink1);
      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, deeplink2);

      expect(key1, equals(key2),
          reason: 'Deeplinks with different IDs should reuse same page');
      expect(key1, equals('/article'));
    });

    test('SCENARIO: Search with changing query terms', () {
      // User searches for "flutter", then "dart"
      // Expected: Same search page, different results

      final navigationData = NavigationData(
        label: 'search',
        url: '/search',
        builder: (_, __, ___) => const SizedBox(),
      );

      final search1 = DefaultRoute(
        path: '/search',
        queryParameters: {'q': 'flutter'},
      );

      final search2 = DefaultRoute(
        path: '/search',
        queryParameters: {'q': 'dart'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData, search1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, search2);

      expect(key1, equals(key2),
          reason: 'Different search queries should reuse same page');
      expect(key1, equals('/search'));
    });

    test('SCENARIO: Pagination with page numbers', () {
      // User navigates through pages: ?page=1, ?page=2, ?page=3
      // Expected: Same list page, updated content

      final navigationData = NavigationData(
        label: 'list',
        url: '/list',
        builder: (_, __, ___) => const SizedBox(),
      );

      final pages = [
        DefaultRoute(path: '/list', queryParameters: {'page': '1'}),
        DefaultRoute(path: '/list', queryParameters: {'page': '2'}),
        DefaultRoute(path: '/list', queryParameters: {'page': '3'}),
      ];

      final keys = pages
          .map((r) => NavigationBuilder.generateCacheKey(navigationData, r))
          .toList();

      expect(keys[0], equals(keys[1]));
      expect(keys[1], equals(keys[2]));
      expect(keys[0], equals('/list'));
    });

    test('SCENARIO: Filter toggles on list page', () {
      // User toggles filters: no filter -> category filter -> sort + category
      // Expected: Same page, updated filter state

      final navigationData = NavigationData(
        label: 'products',
        url: '/products',
        builder: (_, __, ___) => const SizedBox(),
      );

      final noFilter = DefaultRoute(path: '/products');
      final withCategory = DefaultRoute(
        path: '/products',
        queryParameters: {'category': 'electronics'},
      );
      final withMultipleFilters = DefaultRoute(
        path: '/products',
        queryParameters: {'category': 'electronics', 'sort': 'price'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData, noFilter);
      final key2 =
          NavigationBuilder.generateCacheKey(navigationData, withCategory);
      final key3 = NavigationBuilder.generateCacheKey(
          navigationData, withMultipleFilters);

      expect(key1, equals(key2));
      expect(key2, equals(key3));
      expect(key1, equals('/products'));
    });

    test('SCENARIO: Multiple items in stack with query params', () {
      // User navigates: /list -> /item?id=1 -> /item?id=2
      // Expected: /list uses one page, two item pages (duplicates)

      final listNav = NavigationData(
        label: 'list',
        url: '/list',
        builder: (_, __, ___) => const SizedBox(),
      );

      final itemNav = NavigationData(
        label: 'item',
        url: '/item',
        builder: (_, __, ___) => const SizedBox(),
      );

      final routes = <DefaultRoute>[];

      final list = DefaultRoute(path: '/list');
      final listKey = NavigationBuilder.generateCacheKey(listNav, list, routes);
      routes.add(list.copyWith(cacheKey: listKey));

      final item1 = DefaultRoute(path: '/item', queryParameters: {'id': '1'});
      final itemKey1 =
          NavigationBuilder.generateCacheKey(itemNav, item1, routes);
      routes.add(item1.copyWith(cacheKey: itemKey1));

      final item2 = DefaultRoute(path: '/item', queryParameters: {'id': '2'});
      final itemKey2 =
          NavigationBuilder.generateCacheKey(itemNav, item2, routes);

      expect(listKey, equals('/list'));
      expect(itemKey1, equals('/item'));
      expect(itemKey2, equals('/item-2'),
          reason: 'Second item is duplicate, should get indexed key');
    });

    test('SCENARIO: Tab navigation with query params in content', () {
      // User has tabs, content within tabs uses query params
      // Tabs use groups, content uses regular routing

      final tabNav1 = NavigationData(
        label: 'home_tab',
        url: '/',
        group: 'tabs',
        builder: (_, __, ___) => const SizedBox(),
      );

      final tabNav2 = NavigationData(
        label: 'explore_tab',
        url: '/explore',
        group: 'tabs',
        builder: (_, __, ___) => const SizedBox(),
      );

      final detailNav = NavigationData(
        label: 'detail',
        url: '/detail',
        builder: (_, __, ___) => const SizedBox(),
      );

      final homeTab = DefaultRoute(path: '/', group: 'tabs');
      final exploreTab = DefaultRoute(path: '/explore', group: 'tabs');
      final detail1 =
          DefaultRoute(path: '/detail', queryParameters: {'id': '1'});
      final detail2 =
          DefaultRoute(path: '/detail', queryParameters: {'id': '2'});

      final homeKey = NavigationBuilder.generateCacheKey(tabNav1, homeTab);
      final exploreKey =
          NavigationBuilder.generateCacheKey(tabNav2, exploreTab);
      final detailKey1 = NavigationBuilder.generateCacheKey(detailNav, detail1);
      final detailKey2 = NavigationBuilder.generateCacheKey(detailNav, detail2);

      expect(homeKey, equals('tabs'));
      expect(exploreKey, equals('tabs'));
      expect(detailKey1, equals('/detail'));
      expect(detailKey2, equals('/detail'));
    });
  });

  group('Cache Keys - Edge Cases', () {
    setUp(() {
      NavigationBuilder.clearCache();
    });

    test('EDGE CASE: Empty query parameters', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(path: '/page');
      final route2 = DefaultRoute(path: '/page', queryParameters: {});

      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);

      expect(key1, equals(key2));
      expect(key1, equals('/page'));
    });

    test('EDGE CASE: Query params with special characters', () {
      final navigationData = NavigationData(
        label: 'search',
        url: '/search',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route = DefaultRoute(
        path: '/search',
        queryParameters: {
          'q': 'hello world!',
          'filter': 'type=article&status=published'
        },
      );

      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      expect(cacheKey, equals('/search'),
          reason:
              'Special characters in query params should not affect cache key');
    });

    test('EDGE CASE: Very long query parameter values', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final longValue = 'a' * 1000;
      final route = DefaultRoute(
        path: '/page',
        queryParameters: {'data': longValue},
      );

      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      expect(cacheKey, equals('/page'));
      expect(cacheKey.length, lessThan(100),
          reason: 'Cache key should be short regardless of query param length');
    });

    test('EDGE CASE: Many query parameters', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final manyParams = {for (var i = 0; i < 50; i++) 'param$i': 'value$i'};

      final route = DefaultRoute(
        path: '/page',
        queryParameters: manyParams,
      );

      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route);

      expect(cacheKey, equals('/page'),
          reason:
              'Cache key should be simple regardless of number of query params');
    });

    test('EDGE CASE: Query params with null or empty values', () {
      final navigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (_, __, ___) => const SizedBox(),
      );

      final route1 = DefaultRoute(
        path: '/page',
        queryParameters: {'key': ''},
      );

      final route2 = DefaultRoute(
        path: '/page',
        queryParameters: {'key': 'value'},
      );

      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);

      expect(key1, equals(key2));
      expect(key1, equals('/page'));
    });
  });
}
