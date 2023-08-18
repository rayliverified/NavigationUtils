import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'navigation_delegate.dart';

/// The RouteInformationParser takes the RouteInformation
/// from a RouteInformationProvider and parses it into a user-defined data type.
class DefaultRouteInformationParser
    extends RouteInformationParser<DefaultRoute> {
  Uri routeUri = Uri(path: '/');
  String initialRoute = '/';
  bool initialized = false;

  DefaultRoute? initialRouteData;

  DefaultRouteInformationParser({this.initialRouteData});

  @override
  Future<DefaultRoute> parseRouteInformation(
      RouteInformation routeInformation) {
    // Parse URL into URI.
    routeUri = routeInformation.uri;
    // Save initial URL.
    if (initialized == false) {
      initialized = true;
      initialRoute = routeInformation.uri.path;
      // Save initial route and handle after initialization.
      return SynchronousFuture(initialRouteData ?? DefaultRoute(path: '/'));
    }

    return SynchronousFuture(DefaultRoute(
        path: routeUri.path, queryParameters: routeUri.queryParameters));
  }

  @override
  RouteInformation? restoreRouteInformation(DefaultRoute configuration) {
    if (configuration.name?.isNotEmpty ?? false) {
      return RouteInformation(
          uri: configuration.uri, state: configuration.arguments);
    }

    return null;
  }
}
