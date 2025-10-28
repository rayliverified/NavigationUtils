import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('Navigation Group Behavior Tests', () {
    testWidgets('Group navigation - contiguous groups build optimization',
        (WidgetTester tester) async {
      // Track which routes were actually built
      final List<String> builtRoutes = [];

      // Create router delegate with grouped routes
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'homePage1',
            url: '/home/1',
            group: 'home',
            builder: (context, route, _) {
              builtRoutes.add('homePage1');
              return Text('HomePage 1 - ${route.path}');
            },
          ),
          NavigationData(
            label: 'homePage2',
            url: '/home/2',
            group: 'home',
            builder: (context, route, _) {
              builtRoutes.add('homePage2');
              return Text('HomePage 2 - ${route.path}');
            },
          ),
          NavigationData(
            label: 'homePage3',
            url: '/home/3',
            group: 'home',
            builder: (context, route, _) {
              builtRoutes.add('homePage3');
              return Text('HomePage 3 - ${route.path}');
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Add all three routes in sequence
      routerDelegate.push('homePage1');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage2');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage3');
      await tester.pumpAndSettle();

      // Verify only the last item is visible
      expect(find.text('HomePage 3 - /home/3'), findsOneWidget);
      
      // All routes should have same cache key
      final routes = routerDelegate.routes;
      for (final route in routes) {
        if (route.group == 'home') {
          expect(route.cacheKey, 'home');
        }
      }
    });

    testWidgets('Group navigation - non-contiguous groups with same key',
        (WidgetTester tester) async {
      // Create router delegate with grouped and non-grouped routes
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'homePage1',
            url: '/home/1',
            group: 'home',
            builder: (context, route, _) {
              return Text('HomePage 1 - ${route.path}');
            },
          ),
          NavigationData(
            label: 'profilePage',
            url: '/profile',
            builder: (context, route, _) {
              return Text('ProfilePage - ${route.path}');
            },
          ),
          NavigationData(
            label: 'homePage2',
            url: '/home/2',
            group: 'home',
            builder: (context, route, _) {
              return Text('HomePage 2 - ${route.path}');
            },
          ),
          NavigationData(
            label: 'homePage3',
            url: '/home/3',
            group: 'home',
            builder: (context, route, _) {
              return Text('HomePage 3 - ${route.path}');
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Create navigation sequence with non-contiguous groups
      routerDelegate.push('homePage1');
      await tester.pumpAndSettle();
      routerDelegate.push('profilePage');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage2');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage3');
      await tester.pumpAndSettle();

      // Verify route structure and cache keys
      final routes = routerDelegate.routes;
      
      // Check for correct cache keys
      for (final route in routes) {
        if (route.group == 'home') {
          expect(route.cacheKey, 'home');
        } else if (route.label == 'profilePage') {
          expect(route.cacheKey, isNot('home'));
        }
      }
    });

    testWidgets('Group navigation - multiple distinct groups separation',
        (WidgetTester tester) async {
      // Create router delegate with multiple groups
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'homePage1',
            url: '/home/1',
            group: 'home',
            builder: (context, route, _) {
              return Text('HomePage 1');
            },
          ),
          NavigationData(
            label: 'homePage2',
            url: '/home/2',
            group: 'home',
            builder: (context, route, _) {
              return Text('HomePage 2');
            },
          ),
          NavigationData(
            label: 'settingsPage1',
            url: '/settings/1',
            group: 'settings',
            builder: (context, route, _) {
              return Text('SettingsPage 1');
            },
          ),
          NavigationData(
            label: 'settingsPage2',
            url: '/settings/2',
            group: 'settings',
            builder: (context, route, _) {
              return Text('SettingsPage 2');
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Add routes in multiple groups
      routerDelegate.push('homePage1');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage2');
      await tester.pumpAndSettle();
      routerDelegate.push('settingsPage1');
      await tester.pumpAndSettle();
      routerDelegate.push('settingsPage2');
      await tester.pumpAndSettle();

      // Verify each group has its own cache key
      final routes = routerDelegate.routes;
      final homeRoutes = routes.where((r) => r.group == 'home').toList();
      final settingsRoutes = routes.where((r) => r.group == 'settings').toList();
      
      for (final route in homeRoutes) {
        expect(route.cacheKey, 'home');
      }
      
      for (final route in settingsRoutes) {
        expect(route.cacheKey, 'settings');
      }
    });

    testWidgets('Group navigation - popping from contiguous sequence',
        (WidgetTester tester) async {
      // Track which routes were actually built
      final List<String> builtRoutes = [];

      // Create router delegate with grouped routes
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'homePage1',
            url: '/home/1',
            group: 'home',
            builder: (context, route, _) {
              builtRoutes.add('homePage1');
              return Text('HomePage 1');
            },
          ),
          NavigationData(
            label: 'homePage2',
            url: '/home/2',
            group: 'home',
            builder: (context, route, _) {
              builtRoutes.add('homePage2');
              return Text('HomePage 2');
            },
          ),
          NavigationData(
            label: 'homePage3',
            url: '/home/3',
            group: 'home',
            builder: (context, route, _) {
              builtRoutes.add('homePage3');
              return Text('HomePage 3');
            },
          ),
        ],
      );

      // Set up testing widget
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Add group routes
      routerDelegate.push('homePage1');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage2');
      await tester.pumpAndSettle();
      routerDelegate.push('homePage3');
      await tester.pumpAndSettle();
      
      // Clear built routes list
      builtRoutes.clear();
      
      // Pop and verify correct rebuilding
      routerDelegate.pop();
      await tester.pumpAndSettle();
      expect(find.text('HomePage 2'), findsOneWidget);
      
      routerDelegate.pop();
      await tester.pumpAndSettle();
      expect(find.text('HomePage 1'), findsOneWidget);
    });
  });
}
