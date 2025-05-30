import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'models/navigation_interface.dart';
import 'navigation_builder.dart';
import 'path_utils_go_router.dart';
import 'utils.dart';

class DefaultRoute extends RouteSettings {
  final String path;
  final String label;
  final Map<String, String> queryParameters;
  final Map<String, String> pathParameters;
  final Map<String, dynamic>? metadata;
  final String? group;

  /// A unique cache key for this route, used to manage page caching
  final String? cacheKey;

  Uri get uri => Uri(path: path, queryParameters: queryParameters);

  DefaultRoute(
      {required this.path,
      this.label = '',
      this.queryParameters = const {},
      this.pathParameters = const {},
      this.metadata = const {},
      this.group,
      this.cacheKey,
      super.arguments})
      : super(
            name: canonicalUri(
                Uri(path: path, queryParameters: queryParameters).toString()));

  factory DefaultRoute.fromUrl(String url,
      {String label = '',
      String? group,
      Map<String, dynamic>? metadata,
      String? cacheKey}) {
    Uri uri = Uri.parse(url);
    return DefaultRoute(
        path: uri.path,
        queryParameters: uri.queryParameters,
        label: label,
        group: group,
        metadata: metadata,
        cacheKey: cacheKey);
  }

  factory DefaultRoute.fromUri(Uri uri,
      {String label = '',
      String? group,
      Map<String, dynamic>? metadata,
      String? cacheKey}) {
    return DefaultRoute(
        path: uri.path,
        queryParameters: uri.queryParameters,
        label: label,
        group: group,
        metadata: metadata,
        cacheKey: cacheKey);
  }

