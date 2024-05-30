import 'models/model_deeplink.dart';
import 'navigation_builder.dart';
import 'navigation_delegate.dart';
import 'path_utils_go_router.dart';

class NavigationUtils {
  /// Extracts the corresponding `NavigationData` from a given `uri`.
  ///
  /// The method goes through the provided [routes] and attempts to match the [uri]
  /// with each of the [NavigationData] objects in the [routes]. If a match is found,
  /// that [NavigationData] is returned.
  static NavigationData? getNavigationDataFromUri(
      {required List<NavigationData> routes,
      required Uri uri,
      Map<String, dynamic>? globalData}) {
    NavigationData? navigationData;
    try {
      navigationData = routes.firstWhere((element) =>
          Uri(path: element.path, queryParameters: element.queryParameters) ==
          uri);
    } on StateError {
      // ignore: empty_catches
    }

    return navigationData;
  }

  /// A method that retrieves a [NavigationData] object from a given route.
  ///
  /// This method takes into account several routing scenarios such as named routing,
  /// exact URL match routing, exact path match routing, and path pattern matching.
  ///
  /// [routes] is a list of available [NavigationData] for your application.
  /// [route] is the [DefaultRoute] object from which to extract the navigation data.
  ///
  /// Usage:
  /// ```
  /// var navigationData = getNavigationDataFromRoute(routes: routesList, route: defaultRoute);
  /// ```
  ///
  /// Returns a [NavigationData] object if a match is found, or [null] if no matching route is found.
  static NavigationData? getNavigationDataFromRoute(
      {required List<NavigationData> routes, required DefaultRoute route}) {
    NavigationData? navigationData;

    // Named routing.
    try {
      navigationData = routes.firstWhere((element) =>
          ((element.label?.isNotEmpty ?? false) &&
              element.label == route.label));
    } on StateError {
      // ignore: empty_catches
    }

    // Exact URL match routing.
    if (navigationData == null) {
      try {
        navigationData = routes.firstWhere((element) =>
            ((element.uri == route.uri &&
                element.path.isNotEmpty &&
                route.path.isNotEmpty)));
      } on StateError {
        // ignore: empty_catches
      }
    }

    // Exact path match routing.
    if (navigationData == null) {
      try {
        navigationData = routes.firstWhere((element) =>
            ((element.path == route.path &&
                element.path.isNotEmpty &&
                route.path.isNotEmpty)));
      } on StateError {
        // ignore: empty_catches
      }
    }

    // Path pattern matching.
    if (navigationData == null) {
      try {
        navigationData = routes.firstWhere((element) {
          Map<String, String> pathParameters =
              extractPathParametersWithPattern(route.path, element.path);
          return pathParameters.isNotEmpty;
        });
      } on StateError {
        // ignore: empty_catches
      }
    }

    return navigationData;
  }

  /// This function maps a [NavigationData] object to a [DefaultRoute] object.
  ///
  /// It requires:
  ///   [routes] - a list of available [NavigationData] for your application.
  ///   [route] - the [DefaultRoute] object you want to map navigation data to.
  ///   [globalData] - a map of dynamic data that can be used in the mapped routes.
  ///
  /// The method checks if [navigationData] (obtained from [getNavigationDataFromRoute]) is not null,
  /// extracts the path parameters if any, and builds a [DefaultRoute].
  ///
  /// Usage:
  /// ```
  /// var defaultRoute = mapNavigationDataToDefaultRoute(routes: routesList, route: defaultRoute, globalData: myGlobalData);
  /// ```
  static DefaultRoute? mapNavigationDataToDefaultRoute(
      {required List<NavigationData> routes,
      required DefaultRoute route,
      Map<String, dynamic>? globalData}) {
    NavigationData? navigationData =
        getNavigationDataFromRoute(routes: routes, route: route);
    DefaultRoute? routeHolder;

    if (navigationData != null) {
      Map<String, String> pathParameters = {};
      String path = navigationData.path;
      if (navigationData.path.contains(':')) {
        pathParameters =
            extractPathParametersWithPattern(route.path, navigationData.path);
        path = patternToPath(navigationData.path, pathParameters);
      }

      // Build DefaultRoute.
      routeHolder = DefaultRoute(
          label: navigationData.label ?? '',
          path: path,
          pathParameters: pathParameters,
          queryParameters: route.queryParameters,
          group: navigationData.group,
          metadata: navigationData.metadata);
    }

    return routeHolder;
  }

