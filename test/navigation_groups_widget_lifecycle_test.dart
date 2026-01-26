import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

/// Tests for grouped routes widget lifecycle behavior
///
/// This test file verifies the specific scenario documented in the README:
/// - Switching between grouped routes (e.g., /login -> /signup in 'auth' group)
/// - Verifying that didUpdateWidget is called (not initState)
/// - Verifying that the widget instance is reused and not recreated
/// - Testing that passing route.path as arguments triggers Flutter's change detection

// Test widget that tracks lifecycle events for grouped routes
class GroupedTestPageWidget extends StatefulWidget {
  final String pageType;
  final VoidCallback? onInit;
  final VoidCallback? onUpdate;
  final VoidCallback? onDispose;

  const GroupedTestPageWidget({
    Key? key,
    required this.pageType,
    this.onInit,
    this.onUpdate,
    this.onDispose,
  }) : super(key: key);

  @override
  State<GroupedTestPageWidget> createState() => _GroupedTestPageWidgetState();
}

class _GroupedTestPageWidgetState extends State<GroupedTestPageWidget> {
  // Internal state to track current page type
  // This will be updated in didUpdateWidget to verify it was called
  late String _currentPageType;

  @override
  void initState() {
    super.initState();
    _currentPageType = widget.pageType;
    widget.onInit?.call();
  }

  @override
  void didUpdateWidget(GroupedTestPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state to match new widget
    _currentPageType = widget.pageType;
    widget.onUpdate?.call();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Page Type: $_currentPageType'),
          Text('Widget Type: ${widget.pageType}'),
        ],
      ),
    );
  }
}

