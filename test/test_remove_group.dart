import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('removeGroup', () {
    test('Single', () {
      String group = 'my_group';
      DefaultRouterDelegate routerDelegate =
          DefaultRouterDelegate(navigationDataRoutes: []);
      routerDelegate.setRoutes([DefaultRoute(path: '/', group: group)]);

      // Removing should not remove the last route. Check last route still exists.
      routerDelegate.removeGroup(group);
      expect(routerDelegate.routes, [DefaultRoute(path: '/', group: group)]);

      // When `all` is true, remove all routes, including the last one.
      routerDelegate.removeGroup(group, all: true);
      expect(routerDelegate.routes.isEmpty, true);

      // Removing empty should not crash.
      routerDelegate.removeGroup(group);
      routerDelegate.removeGroup(group, all: true);
    });
    test('Multiple', () {
      String group = 'my_group';
      DefaultRouterDelegate routerDelegate =
          DefaultRouterDelegate(navigationDataRoutes: []);
      routerDelegate.setRoutes([
        DefaultRoute(path: '/', group: group),
        DefaultRoute(path: '/1', group: group),
        DefaultRoute(path: '/2', group: group),
        DefaultRoute(path: '/3', group: group),
      ]);

      // Removing should not remove the last route. Check last route still exists.
      routerDelegate.removeGroup(group);
      expect(routerDelegate.routes, [DefaultRoute(path: '/', group: group)]);

      // When `all` is true, remove all routes, including the last one.
      routerDelegate.removeGroup(group, all: true);
      expect(routerDelegate.routes.isEmpty, true);
    });
    test('Multiple with Non Group', () {
      String group = 'my_group';
      DefaultRouterDelegate routerDelegate =
          DefaultRouterDelegate(navigationDataRoutes: []);
      routerDelegate.setRoutes([
        DefaultRoute(path: '/', group: group),
        DefaultRoute(path: '/1', group: group),
        DefaultRoute(path: '/2', group: group),
        DefaultRoute(path: '/3', group: group),
        DefaultRoute(path: '/4'),
        DefaultRoute(path: '/5'),
        DefaultRoute(path: '/6'),
      ]);
      routerDelegate.removeGroup(group);
      expect(routerDelegate.routes, [
        DefaultRoute(path: '/4'),
        DefaultRoute(path: '/5'),
        DefaultRoute(path: '/6'),
      ]);

      routerDelegate.setRoutes([
        DefaultRoute(path: '/', group: group),
        DefaultRoute(path: '/4'),
        DefaultRoute(path: '/1', group: group),
        DefaultRoute(path: '/5'),
        DefaultRoute(path: '/2', group: group),
        DefaultRoute(path: '/6'),
        DefaultRoute(path: '/3', group: group),
      ]);
      routerDelegate.removeGroup(group);
      expect(routerDelegate.routes, [
        DefaultRoute(path: '/4'),
        DefaultRoute(path: '/5'),
        DefaultRoute(path: '/6'),
      ]);
    });
  });
}
