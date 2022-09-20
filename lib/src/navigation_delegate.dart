import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'navigation_builder.dart';
import 'path_utils_go_router.dart';

class DefaultRoute extends RouteSettings {
  final String label;
  final String path;
  final Map<String, String> queryParameters;
  final Map<String, String> pathParameters;
  final Map<String, dynamic>? metadata;

  DefaultRoute(
      {this.label = '',
      this.path = '',
      this.queryParameters = const {},
      this.pathParameters = const {},
      this.metadata = const {},
      super.arguments})
      : super(
            name: _trimRight(
                Uri(path: path, queryParameters: queryParameters).toString(),
                '?'));

  Uri get uri => Uri(path: path, queryParameters: queryParameters);

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

  static String _trimRight(String from, String pattern) {
    if (from.isEmpty || pattern.isEmpty || pattern.length > from.length) {
      return from;
    }

    while (from.endsWith(pattern)) {
      from = from.substring(0, from.length - pattern.length);
    }
    return from;
  }
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
  List<DefaultRoute> _defaultRoutes = [];

  List<DefaultRoute> get defaultRoutes => _defaultRoutes;

  bool _canPop = true;

  bool get canPop {
    if (_canPop == false) return false;

    return _defaultRoutes.isNotEmpty;
  }

  set canPop(bool canPop) => _canPop = canPop;

  /// CurrentConfiguration detects changes in the route information
  /// It helps complete the browser history and enables browser back and forward buttons.
  @override
  DefaultRoute? get currentConfiguration =>
      defaultRoutes.isNotEmpty ? defaultRoutes.last : null;

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
    // Handle InitialRoutePath logic here. Adding a page here ensures
    // there is always a page to display. The initial page is now set here
    // instead of in the Navigator widget.
    if (_defaultRoutes.isEmpty) {
      _defaultRoutes.add(configuration);
      return;
    }

    // TODO: Implement canPop.

