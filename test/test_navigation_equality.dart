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
/// Test widget that tracks lifecycle callbacks to verify widget updates vs recreations
class TestPageWidget extends StatefulWidget {
  final String id;
  final String? category;
  final VoidCallback? onInit;
  final VoidCallback? onUpdate;
  final VoidCallback? onDispose;

  const TestPageWidget({
    super.key,
    required this.id,
    this.category,
    this.onInit,
    this.onUpdate,
    this.onDispose,
  });

  @override
  State<TestPageWidget> createState() => _TestPageWidgetState();
}

class _TestPageWidgetState extends State<TestPageWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInit?.call();
  }

  @override
  void didUpdateWidget(TestPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only call onUpdate if query parameters changed (not the widget key)
    if (oldWidget.id != widget.id || oldWidget.category != widget.category) {
      widget.onUpdate?.call();
    }
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Page - ID: ${widget.id}')),
      body: Column(
        children: [
          Text('ID: ${widget.id}'),
          if (widget.category != null) Text('Category: ${widget.category}'),
        ],
      ),
    );
  }
}

/// Router delegate for testing navigation equality
class TestRouterDelegate extends BaseRouterDelegate {
  int initCount = 0;
  int updateCount = 0;
  int disposeCount = 0;

  @override
  List<NavigationData> navigationDataRoutes = [];

  TestRouterDelegate({required this.navigationDataRoutes});

  void resetCounters() {
    initCount = 0;
    updateCount = 0;
    disposeCount = 0;
  }

  Widget buildTestPage(BuildContext context, DefaultRoute routeData,
      Map<String, dynamic> globalData) {
    return TestPageWidget(
      key: ValueKey('test-${routeData.queryParameters['id']}'),
      id: routeData.queryParameters['id'] ?? 'unknown',
      category: routeData.queryParameters['category'],
      onInit: () => initCount++,
      onUpdate: () => updateCount++,
      onDispose: () => disposeCount++,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container if no routes to avoid Navigator.pages empty error
    if (routes.isEmpty) {
      return Container();
    }

    return Navigator(
      key: navigatorKey,
      pages: NavigationBuilder.build(
        context: context,
        routeDataList: routes,
        routes: navigationDataRoutes,
      ),
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        pop(result);
        return true;
      },
    );
  }
}

