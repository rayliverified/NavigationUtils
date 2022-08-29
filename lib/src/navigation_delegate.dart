import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'navigation_builder.dart';

class DefaultRoute extends RouteSettings {
  final String label;
  final String path;
  final Map<String, String> queryParameters;
  final dynamic data;

  DefaultRoute(
      {this.label = '',
      this.path = '',
      this.queryParameters = const {},
      this.data = const {},
      super.arguments})
      : super(
            name: _trimRight(
                Uri(path: path, queryParameters: queryParameters).toString(),
                '?'));

  Uri get uri => Uri(path: path, queryParameters: queryParameters);

  @override
  RouteSettings copyWith(
      {String? label,
      String? path,
      Map<String, String>? queryParameters,
      Object? arguments,
      dynamic data,
      String? name}) {
    return DefaultRoute(
      label: label ?? this.label,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      arguments: arguments ?? this.arguments,
      data: data ?? this.data,
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
      'Route(label: $label, path: $path, name: $name, queryParameters: $queryParameters, arguments: $arguments)';

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
    _defaultRoutes = setMainRoutes(_defaultRoutes) ?? _defaultRoutes;
    // Expose that the route has changed.
    if (didChangeRoute) onRouteChanged(_defaultRoutes.last);
    _debugPrintMessage('Main Routes Updated $defaultRoutes');
    notifyListeners();
    return;
  }

  @override
  Future<bool> popRoute() {
    _debugPrintMessage('popRoute');
    return super.popRoute();
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

  /// Exposes the [routes] history to the implementation to allow
  /// modifying the navigation stack based on app state.
  List<DefaultRoute>? setMainRoutes(List<DefaultRoute> routes) => routes;

  /// Exposes a callback for when the route changes.
  void onRouteChanged(DefaultRoute route) {
    currentRouteController.add(route);
  }

  /// A Completer to help return results from a popped route.
  final LinkedHashMap<DefaultRoute, Completer<dynamic>> _pageCompleters =
      LinkedHashMap();

  // Push

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

  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction) {
    DefaultRoute? pathEntry =
        _defaultRoutes.isNotEmpty ? _defaultRoutes.last : null;
    while (pathEntry != null) {
      if (popUntilRouteFunction(pathEntry)) break;
      pop();
      pathEntry = _defaultRoutes.isNotEmpty ? _defaultRoutes.last : null;
    }
    notifyListeners();
  }

  // Push and Remove Until

  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction) async {
    popUntilRoute(popUntilRouteFunction);
    _defaultRoutes.add(route);
    notifyListeners();
  }

  // Remove

  void removeRoute(DefaultRoute route) {
    if (_defaultRoutes.contains(route)) {
      _defaultRoutes.remove(route);
      notifyListeners();
    }
  }

  // Push Replacement

  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result]) async {
    pop(result);
    return await pushRoute(route);
  }

  // Remove Below

  void removeRouteBelow(DefaultRoute route) {
    int anchorIndex = _defaultRoutes.indexOf(route);
    if (anchorIndex >= 1) {
      _defaultRoutes.removeAt(anchorIndex - 1);
      notifyListeners();
    }
  }

  // Replace

  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute) {
    int index = _defaultRoutes.indexOf(oldRoute);
    if (index != -1) {
      _defaultRoutes[index] = newRoute;
      notifyListeners();
    }
  }

  // Replace Below

  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute) {
    int index = _defaultRoutes.indexOf(anchorRoute);
    if (index >= 1) {
      _defaultRoutes[index - 1] = newRoute;
      notifyListeners();
    }
  }

  // Set

  void setRoutes(List<DefaultRoute> routes) {
    assert(routes.isNotEmpty, 'Routes cannot be empty.');
    _defaultRoutes.clear();
    _defaultRoutes.addAll(routes);
    // Notify route change listeners that route has changed.
    onRouteChanged(_defaultRoutes.last);
    notifyListeners();
  }

  void setNamed(List<String> names) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    _defaultRoutes.clear();
    // Map route names to routes.
    _defaultRoutes.addAll(names.map((e) {
      NavigationData? navigationData;
      try {
        navigationData = navigationDataRoutes.firstWhere((element) =>
            ((element.label?.isNotEmpty ?? false) && element.label == e));
      } on StateError {
        // ignore: empty_catches
      }

      if (navigationData == null) {
        throw Exception('`$e` route not found.');
      }

      return DefaultRoute(label: e, path: navigationData.path);
    }));
    // Notify route change listeners that route has changed.
    onRouteChanged(_defaultRoutes.last);
    notifyListeners();
  }

  // Set Backstack

  void setBackstackRoutes(List<DefaultRoute> routes) {
    DefaultRoute currentRoute = _defaultRoutes.last;
    _defaultRoutes.clear();
    _defaultRoutes.addAll(routes);
    _defaultRoutes.add(currentRoute);
  }

  Future<dynamic> pushNamed(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      dynamic data}) async {
    NavigationData? navigationData;
    try {
      navigationData = navigationDataRoutes.firstWhere((element) =>
          ((element.label?.isNotEmpty ?? false) && element.label == name));
    } on StateError {
      // ignore: empty_catches
    }

    if (navigationData == null) {
      throw Exception('`$name` route not found.');
    }

    DefaultRoute route = DefaultRoute(
        label: name,
        path: navigationData.path,
        queryParameters: queryParameters ?? navigationData.queryParameters,
        arguments: arguments,
        data: data);

    // Save global data to name key.
    if (data != null) globalData[name] = data;

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

  Future<dynamic> pushReplacementNamed(String name, [dynamic result]) async {
    pop(result);
    return await pushNamed(name);
  }

  void setQueryParameters(Map<String, String> queryParameters) {
    _defaultRoutes.last = _defaultRoutes.last
        .copyWith(queryParameters: queryParameters) as DefaultRoute;
    notifyListeners();
  }

  // ignore: unused_element
  String _buildQueryParameters(Map<String, String> queryParameters) {
    return queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&')
        .toString();
  }

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

  void _debugPrintMessage(String message) {
    if (debugLog) {
      debugPrint('NavigationUtils: $message');
    }
  }
}