void main() {
  group('Grouped Routes - Widget Lifecycle Tests', () {
    testWidgets(
        'Switching between grouped routes should call didUpdateWidget',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;
      int disposeCount = 0;

      // Create router delegate with grouped auth routes
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'login',
                onInit: () => initCount++,
                onUpdate: () => updateCount++,
                onDispose: () => disposeCount++,
              );
            },
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'signup',
                onInit: () => initCount++,
                onUpdate: () => updateCount++,
                onDispose: () => disposeCount++,
              );
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Navigate to login
      routerDelegate.push('login');
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Page Type: login'), findsOneWidget);
      expect(find.text('Widget Type: login'), findsOneWidget);
      print('After login - initCount: $initCount, updateCount: $updateCount, disposeCount: $disposeCount');

      // Reset counters to track only the navigation change
      final initCountBeforeSwitch = initCount;
      final updateCountBeforeSwitch = updateCount;
      final disposeCountBeforeSwitch = disposeCount;

      // Navigate to signup (same group)
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      print('After signup - initCount: $initCount, updateCount: $updateCount, disposeCount: $disposeCount');

      // CRITICAL ASSERTION: didUpdateWidget should be called, NOT initState
      expect(initCount, initCountBeforeSwitch,
          reason:
              'initState should NOT be called when switching grouped routes');
      expect(updateCount, greaterThan(updateCountBeforeSwitch),
          reason:
              'didUpdateWidget SHOULD be called when switching grouped routes');
      expect(disposeCount, disposeCountBeforeSwitch,
          reason:
              'dispose should NOT be called when switching grouped routes');

      // Verify UI updated
      expect(find.text('Page Type: signup'), findsOneWidget);
      expect(find.text('Widget Type: signup'), findsOneWidget);
      expect(find.text('Page Type: login'), findsNothing);
    });

    testWidgets('Grouped routes share the same cache key',
        (WidgetTester tester) async {
      // Create router delegate with grouped auth routes
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) {
              return const Text('Login Page');
            },
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) {
              return const Text('Signup Page');
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Navigate to login
      routerDelegate.push('login');
      await tester.pumpAndSettle();

      // Navigate to signup
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      // Both routes should have the same cache key (the group name)
      final routes = routerDelegate.routes;
      final authRoutes = routes.where((r) => r.group == 'auth').toList();

      print('Auth routes cache keys:');
      for (final route in authRoutes) {
        print('  ${route.path} -> cacheKey: ${route.cacheKey}');
      }

      // All auth routes should share the same cache key
      for (final route in authRoutes) {
        expect(route.cacheKey, 'auth',
            reason: 'All grouped routes should share the group name as cache key');
      }
    });

    testWidgets(
        'Multiple switches between grouped routes maintain widget instance',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;
      int disposeCount = 0;

      // Create router delegate with grouped auth routes
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'login',
                onInit: () => initCount++,
                onUpdate: () => updateCount++,
                onDispose: () => disposeCount++,
              );
            },
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'signup',
                onInit: () => initCount++,
                onUpdate: () => updateCount++,
                onDispose: () => disposeCount++,
              );
            },
          ),
          NavigationData(
            label: 'reset',
            url: '/reset',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'reset',
                onInit: () => initCount++,
                onUpdate: () => updateCount++,
                onDispose: () => disposeCount++,
              );
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Navigate through all three auth pages
      routerDelegate.push('login');
      await tester.pumpAndSettle();
      expect(find.text('Page Type: login'), findsOneWidget);
      print('After login - initCount: $initCount, updateCount: $updateCount');

      final initAfterLogin = initCount;

      routerDelegate.push('signup');
      await tester.pumpAndSettle();
      expect(find.text('Page Type: signup'), findsOneWidget);
      print('After signup - initCount: $initCount, updateCount: $updateCount');

      routerDelegate.push('reset');
      await tester.pumpAndSettle();
      expect(find.text('Page Type: reset'), findsOneWidget);
      print('After reset - initCount: $initCount, updateCount: $updateCount');

      routerDelegate.push('login');
      await tester.pumpAndSettle();
      expect(find.text('Page Type: login'), findsOneWidget);
      print('After back to login - initCount: $initCount, updateCount: $updateCount');

      // Only ONE initState call should have happened (for the initial widget)
      expect(initCount, initAfterLogin,
          reason: 'Only one initState call should happen for the grouped widget');

      // Multiple didUpdateWidget calls should have happened
      expect(updateCount, greaterThan(0),
          reason: 'didUpdateWidget should be called for each route switch');

      // No dispose should have happened
      expect(disposeCount, 0,
          reason: 'Widget should not be disposed when switching grouped routes');
    });

    testWidgets(
        'Grouped routes with different groups create separate instances',
        (WidgetTester tester) async {
      int authInitCount = 0;
      int authUpdateCount = 0;
      int settingsInitCount = 0;
      int settingsUpdateCount = 0;

      // Create router delegate with multiple groups
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'login',
                onInit: () => authInitCount++,
                onUpdate: () => authUpdateCount++,
              );
            },
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'signup',
                onInit: () => authInitCount++,
                onUpdate: () => authUpdateCount++,
              );
            },
          ),
          NavigationData(
            label: 'settings',
            url: '/settings',
            group: 'settings',
            builder: (context, route, _) {
              return GroupedTestPageWidget(
                pageType: 'settings',
                onInit: () => settingsInitCount++,
                onUpdate: () => settingsUpdateCount++,
              );
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Navigate within auth group
      routerDelegate.push('login');
      await tester.pumpAndSettle();
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      print('After auth navigation - authInit: $authInitCount, authUpdate: $authUpdateCount');

      // Navigate to different group
      routerDelegate.push('settings');
      await tester.pumpAndSettle();

      print('After settings - settingsInit: $settingsInitCount, authInit: $authInitCount');

      // Settings should be a new instance
      expect(settingsInitCount, 1,
          reason: 'Settings group should create new instance');

      // Auth group should have only one init (reused widget)
      expect(authInitCount, 1,
          reason: 'Auth group should reuse widget instance');

      // Auth should have updates from switching login->signup
      expect(authUpdateCount, greaterThan(0),
          reason: 'Auth switches should trigger didUpdateWidget');
    });
  });
}
