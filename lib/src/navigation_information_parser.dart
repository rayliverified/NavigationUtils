import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'navigation_delegate.dart';

/// The RouteInformationParser takes the RouteInformation
/// from a RouteInformationProvider and parses it into a user-defined data type.
class DefaultRouteInformationParser
    extends RouteInformationParser<DefaultRoute> {
  Uri routeUri = Uri();
  Uri initialRouteUri = Uri();
  bool initialized = false;

  DefaultRoute? initialRouteData;

  DefaultRouteInformationParser({this.initialRouteData});

  @override
  Future<DefaultRoute> parseRouteInformation(
      RouteInformation routeInformation) {
    // Parse URL into URI.
    try {
      routeUri = Uri.parse(routeInformation.location ?? '');
    } on FormatException catch (e) {
      debugPrint(e.toString());
      routeUri = Uri();
    }
    // Save initial URL.
    if (initialized == false) {
      initialized = true;
      initialRouteUri = routeUri;
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
          location: configuration.name, state: configuration.arguments);
    }

    return null;
  }
}
