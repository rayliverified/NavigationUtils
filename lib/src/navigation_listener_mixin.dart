import 'dart:async';

import 'package:flutter/widgets.dart';

import 'navigation_delegate.dart';
import 'navigation_manager.dart';

mixin NavigationListenerMixin {
  late BuildContext _context;
  late StreamSubscription navigationListener;
  bool mounted = true;
  bool paused = false;

  void initNavigationListener(BuildContext context) {
    _context = context;
    navigationListener = NavigationManager
        .instance.routerDelegate.getCurrentRoute
        .listen(_didUpdateRoute);
  }

  void _didUpdateRoute(DefaultRoute currentRoute) {
    // Do not update if page is being closed.
    if (mounted == false) return;
    if (_context.mounted == false) return;
    // Get the name of the current page.
    // The route is returned via the context of the page
    // the mixin is added to.
    String routeName = ModalRoute.of(_context)?.settings.name ?? '';
    // If the route name changes, the current page is no
    // longer active and paused.
    if (routeName != currentRoute.name) {
      // Do nothing if already paused since every navigation event
      // triggers this function.
      if (paused) return;
      paused = true;
      onRoutePause(
          oldRouteName: routeName, newRouteName: currentRoute.name ?? '');
    } else if (routeName == currentRoute.name) {
      paused = false;
      // Unlike other NavigationListeners, no initial call tracking
      // is required as this NavigationListener does not make duplicate calls on start.
      onRouteResume();
    }
  }

  /// Route paused callback.
  ///
  /// [oldRouteName] - paused route.
  /// [newRouteName] - resumed route.
  ///
  /// Example: Page 1 -> Page 2
  /// When Page 1 is paused, Page 1 receives a callback
  /// with `oldRouteName` = `Page 1` and
  /// `newRouteName` = `Page 2`.
  ///
  /// Example 2: Page 2 -> Page 1
  /// When Page 2 is popped and the user navigates
  /// back to Page 1, Page 2 receives a callback with
  /// `oldRouteName` = `Page 2` and
  /// `newRouteName` = `Page 1`.
  ///
  /// The `onRoutePause` callback is useful for pausing
  /// a page's updates and background operations that
  /// are no longer needed when in the background.
  /// Because Flutter keeps Page widgets mounted
  /// and preserves their state, "heavy" page processes
  /// should be paused in the background.
  ///
  /// Note: `onRoutePause` is always called before a
  /// page is disposed. In the rare instance when it is
  /// important to differentiate between a pause and
  /// close event, use the following code to check.
  /// ```dart
  ///     String routeName = ModalRoute.of(context)?.settings.name ?? '';
  ///     bool closed = NavigationManager.instance.routerDelegate.routes
  ///             .contains(DefaultRoute(path: routeName)) ==
  ///         false;
  /// ```
  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {}

  void onRouteResume() {}

  void disposeNavigationListener() {
    navigationListener.cancel();
  }
}

mixin NavigationListenerStateMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription navigationListener;
  bool paused = false;

  @override
  void initState() {
    super.initState();
    navigationListener = NavigationManager
        .instance.routerDelegate.getCurrentRoute
        .listen(_didUpdateRoute);
  }

  @override
  void dispose() {
    navigationListener.cancel();
    super.dispose();
  }

  void _didUpdateRoute(DefaultRoute currentRoute) {
    if (mounted == false) return;
    if (context.mounted == false) return;

    String routeName = ModalRoute.of(context)?.settings.name ?? '';
    if (routeName != currentRoute.name) {
      if (paused) return;
      paused = true;
      onRoutePause(
          oldRouteName: routeName, newRouteName: currentRoute.name ?? '');
    } else if (routeName == currentRoute.name) {
      paused = false;
      onRouteResume();
    }
  }

  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {}

  void onRouteResume() {}
}

mixin NavigationListenerChangeNotifierMixin on ChangeNotifier {
  late BuildContext _context;
  late StreamSubscription navigationListener;
  bool mounted = true;
  bool paused = false;

  void initNavigationListener(BuildContext context) {
    _context = context;
    navigationListener = NavigationManager
        .instance.routerDelegate.getCurrentRoute
        .listen(_didUpdateRoute);
  }

  @override
  void dispose() {
    mounted = false;
    navigationListener.cancel();
    super.dispose();
  }

  void _didUpdateRoute(DefaultRoute currentRoute) {
    if (mounted == false) return;
    if (_context.mounted == false) return;

    String routeName = ModalRoute.of(_context)?.settings.name ?? '';
    if (routeName != currentRoute.name) {
      if (paused) return;
      paused = true;
      onRoutePause(
          oldRouteName: routeName, newRouteName: currentRoute.name ?? '');
    } else if (routeName == currentRoute.name) {
      paused = false;
      onRouteResume();
    }
  }

  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {}

  void onRouteResume() {}
}