  /// Returns the first [NavigationData] that matches with [name].
  ///
  /// The method iterates through [routes] to find a [NavigationData] where the [name]
  /// matches with [NavigationData.label] or [NavigationData.url] or [NavigationData.path].
  /// It can match with either exact URL or path or with path pattern.
  ///
  /// If [name] does not start with '/', the method assumes it's a label and tries to find a match in [routes].
  ///
  /// If [name] starts with '/', the method tries exact URL match first. If it doesn't find any, it tries
  /// exact path match, then it tries path pattern match.
  ///
  /// The method canonicalizes the URL path before comparing it with [NavigationData.url] and [NavigationData.path].
  ///
  /// Returns the first matching [NavigationData], or null if no match is found.
  static NavigationData? getNavigationDataFromName(
      List<NavigationData> routes, String name) {
    if (name.isEmpty) return null;

    NavigationData? navigationData;
    if (name.startsWith('/') == false) {
      try {
        navigationData = routes.firstWhere((element) =>
            ((element.label?.isNotEmpty ?? false) && element.label == name));
      } on StateError {
        // ignore: empty_catches
      }
    } else {
      String path = canonicalUri(Uri.tryParse(name)?.path ?? '');

      // Exact URL match routing.
      try {
        navigationData = routes.firstWhere((element) => (element.url == name));
      } on StateError {
        // ignore: empty_catches
      }

      // Exact path match routing.
      if (navigationData == null) {
        try {
          navigationData =
              routes.firstWhere((element) => (element.path == path));
        } on StateError {
          // ignore: empty_catches
        }
      }

      // Path pattern matching.
      if (navigationData == null) {
        try {
          navigationData = routes.firstWhere((element) {
            Map<String, String> pathParameters =
                extractPathParametersWithPattern(path, element.path);
            return pathParameters.isNotEmpty;
          });
        } on StateError {
          // ignore: empty_catches
        }
      }
    }

    return navigationData;
  }

  /// Builds and returns a [DefaultRoute] from the given [name] using a list of [NavigationData].
  ///
  /// This method uses [NavigationUtils.getNavigationDataFromName] to search for a matching
  /// [NavigationData] in [navigationDataRoutes] based on [name].
  ///
  /// Returns a [DefaultRoute] constructed from the named route or URL.
  /// Throws an [Exception] if a named route is not found in [navigationDataRoutes].
  static DefaultRoute buildDefaultRouteFromName(
      List<NavigationData> navigationDataRoutes, String name) {
    NavigationData? navigationData =
        NavigationUtils.getNavigationDataFromName(navigationDataRoutes, name);

    // Named route.
    if (name.startsWith('/') == false) {
      if (navigationData == null) {
        throw Exception('`$name` route not found.');
      }

      return DefaultRoute(
          label: navigationData.label ?? '',
          path: navigationData.path,
          group: navigationData.group,
          metadata: navigationData.metadata);
    } else {
      return DefaultRoute.fromUrl(name,
          label: navigationData?.label ?? '',
          group: navigationData?.group,
          metadata: navigationData?.metadata);
    }
  }