  DefaultRoute copyWith(
      {String? label,
      String? path,
      Map<String, String>? queryParameters,
      Map<String, String>? pathParameters,
      Map<String, dynamic>? metadata,
      String? group,
      String? cacheKey,
      Object? arguments}) {
    return DefaultRoute(
      label: label ?? this.label,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      pathParameters: pathParameters ?? this.pathParameters,
      metadata: metadata ?? this.metadata,
      group: group ?? this.group,
      cacheKey: cacheKey ?? this.cacheKey,
      arguments: arguments ?? this.arguments,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DefaultRoute &&
      ((other.label.isNotEmpty && other.label == label) ||
          (other.path == path && other.path.isNotEmpty && path.isNotEmpty));

  @override
  int get hashCode => label.hashCode * path.hashCode;

  @override
  String toString() =>
      'Route(label: $label, path: $path, name: $name, queryParameters: $queryParameters, metadata: $metadata, group: $group, arguments: $arguments, cacheKey: $cacheKey)';

  operator [](String key) => queryParameters[key];
}

/// Pop until definition.
typedef PopUntilRouteFunction = bool Function(DefaultRoute route);

/// Set navigation callback.
typedef SetMainRoutesCallback = List<DefaultRoute> Function(
    List<DefaultRoute> controller);

/// The RouteDelegate defines application specific behaviors of how the router
/// learns about changes in the application state and how it responds to them.
/// It listens to the RouteInformation Parser and the app state and builds the Navigator with
/// the current list of pages (immutable object used to set navigator's history stack).
abstract class BaseRouterDelegate extends RouterDelegate<DefaultRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<DefaultRoute>
    implements NavigationInterface {
  // Persist the navigator with a global key.
  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Internal backstack and pages representation.
  List<DefaultRoute> _routes = [];

  List<DefaultRoute> get routes => _routes;

  bool _canPop = true;

  bool get canPop {
    if (_canPop == false) return false;

    return _routes.isNotEmpty;
  }

  set canPop(bool canPop) => _canPop = canPop;

  /// CurrentConfiguration detects changes in the route information
  /// It helps complete the browser history and enables browser back and forward buttons.
  @override
  DefaultRoute? get currentConfiguration =>
      routes.isNotEmpty ? routes.last : null;

  // Current route name.
  StreamController<DefaultRoute> currentRouteController =
      StreamController<DefaultRoute>.broadcast();
  Stream<DefaultRoute> get getCurrentRoute => currentRouteController.stream;

  Map<String, dynamic> globalData = {};

  List<NavigationData> navigationDataRoutes = [];

  Page Function(String name)? pageOverride;

  Page Function(String name)? pageOverlay;

  /// Exposes the [routes] history to the implementation to allow
  /// modifying the navigation stack based on app state.
  SetMainRoutesCallback? setMainRoutes;

  /// Unknown route generation function.
  OnUnknownRoute? onUnknownRoute;

  bool debugLog = false;

  /// Internal method that takes a Navigator initial route
  /// and maps to a list of routes.
  ///
  /// Do not call this function directly.
  @override
  @protected
  Future<void> setInitialRoutePath(DefaultRoute configuration) {
    _debugPrintMessage('setInitialRoutePath: $configuration');
    return setNewRoutePath(configuration);
  }

  /// Exposed method for setting the navigation stack
  /// given a new [configuration] path.
  ///
  /// Do not call this function directly.
  @override
  @protected
  Future<void> setNewRoutePath(DefaultRoute configuration) async {
    _debugPrintMessage('setNewRoutePath: $configuration');
    // Do not set empty route.
    if (configuration.label.isEmpty && configuration.path.isEmpty) return;
    _debugPrintMessage('setNewRoutePath: Old Routes: $routes');
    NavigationData? navigationData = NavigationUtils.getNavigationDataFromRoute(
        routes: navigationDataRoutes, route: configuration);
    // Resolve Route From Navigation Data.
    DefaultRoute? configurationHolder =
        NavigationUtils.mapNavigationDataToDefaultRoute(
            route: configuration,
            routes: navigationDataRoutes,
            globalData: globalData,
            navigationData: navigationData);

    // Unknown route. Show unknown route.
    configurationHolder ??= configuration;

    // Generate and assign cache key if not already present
    if (configurationHolder.cacheKey == null) {
      if (navigationData != null) {
        String cacheKey = NavigationBuilder.generateCacheKey(
            navigationData, configurationHolder);
        configurationHolder = configurationHolder.copyWith(cacheKey: cacheKey);
      }
    }

    // Handle InitialRoutePath logic here. Adding a page here ensures
    // there is always a page to display. The initial page is now set here
    // instead of in the Navigator widget.
    if (_routes.isEmpty) {
      _routes.add(configurationHolder);
      _debugPrintMessage('setNewRoutePath: Handle Initial Route: $routes');
    }

    // TODO: Implement canPop.

    bool didChangeRoute = currentConfiguration != configurationHolder;
    _routes = _setNewRouteHistory(_routes, configurationHolder);
    // User can customize returned routes with this exposed callback.
    _routes = setMainRoutes?.call(_routes) ?? _routes;
    if (_routes.isEmpty) {
      throw Exception('Routes cannot be empty.');
    }
    // Expose that the route has changed.
    if (didChangeRoute) onRouteChanged(_routes.last);
    _debugPrintMessage('setNewRoutePath: New Routes: $routes');
    notifyListeners();
    return;
  }

  /// Updates route path history.
  ///
  /// In a browser, forward and backward navigation
  /// is indeterminate and a custom path history stack
  /// implementation is needed.
  /// When a [newRoute] is added, check the existing [routes]
  /// to see if the path already exists. If the path exists,
  /// remove all path entries on top of the path.
  /// Otherwise, add the new path to the path list.
  List<DefaultRoute> _setNewRouteHistory(
      List<DefaultRoute> routes, DefaultRoute newRoute) {
    List<DefaultRoute> pathsHolder = [];
    pathsHolder.addAll(routes);
    // Check if new path exists in history.
    for (int i = 0; i < routes.length; i++) {
      DefaultRoute route = routes[i];

      // If path exists, remove all paths on top.
      if (route == newRoute) {
        // Important: preserve the existing route's cache key
        newRoute = newRoute.copyWith(cacheKey: route.cacheKey);

        int index = routes.indexOf(route);
        int count = routes.length;
        for (var i = index; i < count - 1; i++) {
          pathsHolder.removeLast();
        }
        pathsHolder.last = newRoute;
        return pathsHolder;
      }
    }

    // Add new path to history.
    pathsHolder.add(newRoute);

    return pathsHolder;
  }

  /// Exposes a callback for when the route changes.
  void onRouteChanged(DefaultRoute route) {
    currentRouteController.add(route);
  }

  /// A Completer to help return results from a popped route.
  final LinkedHashMap<DefaultRoute, Completer<dynamic>> _pageCompleters =
      LinkedHashMap();

  // Push

  @override
  Future<dynamic> push(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true}) async {
    NavigationData? navigationData =
        NavigationUtils.getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationData == null) {
      throw Exception('`$name` route not found.');
    }

    String? path;
    // Final path provided.
    if (name.startsWith('/') && name.contains(':') == false) {
      path = canonicalUri(name);
    } else if (navigationData.path.contains(':')) {
      // Named pattern path provided.
      path = patternToPath(navigationData.path, pathParameters);
    } else {
      // Named direct path provided.
      path = navigationData.path;
    }

    // Build DefaultRoute.
    DefaultRoute route = DefaultRoute(
        label: navigationData.label ?? '',
        path: path,
        pathParameters: pathParameters,
        queryParameters: {
          ...?queryParameters,
          ...navigationData.queryParameters
        },
        metadata: navigationData.metadata,
        group: navigationData.group,
        arguments: arguments);

    // Save global data to unique path key.
    globalData[path] = data;

    // Generate and assign a cache key
    String cacheKey = NavigationBuilder.generateCacheKey(navigationData, route);
    route = route.copyWith(cacheKey: cacheKey);

    // Check duplicate route to prevent inadvertently
    // adding the same page twice. Duplicate pages are
    // commonly added if a user presses a navigation button twice
    // very quickly.
    //
    // If the path is different, this is a new page.
    // Else, return the current page.
    if (routes.isNotEmpty &&
        (_routes.last.path == route.path ||
            (route.group != null && _routes.contains(route)))) {
      // Note: Should probably move to keys or a canonicalized route identifier.
      // There's a subtle behavior with routes matching based on label when the path is different.
      // That behavior is sometimes intended but sometimes unintended.
      for (int i = _routes.length - 1; i >= 0; i--) {
        if (_routes[i] == route) {
          _routes.removeAt(i);
          break;
        }
      }
      _routes.add(route);
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
      return _pageCompleters[route]?.future;
    }

    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[route] = pageCompleter;
    _routes.add(route);
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
    return pageCompleter.future;
  }

