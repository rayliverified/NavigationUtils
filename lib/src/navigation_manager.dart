import 'package:flutter/widgets.dart';
import 'package:navigation_utils/src/models/navigation_interface.dart';

import 'navigation_delegate.dart';
import 'navigation_information_parser.dart';

class NavigationManager implements NavigationInterface {
  static const String instanceName = 'NavigationManager';

  static NavigationManager? _instance;

  static NavigationManager get instance {
    if (_instance == null) {
      throw Exception(
          'NavigationManager has not been initialized. Call `init()` to initialize before using.');
    }
    return _instance!;
  }

  final BaseRouterDelegate routerDelegate;
  final DefaultRouteInformationParser routeInformationParser;

  NavigationManager._(this.routerDelegate, this.routeInformationParser);

  static NavigationManager init(
      {required BaseRouterDelegate mainRouterDelegate,
        required DefaultRouteInformationParser routeInformationParser}) {
    _instance = NavigationManager._(mainRouterDelegate, routeInformationParser);
    return _instance!;
  }

  DefaultRoute? get currentRoute => routerDelegate.currentConfiguration;
  set setMainRoutes(SetMainRoutesCallback? setMainRoutes) => routerDelegate.setMainRoutes;

  @override
  Future<dynamic> push(String name,
      {Map<String, String>? queryParameters,
        Object? arguments,
        Map<String, dynamic> data = const {},
        Map<String, String> pathParameters = const {},
        bool apply = true}) {
    return routerDelegate.push(name,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        apply: apply);
  }

  @override
  Future<dynamic> pushRoute(DefaultRoute path, {bool apply = true}) {
    return routerDelegate.pushRoute(path, apply: apply);
  }

  @override
  void pop([dynamic result, bool apply = true]) {
    routerDelegate.pop(result, apply);
  }

  @override
  void popUntil(String name, {bool apply = true}) {
    routerDelegate.popUntil(name, apply: apply);
  }

  @override
  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true}) {
    routerDelegate.popUntilRoute(popUntilRouteFunction, apply: apply);
  }

  @override
  Future<dynamic> pushAndRemoveUntil(String name, String routeUntilName,
      {Map<String, String>? queryParameters,
        Object? arguments,
        Map<String, dynamic> data = const {},
        Map<String, String> pathParameters = const {},
        bool apply = true}) {
    return routerDelegate.pushAndRemoveUntil(name, routeUntilName,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        apply: apply);
  }

  @override
  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true}) {
    return routerDelegate.pushAndRemoveUntilRoute(route, popUntilRouteFunction,
        apply: apply);
  }

  @override
  void remove(String name, {bool apply = true}) {
    routerDelegate.remove(name, apply: apply);
  }

  @override
  void removeRoute(DefaultRoute route, {bool apply = true}) {
    routerDelegate.removeRoute(route, apply: apply);
  }

  @override
  Future<dynamic> pushReplacement(String name,
      {Map<String, String>? queryParameters,
        Object? arguments,
        Map<String, dynamic> data = const {},
        Map<String, String> pathParameters = const {},
        dynamic result,
        bool apply = true}) {
    return routerDelegate.pushReplacement(name,
        queryParameters: queryParameters,
        arguments: arguments,
        data: data,
        pathParameters: pathParameters,
        result: result,
        apply: apply);
  }

  @override
  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result, bool apply = true]) {
    return routerDelegate.pushReplacementRoute(route, result, apply);
  }

  @override
  void removeBelow(String name, {bool apply = true}) {
    routerDelegate.removeBelow(name, apply: apply);
  }

  @override
  void removeRouteBelow(DefaultRoute route, {bool apply = true}) {
    routerDelegate.removeRouteBelow(route, apply: apply);
  }

  @override
  void replace(String oldName,
      {String? newName,
        DefaultRoute? newRoute,
        Map<String, dynamic>? data,
        bool apply = true}) {
    routerDelegate.replace(oldName,
        newName: newName, newRoute: newRoute, data: data, apply: apply);
  }

  @override
  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute,
      {bool apply = true}) {
    routerDelegate.replaceRoute(oldRoute, newRoute, apply: apply);
  }

  @override
  void replaceBelow(String anchorName, String name, {bool apply = true}) {
    routerDelegate.replaceBelow(anchorName, name, apply: apply);
  }

  @override
  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute,
      {bool apply = true}) {
    routerDelegate.replaceRouteBelow(anchorRoute, newRoute, apply: apply);
  }

  @override
  void set(List<String> names, {bool apply = true}) {
    routerDelegate.set(names, apply: apply);
  }

  @override
  void setRoutes(List<DefaultRoute> routes, {bool apply = true}) {
    routerDelegate.setRoutes(routes, apply: apply);
  }

  @override
  void setBackstack(List<String> names, {bool apply = true}) {
    routerDelegate.setBackstack(names, apply: apply);
  }

  @override
  void setBackstackRoutes(List<DefaultRoute> routes, {bool apply = true}) {
    routerDelegate.setBackstackRoutes(routes, apply: apply);
  }

  @override
  void setOverride(Widget page, {bool apply = true}) {
    routerDelegate.setOverride(page, apply: apply);
  }

  @override
  void removeOverride({bool apply = true}) {
    routerDelegate.removeOverride(apply: apply);
  }

  @override
  void setQueryParameters(Map<String, String> queryParameters,
      {bool apply = true}) {
    routerDelegate.setQueryParameters(queryParameters, apply: apply);
  }

  @override
  void navigate(BuildContext context, Function function) {
    routerDelegate.navigate(context, function);
  }

  @override
  void neglect(BuildContext context, Function function) {
    routerDelegate.neglect(context, function);
  }

  @override
  void apply() {
    routerDelegate.apply();
  }

  @override
  void clear() {
    routerDelegate.clear();
  }
}
