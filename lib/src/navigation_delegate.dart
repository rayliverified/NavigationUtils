import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'navigation_builder.dart';
import 'path_utils_go_router.dart';
import 'utils.dart';

class DefaultRoute extends RouteSettings {
  final String path;
  final String label;
  final Map<String, String> queryParameters;
  final Map<String, String> pathParameters;
  final Map<String, dynamic>? metadata;

  Uri get uri => Uri(path: path, queryParameters: queryParameters);

  DefaultRoute(
      {required this.path,
      this.label = '',
      this.queryParameters = const {},
      this.pathParameters = const {},
      this.metadata = const {},
      super.arguments})
      : super(
            name: canonicalUri(
                Uri(path: path, queryParameters: queryParameters).toString()));

  factory DefaultRoute.fromUrl(String url,
      {String label = '', Map<String, dynamic>? metadata}) {
    Uri uri = Uri.parse(url);
    return DefaultRoute(
        path: uri.path,
        queryParameters: uri.queryParameters,
        label: label,
        metadata: metadata);
  }

  @override
  DefaultRoute copyWith(
      {String? label,
      String? path,
      Map<String, String>? queryParameters,
      Map<String, String>? pathParameters,
      Map<String, dynamic>? metadata,
      Object? arguments,
      String? name}) {
    return DefaultRoute(
      label: label ?? this.label,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      pathParameters: pathParameters ?? this.pathParameters,
      metadata: metadata ?? this.metadata,
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
      'Route(label: $label, path: $path, name: $name, queryParameters: $queryParameters, metadata: $metadata, arguments: $arguments)';

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
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<DefaultRoute> {
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

  Widget? pageOverride;

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
    _debugPrintMessage('setInitialRoutePath');
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

    _debugPrintMessage('Main Routes: $routes');

    // Resolve Route From Navigation Data.
    DefaultRoute? configurationHolder =
        NavigationUtils.mapNavigationDataToDefaultRoute(
            route: configuration,
            routes: navigationDataRoutes,
            globalData: globalData);

    // Unknown route, do not navigate if unknown route is not implemented.
    if (configurationHolder == null && onUnknownRoute != null) {
      configurationHolder = configuration;
    }
    if (configurationHolder == null) return;

    // Handle InitialRoutePath logic here. Adding a page here ensures
    // there is always a page to display. The initial page is now set here
    // instead of in the Navigator widget.
    if (_routes.isEmpty) {
      _routes.add(configurationHolder);
      _debugPrintMessage('New Initialized Route: $routes');
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
    _debugPrintMessage('Main Routes Updated: $routes');
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
    for (DefaultRoute path in routes) {
      // If path exists, remove all paths on top.
      if (path == newRoute) {
        int index = routes.indexOf(path);
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
        queryParameters: queryParameters ?? navigationData.queryParameters,
        metadata: navigationData.metadata,
        arguments: arguments);

    // Save global data to name key.
    globalData[name] = data;

    // If route already exists, move to top.
    if (_routes.contains(route)) {
      _routes.remove(route);
      _routes.add(route);
      notifyListeners();
      return _pageCompleters[route]?.future;
    }

    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[route] = pageCompleter;
    _routes.add(route);
    if (apply) notifyListeners();
    return pageCompleter.future;
  }

  Future<dynamic> pushRoute(DefaultRoute path, {bool apply = true}) async {
    if (_routes.contains(path)) {
      _routes.remove(path);
      _routes.add(path);
      notifyListeners();
      return _pageCompleters[path]?.future;
    }
    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[path] = pageCompleter;
    _routes.add(path);
    if (apply) notifyListeners();
    return pageCompleter.future;
  }

  // Pop

  void pop([dynamic result, bool apply = true]) {
    if (canPop) {
      if (_pageCompleters.containsKey(routes.last)) {
        _pageCompleters[routes.last]!.complete(result);
        _pageCompleters.remove(routes.last);
      }
      _routes.removeLast();
      if (_routes.isNotEmpty) {
        onRouteChanged(_routes.last);
      }
      if (apply) notifyListeners();
    }
  }

  // Pop Until

  void popUntil(String name, {bool apply = true}) {
    DefaultRoute? route = _routes.isNotEmpty ? _routes.last : null;
    while (route != null) {
      if (route.label == name || route.path == name || _routes.length == 1)
        break;
      pop();
      route = _routes.isNotEmpty ? _routes.last : null;
    }
    if (apply) notifyListeners();
  }

  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true}) {
    DefaultRoute? route = _routes.isNotEmpty ? _routes.last : null;
    while (route != null) {
      if (popUntilRouteFunction(route) || _routes.length == 1) break;
      pop();
      route = _routes.isNotEmpty ? _routes.last : null;
    }
    if (apply) notifyListeners();
  }

  // Push and Remove Until

  Future<dynamic> pushAndRemoveUntil(String name, String routeUntilName,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true}) async {
    popUntil(routeUntilName, apply: apply);
    return await push(name,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        apply: apply);
  }

  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true}) async {
    popUntilRoute(popUntilRouteFunction, apply: apply);
    return await pushRoute(route, apply: apply);
  }

  // Remove

  void remove(String name, {bool apply = true}) {
    DefaultRoute route =
        NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

    removeRoute(route, apply: apply);
  }

  void removeRoute(DefaultRoute route, {bool apply = true}) {
    if (_routes.contains(route)) {
      _routes.remove(route);
      if (apply) notifyListeners();
    }
  }

  // Push Replacement

  Future<dynamic> pushReplacement(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      dynamic result,
      bool apply = true}) async {
    pop(result, apply);
    return await push(name,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        apply: apply);
  }

  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result, bool apply = true]) async {
    pop(result, apply);
    return await pushRoute(route, apply: apply);
  }

  // Remove Below

  void removeBelow(String name, {bool apply = true}) {
    DefaultRoute route =
        NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

    int anchorIndex = _routes.indexOf(route);
    if (anchorIndex >= 1) {
      _routes.removeAt(anchorIndex - 1);
      if (apply) notifyListeners();
    }
  }

  void removeRouteBelow(DefaultRoute route, {bool apply = true}) {
    int anchorIndex = _routes.indexOf(route);
    if (anchorIndex >= 1) {
      _routes.removeAt(anchorIndex - 1);
      if (apply) notifyListeners();
    }
  }

  // Replace

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

    DefaultRoute? defaultRouteHolder = newRoute;

    if (newName != null) {
      defaultRouteHolder = NavigationUtils.buildDefaultRouteFromName(
          navigationDataRoutes, newName);
    }

    _routes[index] = defaultRouteHolder!;

    // Save global data to name key.
    if (data != null) {
      if (newName != null) {
        globalData[newName] = data;
      }

      if (newRoute != null) {
        globalData[canonicalUri(newRoute.path)] = data;
      }
    }

    if (apply) notifyListeners();
    return;
  }

  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute,
      {bool apply = true}) {
    replace(oldRoute.path, newRoute: newRoute, apply: apply);
  }

  // Replace Below

  void replaceBelow(String anchorName, String name, {bool apply = true}) {
    NavigationData? navigationDataAnchor =
        NavigationUtils.getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationDataAnchor == null) return;

    DefaultRoute anchorRoute = DefaultRoute(
        label: navigationDataAnchor.label ?? '',
        path: navigationDataAnchor.path);

    int index = _routes.indexOf(anchorRoute);
    if (index >= 1) {
      DefaultRoute newRoute =
          NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, name);

      _routes[index - 1] = newRoute;
      if (apply) notifyListeners();
    }
  }

  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute,
      {bool apply = true}) {
    int index = _routes.indexOf(anchorRoute);
    if (index >= 1) {
      _routes[index - 1] = newRoute;
      if (apply) notifyListeners();
    }
  }

  // Set

  void set(List<String> names, {bool apply = true}) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    DefaultRoute? oldRoute = _routes.isNotEmpty ? _routes.last : null;

    _routes.clear();
    // Map route names to routes.
    _routes.addAll(names.map((e) {
      return NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, e);
    }));

    bool didChangeRoute = oldRoute != _routes.last;

    _routes = setMainRoutes?.call(_routes) ?? _routes;
    if (_routes.isEmpty) {
      throw Exception('Routes cannot be empty.');
    }
    // Expose that the route has changed.
    if (didChangeRoute) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  void setRoutes(List<DefaultRoute> routes, {bool apply = true}) {
    assert(routes.isNotEmpty, 'Routes cannot be empty.');
    bool didChangeRoute =
        routes.last != (_routes.isNotEmpty ? _routes.last : null);

    _routes.clear();
    _routes.addAll(routes);
    _routes = setMainRoutes?.call(_routes) ?? _routes;
    if (_routes.isEmpty) {
      throw Exception('Routes cannot be empty.');
    }
    // Expose that the route has changed.
    if (didChangeRoute) onRouteChanged(_routes.last);
    if (apply) notifyListeners();
  }

  // Set Backstack

  void setBackstack(List<String> names, {bool apply = true}) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    DefaultRoute currentRoute = _routes.last;
    _routes.clear();
    // Map route names to routes.
    _routes.addAll(names.map((e) {
      return NavigationUtils.buildDefaultRouteFromName(navigationDataRoutes, e);
    }));
    _routes.add(currentRoute);
    if (apply) notifyListeners();
  }

  void setBackstackRoutes(List<DefaultRoute> routes, {bool apply = true}) {
    DefaultRoute currentRoute = _routes.last;
    _routes.clear();
    _routes.addAll(routes);
    _routes.add(currentRoute);
    if (apply) notifyListeners();
  }

  // Set Override

  void setOverride(Widget page, {bool apply = true}) {
    pageOverride = page;
    if (apply) notifyListeners();
  }

  void removeOverride({bool apply = true}) {
    pageOverride = null;
    if (apply) notifyListeners();
  }

  // Query Parameters

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

  void navigate(BuildContext context, Function function) {
    Router.navigate(context, () {
      function.call();
      notifyListeners();
    });
  }

  void neglect(BuildContext context, Function function) {
    Router.neglect(context, () {
      function.call();
      notifyListeners();
    });
  }

  void apply() {
    notifyListeners();
  }

  void _debugPrintMessage(String message) {
    if (debugLog) {
      debugPrint('NavigationUtils: $message');
    }
  }
}
