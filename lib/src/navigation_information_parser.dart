import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'navigation_delegate.dart';

/// The RouteInformationParser takes the RouteInformation
/// from a RouteInformationProvider and parses it into a user-defined data type.
///
/// This implementation parses route information into [DefaultRoute] objects.
class DefaultRouteInformationParser
    extends RouteInformationParser<DefaultRoute> {
  /// The current route URI.
  Uri routeUri = Uri(path: '/');

  /// The initial route path.
  String initialRoute = '/';

  /// Whether the parser has been initialized.
  bool initialized = false;

  /// Optional default route to use on initialization.
  DefaultRoute? defaultRoute;

  /// Optional default route path to use on initialization.
  String? defaultRoutePath;

  /// Optional function to set the initial route from a URI.
  DefaultRoute Function(Uri initialRoute)? setInitialRouteFunction;

  /// Optional function to set the initial route path from a URI.
  String Function(Uri initialRoute)? setInitialRoutePathFunction;

  /// Whether to enable debug logging.
  bool debugLog;

  /// Creates a [DefaultRouteInformationParser] with the given configuration.
  ///
  /// [defaultRoute] - Optional default route to use on initialization.
  /// [defaultRoutePath] - Optional default route path (must start with '/').
  /// [setInitialRouteFunction] - Optional function to set initial route from URI.
  /// [setInitialRoutePathFunction] - Optional function to set initial route path from URI.
  /// [debugLog] - Whether to enable debug logging.
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
    _debugPrintMessage('parseRouteInformation: ${routeInformation.uri}');
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

      defaultRouteHolder ??= DefaultRoute.fromUri(routeUri);

      _debugPrintMessage(
          'parseRouteInformation: defaultRouteHolder: $defaultRouteHolder');

      // Save initial route and handle after initialization.
      return SynchronousFuture(defaultRouteHolder);
    }

    return SynchronousFuture(DefaultRoute(
        path: routeUri.path, queryParameters: routeUri.queryParameters));
  }

  @override
  RouteInformation? restoreRouteInformation(DefaultRoute configuration) {
    _debugPrintMessage('restoreRouteInformation: $configuration');
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
