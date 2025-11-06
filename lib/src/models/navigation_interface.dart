import 'package:flutter/widgets.dart';

import '../navigation_delegate.dart';

/// Abstract interface for navigation operations.
///
/// This interface defines the contract for navigation operations including
/// pushing, popping, replacing, and managing routes in the navigation stack.
/// Implementations of this interface provide the actual navigation functionality.
abstract class NavigationInterface {
  /// Pushes a new route onto the navigation stack.
  Future<dynamic> push(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true});

  /// Pushes a new route onto the navigation stack using the provided [route].
  Future<dynamic> pushRoute(DefaultRoute route, {bool apply = true});

  /// Pops the current route from the navigation stack.
  void pop([dynamic result, bool apply = true, bool all = false]);

  /// Pops routes from the navigation stack until a specific route is reached.
  void popUntil(String name,
      {bool apply = true, bool all = false, bool inclusive = false});

  /// Pops routes from the navigation stack until a specific route, determined by [popUntilRouteFunction], is reached.
  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true, bool all = false, bool inclusive = false});

  /// Pushes a new route onto the navigation stack and removes all routes until a specific route is reached.
  Future<dynamic> pushAndRemoveUntil(String name, String routeUntilName,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true,
      bool inclusive = false});

  /// Pushes a new route onto the navigation stack and removes all routes until a specific route, determined by [popUntilRouteFunction], is reached.
  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true, bool inclusive = false});

  /// Removes a route from the navigation stack based on the route's [name].
  void remove(String name, {bool apply = true});

  /// Removes a specific [route] from the navigation stack.
  void removeRoute(DefaultRoute route, {bool apply = true});

  /// Pushes a new route onto the navigation stack and replaces the current route with it.
  Future<dynamic> pushReplacement(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      dynamic result,
      bool apply = true});

  /// Pushes a new route onto the navigation stack and replaces the current route with it, using the provided [route].
  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result, bool apply = true]);

  /// Removes all routes below a specific route determined by its [name].
  void removeBelow(String name, {bool apply = true});

  /// Removes all routes below a specific [route].
  void removeRouteBelow(DefaultRoute route, {bool apply = true});

  /// Removes all routes above a specific route determined by its [name].
  void removeAbove(String name, {bool apply = true});

  /// Removes all routes above a specific [route].
  void removeRouteAbove(DefaultRoute route, {bool apply = true});

  /// Remove all routes with the group [name].
  /// All routes tagged with the group name will be removed.
  ///
  /// This method works for most of the common group usage scenarios.
  /// For complex scenarios with multiple separated groups
  /// with the same name, handle navigation manually
  /// by processing the route list and using [set].
  void removeGroup(String name, {bool apply = true, bool all = false});

  /// Replaces an [oldName] route with a new route, with [newName] or [newRoute].
  void replace(String oldName,
      {String? newName,
      DefaultRoute? newRoute,
      Map<String, dynamic>? data,
      bool apply = true});

  /// Replaces an [oldRoute] with a new [newRoute].
  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute,
      {bool apply = true});

  /// Replaces the route below a specific route determined by its [anchorName] with a new route.
  void replaceBelow(String anchorName, String name, {bool apply = true});

  /// Replaces the route below a specific [anchorRoute] with a new [newRoute].
  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute,
      {bool apply = true});

  /// Sets the navigation stack with routes based on a list of route [names].
  void set(List<String> names, {bool apply = true});

  /// Sets the navigation stack with the provided [routes].
  void setRoutes(List<DefaultRoute> routes, {bool apply = true});

  /// Sets the navigation stack with routes based on a list of route [names],
  /// preserving the current route at the top of the stack.
  void setBackstack(List<String> names, {bool apply = true});

  /// Sets the navigation stack with the provided [routes],
  /// preserving the current route at the top of the stack.
  void setBackstackRoutes(List<DefaultRoute> routes, {bool apply = true});

  /// Override all routes and navigation with a custom page.
  ///
  /// Show an override page built using the [pageBuilder]
  /// instead of through the Navigation APIs.
  ///
  /// Commonly used to show a loading screen while
  /// running async navigation operations. Setting
  /// an override ignores navigation events until the
  /// override is removed.
  ///
  /// For example, Firebase Auth returns authentication
  /// state after an arbitrary amount of time. When the
  /// user navigates to an authenticated page, show
  /// a loading overlay before navigating while the app
  /// waits for the authentication state.
  ///
  /// See `main_auth_delay.dart` in the examples folder.
  void setOverride(Page Function(String name) pageBuilder, {bool apply = true});

  /// Removes the page override.
  void removeOverride({bool apply = true});

  /// Push a custom page above the navigation stack
  /// without triggering any URL or navigation callback changes.
  ///
  /// Commonly used to show a lock screen that
  /// overlays all other pages, regardless of where the
  /// user has navigated to.
  ///
  /// See `main_lock_screen.dart` in the examples folder.
  void setOverlay(Page Function(String name) pageBuilder, {bool apply = true});

  /// Removes the page overlay.
  void removeOverlay({bool apply = true});

  /// Sets query parameters for the current route.
  void setQueryParameters(Map<String, String> queryParameters,
      {bool apply = true});

  /// Forces the Router to run the callback and create a new history entry in the browser.
  ///
  /// See [Router.navigate].
  void navigate(BuildContext context, Function function);

  /// Forces the Router to run the callback without creating a new history entry in the browser.
  ///
  /// See [Router.neglect].
  void neglect(BuildContext context, Function function);

  /// Apply navigation changes by calling `notifyListeners`
  /// on the NavigationDelegate's ChangeNotifier.
  ///
  /// Call apply after modifying the route stack using
  /// push, set, etc with `apply = false`, once edits are
  /// finished and ready.
  void apply();

  /// Clears navigation routes.
  ///
  /// Warning: Do not call without setting a new route stack
  /// as navigation requires a page at all times.
  void clear();
}