  /// Extracts and returns path parameters from the given [route] using the [pattern].
  ///
  /// Returns a [Map] of parameter names and their corresponding values from the route.
  static Map<String, String> extractPathParametersWithPattern(
      String route, String pattern) {
    Map<String, String> pathParameters = {};

    if ((pattern.isNotEmpty && route.isNotEmpty)) {
      if (pattern.contains(':')) {
        final List<String> paramNames = <String>[];
        RegExp regExp = patternToRegExp(pattern, paramNames);
        final String? match = regExp.stringMatch(route);
        if (match == route) {
          final RegExpMatch match = regExp.firstMatch(route)!;
          pathParameters = extractPathParameters(paramNames, match);
          return pathParameters;
        }
      }
    }

    return pathParameters;
  }

  /// Trims all instances of [pattern] from the end of [from].
  ///
  /// This function removes [pattern] from the end of [from] repeatedly until [from] no longer ends with [pattern].
  ///
  /// Returns [from] if it's empty, if [pattern] is empty, or if [pattern] is longer than [from].
  ///
  /// Returns the modified [from] string, without any trailing [pattern].
  static String trimRight(String from, String pattern) {
    if (from.isEmpty || pattern.isEmpty || pattern.length > from.length) {
      return from;
    }

    while (from.endsWith(pattern)) {
      from = from.substring(0, from.length - pattern.length);
    }
    return from;
  }

  /// Gets the `DeeplinkDestination` from an [url].
  static DeeplinkDestination? getDeeplinkDestinationFromUrl(
      List<DeeplinkDestination> deeplinkDestinations, String? url) {
    if (url?.isEmpty ?? true) return null;
    return getDeeplinkDestinationFromUri(
        deeplinkDestinations, Uri.tryParse(url!));
  }

  /// Gets the `DeeplinkDestination` from an [uri].
  ///
  /// The function first attempts to find a direct path match. If no match
  /// is found, it then attempts to match the path pattern.
  static DeeplinkDestination? getDeeplinkDestinationFromUri(
      List<DeeplinkDestination> deeplinkDestinations, Uri? uri) {
    if (uri?.hasEmptyPath ?? true) return null;

    String deeplinkPath = canonicalUri(uri!.path);
    DeeplinkDestination? deeplinkDestination;

    // Exact path match routing.
    try {
      deeplinkDestination = deeplinkDestinations
          .firstWhere((element) => (element.path == deeplinkPath));
    } on StateError {
      // ignore: empty_catches
    }

    // Path pattern matching.
    if (deeplinkDestination == null) {
      try {
        deeplinkDestination = deeplinkDestinations.firstWhere((element) {
          Map<String, String> pathParameters = extractPathParametersWithPattern(
              deeplinkPath, element.deeplinkUrl);
          return pathParameters.isNotEmpty;
        });
      } on StateError {
        // ignore: empty_catches
      }
    }

    return deeplinkDestination;
  }

