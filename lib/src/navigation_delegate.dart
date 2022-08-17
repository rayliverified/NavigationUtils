import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

class MainRoute extends RouteSettings {
  final String label;
  final String path;
  final Map<String, String> queryParameters;
  final dynamic data;

  MainRoute(
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
    return MainRoute(
      label: label ?? this.label,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      arguments: arguments ?? this.arguments,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MainRoute &&
      ((other.label.isNotEmpty && other.label == label) ||
          (other.path == path && other.path.isNotEmpty && path.isNotEmpty));

  @override
  int get hashCode => label.hashCode * path.hashCode;

  @override
  String toString() => 'Route(label: $label, path: $path)';

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
typedef PopUntilRoute = bool Function(MainRoute route);

/// The RouteDelegate defines application specific behaviors of how the router
/// learns about changes in the application state and how it responds to them.
/// It listens to the RouteInformation Parser and the app state and builds the Navigator with
/// the current list of pages (immutable object used to set navigator's history stack).
abstract class MainRouterDelegate extends RouterDelegate<MainRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<MainRoute> {
  // Persist the navigator with a global key.
  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Internal backstack and pages representation.
  List<MainRoute> _mainRoutes = [];

  List<MainRoute> get mainRoutes => _mainRoutes;

  bool _canPop = true;

  bool get canPop {
    if (_canPop == false) return false;

    return _mainRoutes.isNotEmpty;
  }

  set canPop(bool canPop) => _canPop = canPop;

  /// CurrentConfiguration detects changes in the route information
  /// It helps complete the browser history and enables browser back and forward buttons.
  @override
  MainRoute? get currentConfiguration =>
      mainRoutes.isNotEmpty ? mainRoutes.last : null;

  // Current route name.
  StreamController<MainRoute> currentRouteController =
      StreamController<MainRoute>.broadcast();
  Stream<MainRoute> get getCurrentRoute => currentRouteController.stream;

  Map<String, dynamic> globalData = {};

  /// Internal method that takes a Navigator initial route
  /// and maps to a list of routes.
  ///
  /// Do not call this function directly.
  @override
  @protected
  Future<void> setInitialRoutePath(MainRoute configuration) {
    return setNewRoutePath(configuration);
  }

  /// Exposed method for setting the navigation stack
  /// given a new [configuration] path.
  ///
  /// Do not call this function directly.
  @override
  @protected
  Future<void> setNewRoutePath(MainRoute configuration) async {
    // Do not set empty route.
    if (configuration.label.isEmpty && configuration.path.isEmpty) return;
    // Handle InitialRoutePath logic here. Adding a page here ensures
    // there is always a page to display. The initial page is now set here
    // instead of in the Navigator widget.
    if (_mainRoutes.isEmpty) {
      _mainRoutes.add(configuration);
      return;
    }

    if (_canPop == false) return;

    bool didChangeRoute = currentConfiguration != configuration;
    debugPrint('Main Routes: $mainRoutes');
    _mainRoutes = _setNewRouteHistory(_mainRoutes, configuration);
    // User can customize returned routes with this exposed callback.
    _mainRoutes = setMainRoutes(_mainRoutes) ?? _mainRoutes;
    // Expose that the route has changed.
    if (didChangeRoute) onRouteChanged(_mainRoutes.last);
    debugPrint('Main Routes Updated: $mainRoutes');
    notifyListeners();
    return;
  }

  @override
  Future<bool> popRoute() {
    debugPrint('Pop Route');
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
  List<MainRoute> _setNewRouteHistory(
      List<MainRoute> routes, MainRoute newRoute) {
    List<MainRoute> pathsHolder = [];
    pathsHolder.addAll(routes);
    // Check if new path exists in history.
    for (MainRoute path in routes) {
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
  List<MainRoute>? setMainRoutes(List<MainRoute> routes) => routes;

  /// Exposes a callback for when the route changes.
  void onRouteChanged(MainRoute route) {
    currentRouteController.add(route);
  }

  /// A Completer to help return results from a popped route.
  final LinkedHashMap<MainRoute, Completer<dynamic>> _pageCompleters =
      LinkedHashMap();

  Future<dynamic> push(MainRoute path) async {
    if (_mainRoutes.contains(path)) return;
    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[path] = pageCompleter;
    _mainRoutes.add(path);
    notifyListeners();
    return pageCompleter.future;
  }

  void pop([dynamic result]) {
    if (canPop) {
      if (_pageCompleters.containsKey(mainRoutes.last)) {
        _pageCompleters[mainRoutes.last]!.complete(result);
        _pageCompleters.remove(mainRoutes.last);
      }
      _mainRoutes.removeLast();
      notifyListeners();
    }
  }

  void popUntil(PopUntilRoute popUntilRoute) {
    MainRoute? pathEntry = _mainRoutes.isNotEmpty ? _mainRoutes.last : null;
    while (pathEntry != null) {
      if (popUntilRoute(pathEntry)) break;
      pop();
      pathEntry = _mainRoutes.isNotEmpty ? _mainRoutes.last : null;
    }
    notifyListeners();
  }

  Future<dynamic> pushAndRemoveUntil(
      MainRoute route, PopUntilRoute popUntilRoute) async {
    popUntil(popUntilRoute);
    _mainRoutes.add(route);
    notifyListeners();
  }

  void removeRoute(MainRoute route) {
    if (_mainRoutes.contains(route)) {
      _mainRoutes.remove(route);
      notifyListeners();
    }
  }

  Future<dynamic> pushReplacement(MainRoute route, [dynamic result]) async {
    pop(result);
    return await push(route);
  }

  void removeRouteBelow(MainRoute route) {
    int anchorIndex = _mainRoutes.indexOf(route);
    if (anchorIndex >= 1) {
      _mainRoutes.removeAt(anchorIndex - 1);
      notifyListeners();
    }
  }

  void replace(MainRoute oldRoute, MainRoute newRoute) {
    int index = _mainRoutes.indexOf(oldRoute);
    if (index != -1) {
      _mainRoutes[index] = newRoute;
      notifyListeners();
    }
  }

  void replaceRouteBelow(MainRoute anchorRoute, MainRoute newRoute) {
    int index = _mainRoutes.indexOf(anchorRoute);
    if (index >= 1) {
      _mainRoutes[index - 1] = newRoute;
      notifyListeners();
    }
  }

  void set(List<MainRoute> routes) {
    assert(routes.isNotEmpty, 'Routes cannot be empty.');
    _mainRoutes.clear();
    _mainRoutes.addAll(routes);
    notifyListeners();
  }

  void setBackstack(List<MainRoute> routes) {
    MainRoute currentRoute = _mainRoutes.last;
    _mainRoutes.clear();
    _mainRoutes.addAll(routes);
    _mainRoutes.add(currentRoute);
  }

  void setNamed(List<String> names) {
    assert(names.isNotEmpty, 'Names cannot be empty.');
    _mainRoutes.clear();
    _mainRoutes.addAll(names.map((e) => MainRoute(label: e)));
    print('Main Routes: $mainRoutes');
    notifyListeners();
  }

  Future<dynamic> pushNamed(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      dynamic data}) async {
    MainRoute route = MainRoute(
        label: name,
        queryParameters: queryParameters ?? {},
        arguments: arguments,
        data: data);

    if (_mainRoutes.contains(route)) return;

    // Save global data to name key.
    // TODO: Potentially support duplicate pages with different data.
    if (data != null) globalData[name] = data;

    Completer<dynamic> pageCompleter = Completer<dynamic>();
    _pageCompleters[route] = pageCompleter;
    _mainRoutes.add(route);
    notifyListeners();
    return pageCompleter.future;
  }

  Future<dynamic> pushReplacementNamed(String name, [dynamic result]) async {
    pop(result);
    return await pushNamed(name);
  }

  void setQueryParameters(Map<String, String> queryParameters) {
    String path =
        '${_mainRoutes.last.uri.path}?${_buildQueryParameters(queryParameters)}';
    _mainRoutes.last = _mainRoutes.last
        .copyWith(queryParameters: queryParameters) as MainRoute;
    print('Page Name: $path, Last: ${_mainRoutes.last}');
    notifyListeners();
  }

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
}