void main() {
  // Widget tests demonstrate the issue but require complex setup
  // The unit tests below (DefaultRoute Equality and Cache Keys) document the issue clearly
  group('Navigation Equality - Query Parameter Changes (Widget Tests)', () {
    late TestRouterDelegate routerDelegate;

    setUp(() {
      routerDelegate = TestRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'test_page',
            url: '/test',
            builder: (context, routeData, globalData) =>
                routerDelegate.buildTestPage(context, routeData, globalData),
          ),
        ],
      );
    });

    testWidgets('Query param change updates same page instance (no recreation)',
        (WidgetTester tester) async {
      // Navigate to test page with initial query params FIRST
      await routerDelegate
          .push('test_page', queryParameters: {'id': '1', 'category': 'books'});

      // Build the router with initial route
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pump();

      expect(routerDelegate.initCount, 1,
          reason: 'Page should be initialized once');
      expect(routerDelegate.updateCount, 0, reason: 'No updates yet');
      expect(routerDelegate.disposeCount, 0,
          reason: 'Page should not be disposed');

      // Reset counters to track next navigation
      routerDelegate.resetCounters();

      // Navigate to same page with different query params
      await routerDelegate.push('test_page',
          queryParameters: {'id': '1', 'category': 'movies'});
      await tester.pump();

      // FIXED BEHAVIOR: Page should update, not recreate
      expect(routerDelegate.initCount, 0,
          reason: 'Page should NOT be recreated');
      expect(routerDelegate.updateCount, 1,
          reason: 'didUpdateWidget should be called');
      expect(routerDelegate.disposeCount, 0,
          reason: 'Page should NOT be disposed');

      // Verify the UI updated with new query params
      expect(find.text('Category: movies'), findsOneWidget);
      expect(find.text('Category: books'), findsNothing);
    });

    testWidgets('Different ID query param should update same instance',
        (WidgetTester tester) async {
      // This test demonstrates the EXPECTED behavior
      // Currently FAILS because query param changes recreate the page

      await routerDelegate.push('test_page', queryParameters: {'id': '1'});
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pump();

      expect(routerDelegate.initCount, 1);
      routerDelegate.resetCounters();

      await routerDelegate.push('test_page', queryParameters: {'id': '2'});
      await tester.pump();

      // EXPECTED: Should update, not recreate (but currently fails)
      // Uncomment these when the fix is implemented:
      expect(routerDelegate.initCount, 0,
          reason: 'Should not recreate page for different query param');
      expect(routerDelegate.updateCount, 1,
          reason: 'Should call didUpdateWidget');
      expect(routerDelegate.disposeCount, 0);

      expect(find.text('ID: 2'), findsOneWidget);
    });

    testWidgets('Adding query parameter should update same instance',
        (WidgetTester tester) async {
      // Navigate with just ID
      await routerDelegate.push('test_page', queryParameters: {'id': '1'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pump();

      expect(routerDelegate.initCount, 1);
      routerDelegate.resetCounters();

      // Add category parameter
      await routerDelegate.push('test_page',
          queryParameters: {'id': '1', 'category': 'sports'});
      await tester.pump();

      expect(routerDelegate.initCount, 0,
          reason: 'Should not recreate when adding query param');
      expect(routerDelegate.updateCount, 1);
      expect(routerDelegate.disposeCount, 0);

      expect(find.text('Category: sports'), findsOneWidget);
    });

    testWidgets('Removing query parameter should update same instance',
        (WidgetTester tester) async {
      // Navigate with multiple params
      await routerDelegate
          .push('test_page', queryParameters: {'id': '1', 'category': 'tech'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pump();

      expect(routerDelegate.initCount, 1);
      expect(find.text('Category: tech'), findsOneWidget);
      routerDelegate.resetCounters();

      // Remove category parameter
      await routerDelegate.push('test_page', queryParameters: {'id': '1'});
      await tester.pump();

      expect(routerDelegate.initCount, 0,
          reason: 'Should not recreate when removing query param');
      expect(routerDelegate.updateCount, 1);
      expect(routerDelegate.disposeCount, 0);

      expect(find.text('Category: tech'), findsNothing);
    });
  });

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

  group('Navigation Equality - Deeplink Scenarios', () {
    late TestRouterDelegate routerDelegate;

    setUp(() {
      routerDelegate = TestRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'product',
            url: '/product',
            builder: (context, routeData, globalData) =>
                routerDelegate.buildTestPage(context, routeData, globalData),
          ),
        ],
      );
    });

    testWidgets('Deeplink with changed query params should update page',
        (WidgetTester tester) async {
      // Simulate deeplink navigation: /product?id=123
      final route1 = DefaultRoute(
        label: 'product',
        path: '/product',
        queryParameters: {'id': '123'},
      );
      await routerDelegate.setNewRoutePath(route1);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pump();

      expect(routerDelegate.initCount, 1,
          reason: 'Initial deeplink should initialize page');
      expect(find.text('ID: 123'), findsOneWidget);

      routerDelegate.resetCounters();

      // Simulate second deeplink with different query param: /product?id=456
      final route2 = DefaultRoute(
        label: 'product',
        path: '/product',
        queryParameters: {'id': '456'},
      );
      await routerDelegate.setNewRoutePath(route2);
      await tester.pump();

      expect(routerDelegate.initCount, 0,
          reason:
              'Second deeplink with different query params should NOT recreate page');
      expect(routerDelegate.updateCount, 1,
          reason: 'didUpdateWidget should be called for query param change');
      expect(routerDelegate.disposeCount, 0,
          reason: 'Page should not be disposed');

      expect(find.text('ID: 456'), findsOneWidget);
    });

    testWidgets(
        'Multiple deeplinks with query param changes should all update same instance',
        (WidgetTester tester) async {
      // First deeplink
      await routerDelegate.setNewRoutePath(DefaultRoute(
        label: 'product',
        path: '/product',
        queryParameters: {'id': '1', 'category': 'books'},
      ));

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pump();

      expect(routerDelegate.initCount, 1);
      routerDelegate.resetCounters();

      // Second deeplink - change category
      await routerDelegate.setNewRoutePath(DefaultRoute(
        label: 'product',
        path: '/product',
        queryParameters: {'id': '1', 'category': 'movies'},
      ));
      await tester.pump();

      expect(routerDelegate.updateCount, 1);
      expect(routerDelegate.initCount, 0);
      routerDelegate.resetCounters();

      // Third deeplink - change id
      await routerDelegate.setNewRoutePath(DefaultRoute(
        label: 'product',
        path: '/product',
        queryParameters: {'id': '2', 'category': 'movies'},
      ));
      await tester.pump();

      expect(routerDelegate.updateCount, 1);
      expect(routerDelegate.initCount, 0);
      expect(routerDelegate.disposeCount, 0,
          reason: 'Page should never be disposed across query param changes');

      expect(find.text('ID: 2'), findsOneWidget);
    });
  });
}