  /// Determines whether a [DeeplinkDestination] can be opened.
  ///
  /// The method checks various conditions, like whether the URI is null, authentication is needed,
  /// whether navigation from the current page is allowed, etc., and returns true
  /// if the [DeeplinkDestination] can be opened.
  ///
  /// The [uri] parameter is the URI for the deeplink.
  ///
  /// The [deeplinkDestinations] parameter is a list of all available
  /// `DeeplinkDestination` instances.
  ///
  /// The [routerDelegate] parameter is the router delegate currently managing app navigation.
  ///
  /// The [deeplinkDestination] parameter is the specific destination to be checked.
  ///
  /// The [pathParameters] array contains path parameters for the destination.
  ///
  /// The [authenticated] boolean indicates if the user is authenticated or not.
  ///
  /// The [currentRoute] is the currently active route.
  ///
  /// The [excludeDeeplinkNavigationPages] list contains names of routes from which deeplink
  /// navigation is not allowed.
  static bool canOpenDeeplinkDestination(
      {required Uri? uri,
      required List<DeeplinkDestination> deeplinkDestinations,
      required BaseRouterDelegate routerDelegate,
      DeeplinkDestination? deeplinkDestination,
      Map<String, String> pathParameters = const {},
      bool authenticated = true,
      DefaultRoute? currentRoute,
      List<String> excludeDeeplinkNavigationPages = const []}) {
    if (uri == null) return false;

    DeeplinkDestination? deeplinkDestinationHolder = deeplinkDestination ??=
        NavigationUtils.getDeeplinkDestinationFromUri(
            deeplinkDestinations, uri);

    if (deeplinkDestinationHolder == null) return false;

    // Check if authentication is needed to navigate to deeplink.
    if (deeplinkDestinationHolder.authenticationRequired) {
      if (authenticated == false) {
        return false;
      }
    }

    // Check if user can navigate from the current page they are on.
    // Do not navigate globally if user is on these pages.
    if (excludeDeeplinkNavigationPages.contains(currentRoute?.label) ||
        excludeDeeplinkNavigationPages.contains(currentRoute?.path)) {
      return false;
    }
    // Do not navigate to destination if current page is in deny list.
    if (deeplinkDestinationHolder.excludeDeeplinkNavigationPages
            .contains(currentRoute?.label) ||
        deeplinkDestinationHolder.excludeDeeplinkNavigationPages
            .contains(currentRoute?.path)) {
      return false;
    }

    // Check deeplink navigation conditional function.
    bool shouldNavigate = deeplinkDestinationHolder
            .shouldNavigateDeeplinkFunction
            ?.call(uri, pathParameters, uri.queryParameters) ??
        true;
    if (shouldNavigate == false) return false;

    return true;
  }