    bool didChangeRoute = currentConfiguration != configuration;
    _debugPrintMessage('Main Routes $defaultRoutes');
    _defaultRoutes = _setNewRouteHistory(_defaultRoutes, configuration);
    // User can customize returned routes with this exposed callback.
    _defaultRoutes = setMainRoutes?.call(_defaultRoutes) ?? _defaultRoutes;
    // Expose that the route has changed.
    if (didChangeRoute) onRouteChanged(_defaultRoutes.last);
    _debugPrintMessage('Main Routes Updated $defaultRoutes');
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
      Map<String, String> pathParameters = const {}}) async {
    NavigationData? navigationData =
        _getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationData == null) {
      throw Exception('`$name` route not found.');
    }

    String path = navigationData.path;
    if (navigationData.path.contains(':')) {
      path = patternToPath(navigationData.path, pathParameters);
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
    if (_defaultRoutes.contains(route)) {
      _defaultRoutes.remove(route);
      _defaultRoutes.add(route);
      notifyListeners();
      return _pageCompleters[route]?.future;
    }

    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[route] = pageCompleter;
    _defaultRoutes.add(route);
    notifyListeners();
    return pageCompleter.future;
  }

  Future<dynamic> pushRoute(DefaultRoute path) async {
    if (_defaultRoutes.contains(path)) {
      _defaultRoutes.remove(path);
      _defaultRoutes.add(path);
      notifyListeners();
      return _pageCompleters[path]?.future;
    }
    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[path] = pageCompleter;
    _defaultRoutes.add(path);
    notifyListeners();
    return pageCompleter.future;
  }

  // Pop

  void pop([dynamic result]) {
    if (canPop) {
      if (_pageCompleters.containsKey(defaultRoutes.last)) {
        _pageCompleters[defaultRoutes.last]!.complete(result);
        _pageCompleters.remove(defaultRoutes.last);
      }
      _defaultRoutes.removeLast();
      notifyListeners();
    }
  }

  // Pop Until

  void popUntil(String name) {
    DefaultRoute? route =
        _defaultRoutes.isNotEmpty ? _defaultRoutes.last : null;
    while (route != null) {
      if (route.name == name ||
          route.path == name ||
          _defaultRoutes.length == 1) break;
      pop();
      route = _defaultRoutes.isNotEmpty ? _defaultRoutes.last : null;
    }
    notifyListeners();
  }

  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction) {
    DefaultRoute? route =
        _defaultRoutes.isNotEmpty ? _defaultRoutes.last : null;
    while (route != null) {
      if (popUntilRouteFunction(route) || _defaultRoutes.length == 1) break;
      pop();
      route = _defaultRoutes.isNotEmpty ? _defaultRoutes.last : null;
    }
    notifyListeners();
  }

  // Push and Remove Until

  Future<dynamic> pushAndRemoveUntil(String name, String routeUntilName) async {
    popUntil(routeUntilName);
    return await push(name);
  }

  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction) async {
    popUntilRoute(popUntilRouteFunction);
    return await pushRoute(route);
  }

  // Remove

  void remove(String name) {
    NavigationData? navigationData =
        _getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationData == null) return;

    DefaultRoute route = DefaultRoute(
        label: navigationData.label ?? '', path: navigationData.path);

    removeRoute(route);
  }

  void removeRoute(DefaultRoute route) {
    if (_defaultRoutes.contains(route)) {
      _defaultRoutes.remove(route);
      notifyListeners();
    }
  }

  // Push Replacement

  Future<dynamic> pushReplacement(String name, [dynamic result]) async {
    pop(result);
    return await push(name);
  }

  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result]) async {
    pop(result);
    return await pushRoute(route);
  }

  // Remove Below

  void removeBelow(String name) {
    NavigationData? navigationData =
        _getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationData == null) return;

    DefaultRoute route = DefaultRoute(
        label: navigationData.label ?? '', path: navigationData.path);

    int anchorIndex = _defaultRoutes.indexOf(route);
    if (anchorIndex >= 1) {
      _defaultRoutes.removeAt(anchorIndex - 1);
      notifyListeners();
    }
  }

  void removeRouteBelow(DefaultRoute route) {
    int anchorIndex = _defaultRoutes.indexOf(route);
    if (anchorIndex >= 1) {
      _defaultRoutes.removeAt(anchorIndex - 1);
      notifyListeners();
    }
  }

  // Replace

  void replace(String oldName, {String? newName, DefaultRoute? newRoute}) {
    assert((newName != null || newRoute != null),
        'Route and route name cannot both be empty.');

    NavigationData? navigationDataOld =
        _getNavigationDataFromName(navigationDataRoutes, oldName);
    if (navigationDataOld == null) return;

    DefaultRoute oldRoute = DefaultRoute(
        label: navigationDataOld.label ?? '', path: navigationDataOld.path);

    int index = _defaultRoutes.indexOf(oldRoute);
    if (index == -1) return;

    DefaultRoute? defaultRouteHolder = newRoute;

    if (newName != null) {
      NavigationData? navigationDataNew =
          _getNavigationDataFromName(navigationDataRoutes, newName);
      if (navigationDataNew == null) return;

      defaultRouteHolder = DefaultRoute(
          label: navigationDataNew.label ?? '', path: navigationDataNew.path);
    }

    _defaultRoutes[index] = defaultRouteHolder!;
    notifyListeners();
    return;
  }

  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute) {
    replace(oldRoute.path, newRoute: newRoute);
  }

  // Replace Below

  void replaceBelow(String anchorName, String name) {
    NavigationData? navigationDataAnchor =
        _getNavigationDataFromName(navigationDataRoutes, name);
    if (navigationDataAnchor == null) return;

    DefaultRoute anchorRoute = DefaultRoute(
        label: navigationDataAnchor.label ?? '',
        path: navigationDataAnchor.path);

    int index = _defaultRoutes.indexOf(anchorRoute);
    if (index >= 1) {
      NavigationData? navigationData =
          _getNavigationDataFromName(navigationDataRoutes, name);
      if (navigationData == null) return;

      DefaultRoute newRoute = DefaultRoute(
          label: navigationData.label ?? '', path: navigationData.path);

      _defaultRoutes[index - 1] = newRoute;
      notifyListeners();
    }
  }

  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute) {
    int index = _defaultRoutes.indexOf(anchorRoute);
    if (index >= 1) {
      _defaultRoutes[index - 1] = newRoute;
      notifyListeners();
    }
  }

  // Set

  void set(List<String> names) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    _defaultRoutes.clear();
    // Map route names to routes.
    _defaultRoutes.addAll(names.map((e) {
      NavigationData? navigationData =
          _getNavigationDataFromName(navigationDataRoutes, e);
      if (navigationData == null) {
        throw Exception('`$e` route not found.');
      }

      return DefaultRoute(
          label: e,
          path: navigationData.path,
          metadata: navigationData.metadata);
    }));
    // Notify route change listeners that route has changed.
    onRouteChanged(_defaultRoutes.last);
    notifyListeners();
  }

  void setRoutes(List<DefaultRoute> routes) {
    assert(routes.isNotEmpty, 'Routes cannot be empty.');
    _defaultRoutes.clear();
    _defaultRoutes.addAll(routes);
    // Notify route change listeners that route has changed.
    onRouteChanged(_defaultRoutes.last);
    notifyListeners();
  }

  // Set Backstack

  void setBackstack(List<String> names) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    DefaultRoute currentRoute = _defaultRoutes.last;
    _defaultRoutes.clear();
    // Map route names to routes.
    _defaultRoutes.addAll(names.map((e) {
      NavigationData? navigationData =
          _getNavigationDataFromName(navigationDataRoutes, e);
      if (navigationData == null) {
        throw Exception('`$e` route not found.');
      }

      return DefaultRoute(
          label: e,
          path: navigationData.path,
          metadata: navigationData.metadata);
    }));
    _defaultRoutes.add(currentRoute);
    notifyListeners();
  }

  void setBackstackRoutes(List<DefaultRoute> routes) {
    DefaultRoute currentRoute = _defaultRoutes.last;
    _defaultRoutes.clear();
    _defaultRoutes.addAll(routes);
    _defaultRoutes.add(currentRoute);
    notifyListeners();
  }

  // Set Override

  void setOverride(Widget page) {
    pageOverride = page;
    notifyListeners();
  }

  void removeOverride() {
    pageOverride = null;
    notifyListeners();
  }

  // Query Parameters

  void setQueryParameters(Map<String, String> queryParameters) {
    _defaultRoutes.last =
        _defaultRoutes.last.copyWith(queryParameters: queryParameters);
    notifyListeners();
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

  // Util Methods

  NavigationData? _getNavigationDataFromName(
      List<NavigationData> navigationDataRoutes, String name) {
    NavigationData? navigationData;
    if (name.startsWith('/') == false) {
      try {
        navigationData = navigationDataRoutes.firstWhere((element) =>
            ((element.label?.isNotEmpty ?? false) && element.label == name));
      } on StateError {
        // ignore: empty_catches
      }
    } else {
      try {
        navigationData = navigationDataRoutes
            .firstWhere((element) => (element.path == name));
      } on StateError {
        // ignore: empty_catches
      }
    }

    return navigationData;
  }

  void _debugPrintMessage(String message) {
    if (debugLog) {
      debugPrint('NavigationUtils: $message');
    }
  }
}