  // Push Route

  @override
  Future<dynamic> pushRoute(DefaultRoute route, {bool apply = true}) async {
    // Check duplicate route to prevent inadvertently
    // adding the same page twice. Duplicate pages are
    // commonly added if a user presses a navigation button twice
    // very quickly.
    //
    // If the path is different, this is a new page.
    // Else, return the current page.
    if (routes.isNotEmpty &&
        (_routes.last.path == route.path ||
            (route.group != null && _routes.contains(route)))) {
      for (int i = _routes.length - 1; i >= 0; i--) {
        if (_routes[i] == route) {
          _routes.removeAt(i);
          break;
        }
      }
      _routes.add(route);
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
      return _pageCompleters[route]?.future;
    }

    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[route] = pageCompleter;
    _routes.add(route);
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
    return pageCompleter.future;
  }

  // Pop

  @override
  void pop([dynamic result, bool apply = true, bool all = false]) {
    if (canPop == false) return;
    if (all == false && _routes.length <= 1) return;

    DefaultRoute poppedRoute = _routes.last;

    // Use the route's cacheKey directly for reliable cache clearing
    NavigationBuilder.clearCachedRoute(poppedRoute);

    if (_pageCompleters.containsKey(poppedRoute)) {
      _pageCompleters[poppedRoute]!.complete(result);
      _pageCompleters.remove(poppedRoute);
    }

    _routes.removeLast();
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Pop Until

  @override
  void popUntil(
    String name, {
    bool apply = true,
    bool all = false,
    bool inclusive = false,
  }) {
    DefaultRoute? route = _routes.isNotEmpty ? _routes.last : null;
    while (route != null) {
      if (route.label == name ||
          route.path == name ||
          (all == false && _routes.length == 1)) {
        if (inclusive) pop(null, false, all);
        break;
      }
      pop(null, false, all);
      route = _routes.isNotEmpty ? _routes.last : null;
    }
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  @override
  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true, bool all = false, bool inclusive = false}) {
    DefaultRoute? route = _routes.isNotEmpty ? _routes.last : null;
    while (route != null) {
      if (popUntilRouteFunction(route) ||
          (all == false && _routes.length == 1)) {
        if (inclusive) pop(null, false, all);
        break;
      }
      pop(null, false, all);
      route = _routes.isNotEmpty ? _routes.last : null;
    }
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Push and Remove Until

  @override
  Future<dynamic> pushAndRemoveUntil(String name, String routeUntilName,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool inclusive = false,
      bool apply = true}) async {
    popUntil(routeUntilName, apply: false, all: true, inclusive: inclusive);
    return await push(name,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        apply: apply);
  }