  /// Opens a deeplink destination if conditions are met.
  ///
  /// The function is responsible for determining if a [DeeplinkDestination] can be opened (using the [canOpenDeeplinkDestination] function) and if so, it performs the necessary navigation.
  ///
  /// The [uri] parameter contains the URI for the deeplink.
  ///
  /// The [deeplinkDestinations] parameter contains a list of all available [DeeplinkDestination] instances.
  ///
  /// The [routerDelegate] parameter represents the router delegate currently handling app navigation.
  ///
  /// The [deeplinkDestination] parameter is the [DeeplinkDestination] object to be opened.
  ///
  /// The [authenticated] parameter specifies if the user is authenticated or not.
  ///
  /// The [currentRoute] parameter identifies the currently active route.
  ///
  /// The [excludeDeeplinkNavigationPages] parameter holds a list of routes from which deeplink navigation is not permitted.
  ///
  /// If [push] is `true`, the destination is pushed onto the navigation stack.
  ///
  /// Each deeplink destination may have associated path parameters, query parameters, and navigation rules - the method is responsible for processing all this contextual information to determine the final navigation action.
  static bool openDeeplinkDestination(
      {required Uri? uri,
      required List<DeeplinkDestination> deeplinkDestinations,
      required BaseRouterDelegate routerDelegate,
      DeeplinkDestination? deeplinkDestination,
      bool authenticated = true,
      DefaultRoute? currentRoute,
      List<String> excludeDeeplinkNavigationPages = const [],
      bool push = false}) {
    if (uri == null) return false;

    DeeplinkDestination? deeplinkDestinationHolder = deeplinkDestination ??=
        NavigationUtils.getDeeplinkDestinationFromUri(
            deeplinkDestinations, uri);

    if (deeplinkDestinationHolder == null) return false;

    Map<String, String> pathParameters = {};
    if (deeplinkDestinationHolder.deeplinkUrl.contains(':')) {
      String deeplinkPath = canonicalUri(uri.path);
      pathParameters = NavigationUtils.extractPathParametersWithPattern(
          deeplinkPath, deeplinkDestinationHolder.deeplinkUrl);
    }

    if (canOpenDeeplinkDestination(
            uri: uri,
            deeplinkDestinations: deeplinkDestinations,
            routerDelegate: routerDelegate,
            deeplinkDestination: deeplinkDestinationHolder,
            pathParameters: pathParameters,
            authenticated: authenticated,
            currentRoute: currentRoute,
            excludeDeeplinkNavigationPages: excludeDeeplinkNavigationPages) ==
        false) return false;

    // Set backstack. If pushOverride is true, skip backstack behavior.
    if (push == false) {
      if (deeplinkDestinationHolder.backstack != null) {
        if (deeplinkDestinationHolder.backstack!.isEmpty) {
          routerDelegate.clear();
        } else {
          routerDelegate.set(deeplinkDestinationHolder.backstack!,
              apply: false);
        }
      } else if (deeplinkDestinationHolder.backstackRoutes != null) {
        if (deeplinkDestinationHolder.backstackRoutes!.isEmpty) {
          routerDelegate.clear();
        } else {
          routerDelegate.setRoutes(deeplinkDestinationHolder.backstackRoutes!,
              apply: false);
        }
      }
    }

    // Process deeplink path parameters.
    // Process deeplink query parameters.
    Map<String, String> queryParameters = {};
    Object? arguments;
    Map<String, dynamic> globalData = {};

    if (deeplinkDestinationHolder.mapQueryParameterFunction != null) {
      queryParameters = deeplinkDestinationHolder.mapQueryParameterFunction!(
          uri.queryParameters, pathParameters);
    } else {
      queryParameters = uri.queryParameters;
    }

    if (deeplinkDestinationHolder.mapArgumentsFunction != null) {
      arguments = deeplinkDestinationHolder.mapArgumentsFunction!(
          pathParameters, uri.queryParameters);
    }

    if (deeplinkDestinationHolder.mapGlobalDataFunction != null) {
      globalData = deeplinkDestinationHolder.mapGlobalDataFunction!(
          pathParameters, uri.queryParameters);
    }

    // Deeplink Path parameter function needs to be placed last so the path parameters
    // can be passed to above functions without being transformed.
    if (deeplinkDestinationHolder.mapPathParameterFunction != null) {
      pathParameters = deeplinkDestinationHolder.mapPathParameterFunction!(
          pathParameters, uri.queryParameters);
    }

    // Default set deeplink navigation function. Skipped if redirect is provided.
    navigateFunctionHolder() {
      if (deeplinkDestinationHolder.destinationLabel.isNotEmpty) {
        routerDelegate.push(deeplinkDestinationHolder.destinationLabel,
            pathParameters: pathParameters,
            queryParameters: queryParameters,
            data: globalData,
            arguments: arguments,
            apply: false);
      } else if (deeplinkDestinationHolder.destinationUrl.isNotEmpty) {
        routerDelegate.push(deeplinkDestinationHolder.destinationUrl,
            pathParameters: pathParameters,
            queryParameters: queryParameters,
            data: globalData,
            arguments: arguments,
            apply: false);
      }
    }

    // Set deeplink destination.
    if (deeplinkDestinationHolder.redirectFunction != null) {
      deeplinkDestinationHolder.redirectFunction!
              (pathParameters, queryParameters, (
                  {String? label,
                  String? url,
                  Map<String, String>? pathParameters,
                  Map<String, String>? queryParameters,
                  Map<String, dynamic>? globalData,
                  Object? arguments}) {
        if (label?.isNotEmpty ?? false) {
          routerDelegate.push(label!,
              pathParameters: pathParameters ?? {},
              queryParameters: queryParameters,
              data: globalData ?? {},
              arguments: arguments,
              apply: false);
        } else if (url?.isNotEmpty ?? false) {
          routerDelegate.push(url!,
              pathParameters: pathParameters ?? {},
              queryParameters: queryParameters,
              data: globalData ?? {},
              arguments: arguments,
              apply: false);
        }
        routerDelegate.apply();
      })
          .then((value) {
        if (value == false) {
          navigateFunctionHolder();
          routerDelegate.apply();
        }
      });

      return true;
    } else {
      navigateFunctionHolder();
      routerDelegate.apply();
    }

    return true;
  }
}
