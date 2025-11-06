import 'dart:async';

import 'package:flutter/widgets.dart';

import 'navigation_delegate.dart';
import 'navigation_manager.dart';

/// A mixin that provides navigation state listening capabilities.
///
/// This mixin allows classes to listen to navigation changes and receive
/// callbacks when routes are paused or resumed.
mixin NavigationListenerMixin {
  late BuildContext _context;
  late StreamSubscription navigationListener;
  String? _routeName;
  bool mounted = true;
  bool paused = false;

  /// Initializes the navigation listener.
  ///
  /// [context] - The build context to use for route detection.
  /// [routeName] - Optional route name to track. If not provided, the route
  /// name is extracted from the context.
  void initNavigationListener(BuildContext context, {String? routeName}) {
    _context = context;
    _routeName = routeName;
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
    late String routeName;
    try {
      routeName = _routeName ?? ModalRoute.of(_context)?.settings.name ?? '';
    } catch (e) {
      return;
    }
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

  /// Called when the route becomes active (resumed).
  ///
  /// Override this method to handle route resume events.
  void onRouteResume() {}

  /// Disposes the navigation listener and cancels the subscription.
  ///
  /// This method should be called when navigation listening is no longer needed.
  void disposeNavigationListener() {
    navigationListener.cancel();
  }
}

/// A mixin that provides navigation state listening capabilities to [State] classes.
///
/// This mixin automatically initializes navigation listening in [initState]
/// and disposes it in [dispose], making it convenient for use in StatefulWidgets.
mixin NavigationListenerStateMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription navigationListener;
  String? _routeName;
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

    late String routeName;
    try {
      routeName = _routeName ?? ModalRoute.of(context)?.settings.name ?? '';
    } catch (e) {
      return;
    }
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

  /// Called when the route becomes active (resumed).
  ///
  /// Override this method to handle route resume events.
  void onRouteResume() {}

  /// Sets the route name to track.
  ///
  /// If not set, the route name is extracted from the context.
  void setRouteName(String routeName) {
    _routeName = routeName;
  }
}

/// A mixin that provides navigation state listening capabilities to [ChangeNotifier] classes.
///
/// This mixin allows ChangeNotifier classes to listen to navigation changes.
/// The navigation listener is automatically disposed when the ChangeNotifier is disposed.
mixin NavigationListenerChangeNotifierMixin on ChangeNotifier {
  late BuildContext _context;
  late StreamSubscription navigationListener;
  String? _routeName;
  bool mounted = true;
  bool paused = false;

  /// Initializes the navigation listener.
  ///
  /// [context] - The build context to use for route detection.
  /// [routeName] - Optional route name to track. If not provided, the route
  /// name is extracted from the context.
  void initNavigationListener(BuildContext context, {String? routeName}) {
    _context = context;
    _routeName = routeName;
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

    late String routeName;
    try {
      routeName = _routeName ?? ModalRoute.of(_context)?.settings.name ?? '';
    } catch (e) {
      return;
    }
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

  /// Called when the route becomes active (resumed).
  ///
  /// Override this method to handle route resume events.
  void onRouteResume() {}
}
