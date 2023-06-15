import 'package:flutter/widgets.dart';

import '../navigation_delegate.dart';

abstract class NavigationInterface {
  Future<dynamic> push(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true});

  Future<dynamic> pushRoute(DefaultRoute path, {bool apply = true});

  void pop([dynamic result, bool apply = true]);

  void popUntil(String name, {bool apply = true});

  void popUntilRoute(PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true});

  Future<dynamic> pushAndRemoveUntil(String name, String routeUntilName,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true});

  Future<dynamic> pushAndRemoveUntilRoute(
      DefaultRoute route, PopUntilRouteFunction popUntilRouteFunction,
      {bool apply = true});

  void remove(String name, {bool apply = true});

  void removeRoute(DefaultRoute route, {bool apply = true});

  Future<dynamic> pushReplacement(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      dynamic result,
      bool apply = true});

  Future<dynamic> pushReplacementRoute(DefaultRoute route,
      [dynamic result, bool apply = true]);

  void removeBelow(String name, {bool apply = true});

  void removeRouteBelow(DefaultRoute route, {bool apply = true});

  void replace(String oldName,
      {String? newName,
      DefaultRoute? newRoute,
      Map<String, dynamic>? data,
      bool apply = true});

  void replaceRoute(DefaultRoute oldRoute, DefaultRoute newRoute,
      {bool apply = true});

  void replaceBelow(String anchorName, String name, {bool apply = true});

  void replaceRouteBelow(DefaultRoute anchorRoute, DefaultRoute newRoute,
      {bool apply = true});

  void set(List<String> names, {bool apply = true});

  void setRoutes(List<DefaultRoute> routes, {bool apply = true});

  void setBackstack(List<String> names, {bool apply = true});

  void setBackstackRoutes(List<DefaultRoute> routes, {bool apply = true});

  void setOverride(Widget page, {bool apply = true});

  void removeOverride({bool apply = true});

  void setQueryParameters(Map<String, String> queryParameters,
      {bool apply = true});

  void navigate(BuildContext context, Function function);

  void neglect(BuildContext context, Function function);

  void apply();

  void clear();
}
