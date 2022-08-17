import 'dart:async';

import 'package:flutter/widgets.dart';

import 'navigation_delegate.dart';
import 'navigation_manager.dart';

mixin NavigationListenerMixin {
  late BuildContext _context;
  late StreamSubscription navigationListener;
  bool mounted = true;
  bool initialLoad = true;

  void initNavigationListener(BuildContext context) {
    _context = context;
    navigationListener = NavigationManager
        .instance.routerDelegate.getCurrentRoute
        .listen(_didUpdateRoute);
  }

  void _didUpdateRoute(MainRoute currentRoute) {
    // Do not update if page is being closed.
    if (mounted == false) return;
    // Get the name of the current page.
    // The route is returned via the context of the page
    // the mixin is added to.
    String routeName = ModalRoute.of(_context)?.settings.name ?? '';
    // If the route name changes, the current page is no
    // longer active and paused.
    if (routeName != currentRoute.name) {
      onRoutePause(
          oldRouteName: routeName, newRouteName: currentRoute.name ?? '');
    } else if (routeName == currentRoute.name) {
      // Resume is called even on initial load. Skip call on initial load.
      if (initialLoad == false) {
        // If the route update matches the current route name,
        // the route has been resumed.
        onRouteResume();
      } else {
        initialLoad = false;
      }
    }
  }

  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {}

  void onRouteResume() {}

  void disposeNavigationListener() {
    navigationListener.cancel();
  }
}

mixin NavigationListenerStateMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription navigationListener;
  bool initialLoad = true;

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

  void _didUpdateRoute(MainRoute currentRoute) {
    // Do not update if page is being closed.
    if (mounted == false) return;
    // Get the name of the current page.
    // The route is returned via the context of the page
    // the mixin is added to.
    String routeName = ModalRoute.of(context)?.settings.name ?? '';
    // If the route name changes, the current page is no
    // longer active and paused.
    if (routeName != currentRoute.name) {
      onRoutePause(
          oldRouteName: routeName, newRouteName: currentRoute.name ?? '');
    } else if (routeName == currentRoute.name) {
      // Resume is called even on initial load. Skip call on initial load.
      if (initialLoad == false) {
        // If the route update matches the current route name,
        // the route has been resumed.
        onRouteResume();
      } else {
        initialLoad = false;
      }
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
  bool initialLoad = true;

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

  void _didUpdateRoute(MainRoute currentRoute) {
    // Do not update if page is being closed.
    if (mounted == false) return;
    // Get the name of the current page.
    // The route is returned via the context of the page
    // the mixin is added to.
    String routeName = ModalRoute.of(_context)?.settings.name ?? '';
    // If the route name changes, the current page is no
    // longer active and paused.
    if (routeName != currentRoute.name) {
      onRoutePause(
          oldRouteName: routeName, newRouteName: currentRoute.name ?? '');
    } else if (routeName == currentRoute.name) {
      // Resume is called even on initial load. Skip call on initial load.
      if (initialLoad == false) {
        // If the route update matches the current route name,
        // the route has been resumed.
        onRouteResume();
      } else {
        initialLoad = false;
      }
    }
  }

  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {}

  void onRouteResume() {}
}
