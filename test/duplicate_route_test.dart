import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('Navigation with Duplicate Routes Tests', () {
    testWidgets('Duplicate routes - simple navigation scenario',
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

      // Check that our routes can have duplicates
      final routes = routerDelegate.routes;

      // Extract all paths
      final paths = routes.map((route) => route.path).toList();

      // Count occurrences of each path
      final pathCounts = <String, int>{};
      for (final path in paths) {
        pathCounts[path] = (pathCounts[path] ?? 0) + 1;
      }

      // Now we expect duplicate paths
      expect(pathCounts['/notifications'], equals(2),
          reason: 'Path "/notifications" should appear 2 times in route stack');
    });

    test(
        'Duplicate routes - route cache key generation',
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

      // Now we expect the notifications route to appear twice
      final expectedPaths = [
        '/home',
        '/community',
        '/notifications',
        '/therapy',
        '/notifications' // The duplicate route
      ];

      // Check routes match expected
      expect(routes.length, equals(expectedPaths.length),
          reason: 'Number of routes should match expected count');

      for (int i = 0; i < routes.length; i++) {
        expect(routes[i].path, equals(expectedPaths[i]),
            reason:
                'Route at position $i should have path ${expectedPaths[i]}');
      }

      // Check for unique cache keys for duplicate routes
      final notificationRoutes = routes
          .where((route) => route.path == '/notifications')
          .toList();
      expect(notificationRoutes.length, equals(2),
          reason: 'There should be 2 notification routes');

      if (notificationRoutes.length > 1) {
        expect(notificationRoutes[0].cacheKey, isNot(equals(notificationRoutes[1].cacheKey)),
            reason: 'Duplicate routes should have different cache keys');
      }
    });

    testWidgets('Duplicate routes - complex navigation flow with duplicates',
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

      // Verify the routes - should now have TWO notifications routes
      final routes = routerDelegate.routes;
      final labels = routes.map((r) => r.label).toList();

      // Should contain duplicate entries
      expect(routes.where((r) => r.path == '/notifications').length, equals(2),
          reason: 'Should have two notifications routes');

      // Final routes should be in correct order with duplicates
      expect(labels, containsAllInOrder(['feed', 'notifications', 'therapy', 'notifications']),
          reason: 'Routes should be in the correct order with duplicates allowed');
    });
  });
}
