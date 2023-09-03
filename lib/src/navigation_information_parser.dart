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

  DefaultRoute? defaultRoute;
  String? defaultRoutePath;
  DefaultRoute Function(Uri initialRoute)? setInitialRouteFunction;
  String Function(Uri initialRoute)? setInitialRoutePathFunction;

  bool debugLog;

  DefaultRouteInformationParser({
    this.defaultRoute,
    this.defaultRoutePath,
    this.setInitialRouteFunction,
    this.setInitialRoutePathFunction,
    this.debugLog = false,
  }) : assert(
            defaultRoutePath != null
                ? (defaultRoutePath.isNotEmpty &&
                    defaultRoutePath.startsWith('/'))
                : true,
            'Route Path must start with /');

  @override
  Future<DefaultRoute> parseRouteInformation(
      RouteInformation routeInformation) {
    _debugPrintMessage('parseRouteInformation - $routeInformation');
    // Parse URL into URI.
    routeUri = routeInformation.uri;
    // Save initial URL.
    if (initialized == false) {
      initialized = true;
      initialRoute = routeInformation.uri.toString();

      DefaultRoute? defaultRouteHolder;
      if (defaultRoute != null) {
        defaultRouteHolder = defaultRoute;
      } else if (defaultRoutePath != null) {
        defaultRouteHolder = DefaultRoute.fromUrl(defaultRoutePath!);
      }

      if (setInitialRouteFunction != null) {
        defaultRouteHolder = setInitialRouteFunction!(routeUri);
      } else if (setInitialRoutePathFunction != null) {
        String routeUrl = setInitialRoutePathFunction!(routeUri);
        defaultRouteHolder = DefaultRoute.fromUrl(routeUrl);
      }

      defaultRouteHolder ??= DefaultRoute(path: '/');

      _debugPrintMessage(
          'parseRouteInformation, defaultRouteHolder - $defaultRouteHolder');

      // Save initial route and handle after initialization.
      return SynchronousFuture(defaultRouteHolder);
    }

    return SynchronousFuture(DefaultRoute(
        path: routeUri.path, queryParameters: routeUri.queryParameters));
  }

  @override
  RouteInformation? restoreRouteInformation(DefaultRoute configuration) {
    _debugPrintMessage('restoreRouteInformation - $configuration');
    if (configuration.name?.isNotEmpty ?? false) {
      return RouteInformation(
          uri: configuration.uri, state: configuration.arguments);
    }

    return null;
  }

  void _debugPrintMessage(String message) {
    if (debugLog) {
      debugPrint('NavigationUtils: $message');
    }
  }
}
