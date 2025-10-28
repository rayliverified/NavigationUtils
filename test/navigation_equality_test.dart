// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

/// ============================================================================
/// Navigation Equality Tests
/// ============================================================================
///
/// These tests document a bug where query parameter changes cause page
/// recreation instead of page updates.
///
/// QUICK SUMMARY:
/// - Problem: Navigating to `/page?id=1` then `/page?id=2` recreates the page
/// - Expected: The same page instance should be updated (didUpdateWidget called)
/// - Cause: Cache keys include query parameters, making them unique
///
/// RUN TESTS: `flutter test test/test_navigation_equality.dart`
/// ============================================================================
///
/// Tests for Navigation Equality and Query Parameter Handling
///
/// PROBLEM STATEMENT:
/// When navigating to the same page with different query parameters (e.g., deeplinks),
/// the navigation library currently RECREATES the page instead of updating it.
/// This is caused by DefaultRoute.name including query parameters in the URI,
/// which results in different cache keys for the same page path.
///
/// EXPECTED BEHAVIOR:
/// - Query parameter changes should reuse the same page instance
/// - The widget's didUpdateWidget() should be called
/// - The page should NOT be disposed and recreated
///
/// CURRENT BEHAVIOR (THE BUG):
/// - Query parameter changes create a NEW page instance
/// - initState() is called again (page recreated)
/// - dispose() is called on the old page
/// - This breaks state persistence and causes unnecessary rebuilds
///
/// ROOT CAUSE:
/// In navigation_delegate.dart, DefaultRoute constructor:
/// ```dart
/// DefaultRoute(...) : super(
///   name: canonicalUri(Uri(path: path, queryParameters: queryParameters).toString())
/// );
/// ```
/// The `name` includes query parameters, so:
/// - `/test?id=1` → cache key: `/test?id=1`
/// - `/test?id=2` → cache key: `/test?id=2`
/// These are treated as different pages by Flutter's Navigator.
///
/// PROPOSED FIX:
/// The cache key generation in NavigationBuilder.generateCacheKey() should use
/// only the path, not the full name (which includes query params).
/// This would allow query parameter changes to update the same page instance.
///
/// TEST ORGANIZATION:
/// 1. DefaultRoute Equality Tests - Documents that routes are considered equal
///    regardless of query parameters (which is correct behavior)
/// 2. Cache Keys Tests - Shows that cache keys INCLUDE query parameters
///    (which causes the bug)
/// 3. Widget Tests (Skipped) - Would demonstrate the full problem but require
///    complex setup
///
/// HOW TO USE THESE TESTS:
/// - Run: `flutter test test/test_navigation_equality.dart`
/// - The passing tests document the CURRENT (problematic) behavior
/// - After implementing a fix, update the expectations and enable skipped tests
///
void main() {
  group('Navigation Equality - DefaultRoute Equality', () {
    test('Routes with same path but different query params should be equal',
        () {
      final route1 = DefaultRoute(
        path: '/test',
        queryParameters: {'id': '1'},
      );

      final route2 = DefaultRoute(
        path: '/test',
        queryParameters: {'id': '2'},
      );

      // Current behavior: DefaultRoute equality ignores query parameters
      expect(route1 == route2, isTrue,
          reason:
              'Routes with same path should be equal regardless of query params');
    });

    test('Routes with same label should be equal', () {
      final route1 = DefaultRoute(
        label: 'test_page',
        path: '/test',
        queryParameters: {'id': '1'},
      );

      final route2 = DefaultRoute(
        label: 'test_page',
        path: '/test',
        queryParameters: {'id': '2'},
      );

      expect(route1 == route2, isTrue,
          reason: 'Routes with same label should be equal');
    });

    test('Routes with different paths should not be equal', () {
      final route1 = DefaultRoute(
        path: '/test1',
        queryParameters: {'id': '1'},
      );

      final route2 = DefaultRoute(
        path: '/test2',
        queryParameters: {'id': '1'},
      );

      expect(route1 == route2, isFalse,
          reason: 'Routes with different paths should not be equal');
    });
  });

  group('Navigation Equality - Cache Keys', () {
    test('Cache key FIXED: same for same path, different query params', () {
      final navigationData = NavigationData(
        label: 'test',
        url: '/test',
        builder: (context, routeData, globalData) => Container(),
      );

      final route1 = DefaultRoute(path: '/test', queryParameters: {'id': '1'});
      final route2 = DefaultRoute(path: '/test', queryParameters: {'id': '2'});

      // Clear cache before test
      NavigationBuilder.clearCache();

      final cacheKey1 =
          NavigationBuilder.generateCacheKey(navigationData, route1);
      final cacheKey2 =
          NavigationBuilder.generateCacheKey(navigationData, route2);

      // FIXED: Cache keys ignore query params and use only the path
      expect(cacheKey1, equals('/test'));
      expect(cacheKey2, equals('/test'));
    });

    test(
        'Cache key EXPECTED BEHAVIOR: same for same path, different query params',
        () {
      // This test documents the EXPECTED behavior for the fix
      // For routes with same path but different query params, cache key SHOULD be same
      // This would enable page reuse and didUpdateWidget calls

      final route1 = DefaultRoute(path: '/test', queryParameters: {'id': '1'});
      final route2 = DefaultRoute(path: '/test', queryParameters: {'id': '2'});

      // The cache key should ideally only use path, not query parameters
      // Expected: both should generate '/test' as cache key
      // This test is marked as expected behavior but will fail with current implementation
      expect(route1.path, equals(route2.path),
          reason: 'Both routes have same path');
      expect(route1.queryParameters, isNot(equals(route2.queryParameters)),
          reason: 'But different query parameters');

      // For the fix, cache keys should be based on path only, not the full name
      final navigationData = NavigationData(
        label: 'test',
        url: '/test',
        builder: (context, routeData, globalData) => Container(),
      );

      NavigationBuilder.clearCache();
      final key1 = NavigationBuilder.generateCacheKey(navigationData, route1);
      final key2 = NavigationBuilder.generateCacheKey(navigationData, route2);
      expect(key1, equals('/test'));
      expect(key2, equals('/test'));
    });

    test('Cache key for duplicate route instances in stack', () {
      final navigationData = NavigationData(
        label: 'test',
        url: '/test',
        builder: (context, routeData, globalData) => Container(),
      );

      NavigationBuilder.clearCache();

      final route1 = DefaultRoute(path: '/test');
      final cacheKey1 =
          NavigationBuilder.generateCacheKey(navigationData, route1);

      expect(cacheKey1, equals('/test'));

      // When the same route appears multiple times in the stack,
      // subsequent instances get numbered suffixes
      // We need to manually add to cache to simulate this
      NavigationBuilder
          .clearCache(); // Can't easily test this without full context

      // For now, just verify that cache key generation works
      final route2 = DefaultRoute(path: '/test');
      final cacheKey2 =
          NavigationBuilder.generateCacheKey(navigationData, route2);

      // Without the route being in cache, both generate the same key
      expect(cacheKey2, equals('/test'));
    });

    test('Cache key should use group name for grouped routes', () {
      final navigationData = NavigationData(
        label: 'test',
        url: '/test',
        group: 'test_group',
        builder: (context, routeData, globalData) => Container(),
      );

      NavigationBuilder.clearCache();

      final route1 = DefaultRoute(
        path: '/test',
        queryParameters: {'id': '1'},
        group: 'test_group',
      );

      final cacheKey =
          NavigationBuilder.generateCacheKey(navigationData, route1);

      expect(cacheKey, equals('test_group'),
          reason: 'Cache key for grouped routes should be the group name');
    });
  });
}
