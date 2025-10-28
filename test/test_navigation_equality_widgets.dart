// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

/// Widget tests focused on lifecycle behavior when only query parameters change
/// for the same route path. These tests verify the EXPECTED behavior where
/// query parameter changes should UPDATE the same widget instance, not recreate it.
///
/// These tests FAIL with the current buggy implementation and will PASS once fixed.
///
/// Run:
/// flutter test test/test_navigation_equality_widgets.dart

// Test widget that tracks lifecycle events
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

/// Minimal router delegate using NavigationUtils to build Navigator.pages
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
    if (routes.isEmpty) {
      return const SizedBox();
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
  group('Navigation Equality - Widget lifecycle with query parameter changes',
      () {
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

    testWidgets('Changing only query param should UPDATE page, not recreate it',
        (WidgetTester tester) async {
      // Navigate to initial page state BEFORE building the app
      routerDelegate
          .push('test_page', queryParameters: {'id': '1', 'category': 'books'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pumpAndSettle();

      expect(routerDelegate.initCount, 1,
          reason: 'First navigation should initialize once');
      expect(routerDelegate.updateCount, 0);
      expect(routerDelegate.disposeCount, 0);
      expect(find.text('Category: books'), findsOneWidget);

      // Change only query parameters (same path)
      routerDelegate.resetCounters();
      routerDelegate.push('test_page',
          queryParameters: {'id': '1', 'category': 'movies'});
      await tester.pumpAndSettle();

      // EXPECTED behavior: page should be updated, not recreated
      expect(routerDelegate.initCount, 0,
          reason: 'Page should NOT be recreated when only query params change');
      expect(routerDelegate.updateCount, 1,
          reason: 'didUpdateWidget SHOULD be called for query param changes');
      expect(routerDelegate.disposeCount, 0,
          reason: 'Page should NOT be disposed when only query params change');

      // UI reflects new parameter
      expect(find.text('Category: movies'), findsOneWidget);
      expect(find.text('Category: books'), findsNothing);
    });

    testWidgets('Changing id param should UPDATE the same page instance',
        (WidgetTester tester) async {
      routerDelegate.push('test_page', queryParameters: {'id': '1'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pumpAndSettle();

      expect(routerDelegate.initCount, 1);
      expect(find.text('ID: 1'), findsOneWidget);

      routerDelegate.resetCounters();
      routerDelegate.push('test_page', queryParameters: {'id': '2'});
      await tester.pumpAndSettle();

      // EXPECTED behavior: page should be updated, not recreated
      expect(routerDelegate.initCount, 0,
          reason: 'Should NOT recreate page for different query param');
      expect(routerDelegate.updateCount, 1,
          reason: 'Should call didUpdateWidget for query param change');
      expect(routerDelegate.disposeCount, 0,
          reason: 'Should NOT dispose page when only query params change');
      expect(find.text('ID: 2'), findsOneWidget);
      expect(find.text('ID: 1'), findsNothing);
    });

    testWidgets('Pushing identical params should not recreate the page',
        (WidgetTester tester) async {
      routerDelegate
          .push('test_page', queryParameters: {'id': '42', 'category': 'tech'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pumpAndSettle();

      expect(routerDelegate.initCount, 1);
      expect(routerDelegate.updateCount, 0);
      expect(routerDelegate.disposeCount, 0);

      routerDelegate.resetCounters();
      routerDelegate
          .push('test_page', queryParameters: {'id': '42', 'category': 'tech'});
      await tester.pumpAndSettle();

      // EXPECTED behavior: duplicate push with identical params should not rebuild
      expect(routerDelegate.initCount, 0,
          reason: 'Should NOT recreate page for identical params');
      expect(routerDelegate.updateCount, 0,
          reason: 'No update needed for identical params');
      expect(routerDelegate.disposeCount, 0,
          reason: 'Should NOT dispose page for identical params');
      expect(find.text('ID: 42'), findsOneWidget);
      expect(find.text('Category: tech'), findsOneWidget);
    });

    testWidgets(
        'Multiple query param changes should all update the same instance',
        (WidgetTester tester) async {
      routerDelegate.push('test_page', queryParameters: {'id': '1'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: routerDelegate,
          routeInformationParser: DefaultRouteInformationParser(),
        ),
      );
      await tester.pumpAndSettle();

      expect(routerDelegate.initCount, 1);
      routerDelegate.resetCounters();

      // First query param change
      routerDelegate.push('test_page', queryParameters: {'id': '2'});
      await tester.pumpAndSettle();

      expect(routerDelegate.initCount, 0,
          reason: 'First query change should not recreate page');
      expect(routerDelegate.updateCount, 1);
      expect(routerDelegate.disposeCount, 0);
      expect(find.text('ID: 2'), findsOneWidget);

      routerDelegate.resetCounters();

      // Second query param change
      routerDelegate.push('test_page',
          queryParameters: {'id': '3', 'category': 'sports'});
      await tester.pumpAndSettle();

      expect(routerDelegate.initCount, 0,
          reason: 'Second query change should not recreate page');
      expect(routerDelegate.updateCount, 1);
      expect(routerDelegate.disposeCount, 0,
          reason: 'Page should never be disposed across query param changes');
      expect(find.text('ID: 3'), findsOneWidget);
      expect(find.text('Category: sports'), findsOneWidget);
    });
  });
}
