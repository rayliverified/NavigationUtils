import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('Navigation with Duplicate Routes Tests', () {
    testWidgets('Should handle navigation with duplicate routes',
        (WidgetTester tester) async {
      DefaultRouterDelegate routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'home',
            url: '/home',
            builder: (context, route, child) => const Text('Home Page'),
          ),
          NavigationData(
            label: 'feed',
            url: '/community',
            group: 'home',
            builder: (context, route, child) => const Text('Feed Page'),
          ),
          NavigationData(
            label: 'therapy',
            url: '/therapy',
            group: 'home',
            builder: (context, route, child) => const Text('Therapy Page'),
          ),
          NavigationData(
            label: 'notifications',
            url: '/notifications',
            builder: (context, route, child) =>
                const Text('Notifications Page'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Initial route
      routerDelegate.setRoutes([DefaultRoute(path: '/home', label: 'home')]);
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);

      // Push first community page
      routerDelegate.push('feed');
      await tester.pumpAndSettle();
      expect(find.text('Feed Page'), findsOneWidget);

      // Push notifications page
      routerDelegate.push('notifications');
      await tester.pumpAndSettle();
      expect(find.text('Notifications Page'), findsOneWidget);

      // Push therapy page
      routerDelegate.push('therapy');
      await tester.pumpAndSettle();
      expect(find.text('Therapy Page'), findsOneWidget);

      // Push notifications page again (duplicate)
      routerDelegate.push('notifications');
      await tester.pumpAndSettle();
      expect(find.text('Notifications Page'), findsOneWidget);

      // Check that our routes don't have duplicates
      final routes = routerDelegate.routes;

      // Extract all paths
      final paths = routes.map((route) => route.path).toList();

      // Count occurrences of each path
      final pathCounts = <String, int>{};
      for (final path in paths) {
        pathCounts[path] = (pathCounts[path] ?? 0) + 1;
      }

      // Verify no path occurs more than once
      for (final entry in pathCounts.entries) {
        expect(entry.value, equals(1),
            reason:
                'Path "${entry.key}" appears ${entry.value} times in route stack');
      }
    });

    test(
        'DefaultRouterDelegate.push should replace existing routes with same path',
        () {
      DefaultRouterDelegate routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'home',
            url: '/home',
            builder: (context, route, child) => const SizedBox(),
          ),
          NavigationData(
            label: 'feed',
            url: '/community',
            group: 'home',
            builder: (context, route, child) => const SizedBox(),
          ),
          NavigationData(
            label: 'therapy',
            url: '/therapy',
            group: 'home',
            builder: (context, route, child) => const SizedBox(),
          ),
          NavigationData(
            label: 'notifications',
            url: '/notifications',
            builder: (context, route, child) => const SizedBox(),
          ),
        ],
      );

      // Setup initial routes
      routerDelegate.setRoutes([
        DefaultRoute(path: '/home', label: 'home'),
        DefaultRoute(path: '/community', label: 'feed', group: 'home'),
      ]);

      // Add notifications route
      routerDelegate.push('notifications');

      // Add therapy route
      routerDelegate.push('therapy');

      // Push notifications again - this should replace the existing one
      routerDelegate.push('notifications');

      // Verify routes
      final routes = routerDelegate.routes;

      // Expected routes in order
      final expectedPaths = [
        '/home',
        '/community',
        '/therapy',
        '/notifications'
      ];

      // Check routes match expected
      expect(routes.length, equals(expectedPaths.length),
          reason: 'Number of routes should match expected count');

      for (int i = 0; i < routes.length; i++) {
        expect(routes[i].path, equals(expectedPaths[i]),
            reason:
                'Route at position $i should have path ${expectedPaths[i]}');
      }

      // Check for duplicates
      final routePaths = routes.map((r) => r.path).toList();
      final uniquePaths = routePaths.toSet();

      // Number of unique paths should match total paths (no duplicates)
      expect(uniquePaths.length, equals(routePaths.length),
          reason: 'There should be no duplicate routes');
    });

    testWidgets('Full navigation flow should not have duplicate routes',
        (WidgetTester tester) async {
      DefaultRouterDelegate routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'home',
            url: '/home',
            builder: (context, route, child) => const Text('Home Page'),
          ),
          NavigationData(
            label: 'feed',
            url: '/community',
            group: 'home',
            builder: (context, route, child) => const Text('Feed Page'),
          ),
          NavigationData(
            label: 'therapy',
            url: '/therapy',
            group: 'home',
            builder: (context, route, child) => const Text('Therapy Page'),
          ),
          NavigationData(
            label: 'notifications',
            url: '/notifications',
            builder: (context, route, child) =>
                const Text('Notifications Page'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Start with Home (Feed)
      routerDelegate.setRoutes(
          [DefaultRoute(path: '/community', label: 'feed', group: 'home')]);
      await tester.pumpAndSettle();

      // Go to Notifications
      routerDelegate.push('notifications');
      await tester.pumpAndSettle();

      // Go back to Home (simulating clicking a link)
      routerDelegate.push('therapy');
      await tester.pumpAndSettle();

      // Go to Notifications again
      routerDelegate.push('notifications');
      await tester.pumpAndSettle();

      // Verify the routes - should have therapy and notifications, no duplicates
      final routes = routerDelegate.routes;
      final labels = routes.map((r) => r.label).toList();

      // Should not contain duplicate entries
      expect(routes.where((r) => r.path == '/notifications').length, equals(1),
          reason: 'Should have only one notifications route');

      // Final routes should be in correct order without duplicates
      expect(labels, containsAllInOrder(['feed', 'therapy', 'notifications']),
          reason: 'Routes should be in the correct order without duplicates');
    });
  });
}