  @override
  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true, bool inclusive = false}) async {
    popUntilRoute(popUntilRouteFunction,
        apply: false, all: true, inclusive: inclusive);
    return await pushRoute(route, apply: apply);
  }

  // Remove

  @override
  void remove(String name, {bool apply = true}) {
    DefaultRoute route =
        NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

    removeRoute(route, apply: apply);
  }

  @override
  void removeRoute(DefaultRoute route, {bool apply = true}) {
    while (_routes.contains(route) && _routes.length > 1) {
      for (int i = _routes.length - 1; i >= 0; i--) {
        if (_routes[i] == route) {
          NavigationBuilder.clearCachedRoute(_routes[i]);
          _routes.removeAt(i);
          break;
        }
      }
    }
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Push Replacement

  @override
  Future<dynamic> pushReplacement(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      dynamic result,
      bool apply = true}) async {
    if (_routes.isNotEmpty) {
      NavigationBuilder.clearCachedRoute(_routes.last);
    }
    pop(result, false, true);
    return await push(name,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        apply: apply);
  }

  @override
  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result, bool apply = true]) async {
    if (_routes.isNotEmpty) {
      NavigationBuilder.clearCachedRoute(_routes.last);
    }
    pop(result, false, true);
    return await pushRoute(route, apply: apply);
  }

  // Remove Below

  @override
  void removeBelow(String name, {bool apply = true}) {
    DefaultRoute route =
        NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

    int anchorIndex = _routes.indexOf(route);
    if (anchorIndex >= 1) {
      NavigationBuilder.clearCachedRoute(_routes[anchorIndex - 1]);
      _routes.removeAt(anchorIndex - 1);
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
    }
  }

  @override
  void removeRouteBelow(DefaultRoute route, {bool apply = true}) {
    int anchorIndex = _routes.indexOf(route);
    if (anchorIndex >= 1) {
      NavigationBuilder.clearCachedRoute(_routes[anchorIndex - 1]);
      _routes.removeAt(anchorIndex - 1);
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
    }
  }

  // Remove Above

  @override
  void removeAbove(String name, {bool apply = true}) {
    DefaultRoute route =
        NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

    int anchorIndex = _routes.indexOf(route);
    if (anchorIndex < _routes.length - 1) {
      // Clear the route cache before removing
      NavigationBuilder.clearCachedRoute(_routes[anchorIndex + 1]);
      _routes.removeAt(anchorIndex + 1);
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
    }
  }

  @override
  void removeRouteAbove(DefaultRoute route, {bool apply = true}) {
    int anchorIndex = _routes.indexOf(route);
    if (anchorIndex < _routes.length - 1) {
      NavigationBuilder.clearCachedRoute(_routes[anchorIndex + 1]);
      _routes.removeAt(anchorIndex + 1);
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
    }
  }

  @override
  void removeGroup(String name, {bool apply = true, bool all = false}) {
    for (int i = _routes.length - 1; i >= 0; i--) {
      DefaultRoute route = _routes[i];

      if (route.group == name) {
        if (!canPop || (all == false && _routes.length <= 1)) {
          continue;
        }

        NavigationBuilder.clearCachedRoute(route);

        if (_pageCompleters.containsKey(route)) {
          _pageCompleters[route]!.complete(null);
          _pageCompleters.remove(route);
        }

        // Remove the route at the current index
        _routes.removeAt(i);
      }
    }
    if (_routes.isNotEmpty && apply) {
      onRouteChanged(_routes.last);
    }
    if (apply) {
      notifyListeners();
    }
  }

  // Replace

  @override
  void replace(String oldName,
      {String? newName,
      DefaultRoute? newRoute,
      Map<String, dynamic>? data,
      bool apply = true}) {
    assert((newName != null || newRoute != null),
        'Route and route name cannot both be empty.');

    DefaultRoute? oldRoute = NavigationUtils.buildDefaultRouteFromName(
        navigationDataRoutes, oldName);

    int index = _routes.indexOf(oldRoute);
    if (index == -1) return;

    NavigationBuilder.clearCachedRoute(_routes[index]);

    DefaultRoute? defaultRouteHolder = newRoute;

    if (newName != null) {
      defaultRouteHolder = NavigationUtils.buildDefaultRouteFromName(
          navigationDataRoutes, newName);
    }

    _routes[index] = defaultRouteHolder!;

    // Save global data to name key.
    if (data != null) {
      if (newRoute != null) {
        globalData[defaultRouteHolder.path] = data;
      }
    }

    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
    return;
  }

  @override
  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute,
      {bool apply = true}) {
    replace(oldRoute.path, newRoute: newRoute, apply: apply);
  }

  // Replace Below

  @override
  void replaceBelow(String anchorName, String name, {bool apply = true}) {
    NavigationData? navigationDataAnchor =
        NavigationUtils.getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationDataAnchor == null) return;

    DefaultRoute anchorRoute = DefaultRoute(
        label: navigationDataAnchor.label ?? '',
        path: navigationDataAnchor.path);

    int index = _routes.indexOf(anchorRoute);
    if (index >= 1) {
      NavigationBuilder.clearCachedRoute(_routes[index - 1]);

      DefaultRoute newRoute =
          NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

      _routes[index - 1] = newRoute;
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
    }
  }

  @override
  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute,
      {bool apply = true}) {
    int index = _routes.indexOf(anchorRoute);
    if (index >= 1) {
      NavigationBuilder.clearCachedRoute(_routes[index - 1]);

      _routes[index - 1] = newRoute;
      if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
      if (apply) notifyListeners();
    }
  }

  // Set

  @override
  void set(List<String> names, {bool apply = true}) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    NavigationBuilder.clearCache();
    _routes.clear();
    // Map route names to routes.
    _routes.addAll(names.map((e) {
      return NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, e);
    }));

    _routes = setMainRoutes?.call(_routes) ?? _routes;
    if (_routes.isEmpty) {
      throw Exception('Routes cannot be empty.');
    }
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  @override
  void setRoutes(List<DefaultRoute> routes, {bool apply = true}) {
    assert(routes.isNotEmpty, 'Routes cannot be empty.');
    NavigationBuilder.clearCache();
    _routes.clear();
    _routes.addAll(routes);
    _routes = setMainRoutes?.call(_routes) ?? _routes;
    if (_routes.isEmpty) {
      throw Exception('Routes cannot be empty.');
    }
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Set Backstack

  @override
  void setBackstack(List<String> names, {bool apply = true}) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    for (int i = 0; i < _routes.length - 1; i++) {
      NavigationBuilder.clearCachedRoute(_routes[i]);
    }
    DefaultRoute currentRoute = _routes.last;
    _routes.clear();
    // Map route names to routes.
    _routes.addAll(names.map((e) {
      return NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, e);
    }));
    _routes.add(currentRoute);
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  @override
  void setBackstackRoutes(List<DefaultRoute> routes, {bool apply = true}) {
    for (int i = 0; i < _routes.length - 1; i++) {
      NavigationBuilder.clearCachedRoute(_routes[i]);
    }
    DefaultRoute currentRoute = _routes.last;
    _routes.clear();
    _routes.addAll(routes);
    _routes.add(currentRoute);
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Set Override

  @override
  void setOverride(Page Function(String name) pageBuilder,
      {bool apply = true}) {
    pageOverride = pageBuilder;
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  @override
  void removeOverride({bool apply = true}) {
    pageOverride = null;
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  @override
  void setOverlay(Page Function(String name) pageBuilder, {bool apply = true}) {
    pageOverlay = pageBuilder;
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  @override
  void removeOverlay({bool apply = true}) {
    pageOverlay = null;
    if (_routes.isNotEmpty && apply) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Query Parameters

  @override
  void setQueryParameters(Map<String, String> queryParameters,
      {bool apply = true}) {
    _routes.last = _routes.last.copyWith(queryParameters: queryParameters);
    if (apply) notifyListeners();
  }

  // ignore: unused_element
  String _buildQueryParameters(Map<String, String> queryParameters) {
    return queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&')
        .toString();
  }

  // Route Functions

  @override
  void navigate(BuildContext context, Function function) {
    Router.navigate(context, () {
      function.call();
      notifyListeners();
    });
  }

  @override
  void neglect(BuildContext context, Function function) {
    Router.neglect(context, () {
      function.call();
      notifyListeners();
    });
  }

  @override
  void apply() {
    onRouteChanged(_routes.last);
    notifyListeners();
  }

  @override
  void clear() {
    NavigationBuilder.clearCache();
    _routes.clear();
  }

  void _debugPrintMessage(String message) {
    if (debugLog) {
      debugPrint('NavigationUtils: $message');
    }
  }
}
