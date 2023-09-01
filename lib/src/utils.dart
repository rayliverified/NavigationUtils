import 'model_deeplink.dart';
import 'navigation_builder.dart';
import 'navigation_delegate.dart';
import 'path_utils_go_router.dart';

class NavigationUtils {
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
          metadata: navigationData.metadata);
    }

    return routeHolder;
  }

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
          metadata: navigationData.metadata);
    } else {
      return DefaultRoute.fromUrl(name,
          label: navigationData?.label ?? '',
          metadata: navigationData?.metadata);
    }
  }

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

  static String trimRight(String from, String pattern) {
    if (from.isEmpty || pattern.isEmpty || pattern.length > from.length) {
      return from;
    }

    while (from.endsWith(pattern)) {
      from = from.substring(0, from.length - pattern.length);
    }
    return from;
  }

  static DeeplinkDestination? getDeeplinkDestinationFromUrl(
      List<DeeplinkDestination> deeplinkDestinations, String? url) {
    if (url?.isEmpty ?? true) return null;
    return getDeeplinkDestinationFromUri(
        deeplinkDestinations, Uri.tryParse(url!));
  }

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

  static bool canOpenDeeplinkDestination(
      {required Uri? uri,
      required List<DeeplinkDestination> deeplinkDestinations,
      required BaseRouterDelegate routerDelegate,
      DeeplinkDestination? deeplinkDestination,
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
    bool shouldNavigate =
        deeplinkDestinationHolder.shouldNavigateDeeplinkFunction?.call() ??
            true;
    if (shouldNavigate == false) return false;

    return true;
  }

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

    if (canOpenDeeplinkDestination(
            uri: uri,
            deeplinkDestinations: deeplinkDestinations,
            routerDelegate: routerDelegate,
            deeplinkDestination: deeplinkDestinationHolder,
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
    Map<String, String> pathParameters = {};
    Map<String, String> queryParameters = {};
    Object? arguments;
    Map<String, dynamic> globalData = {};

    Map<String, String> deeplinkPathParameters = {};

    if (deeplinkDestinationHolder.deeplinkUrl.contains(':')) {
      String deeplinkPath = canonicalUri(uri.path);
      pathParameters = NavigationUtils.extractPathParametersWithPattern(
          deeplinkPath, deeplinkDestinationHolder.deeplinkUrl);
      deeplinkPathParameters.addAll(pathParameters);
      if (deeplinkDestinationHolder.mapPathParameterFunction != null) {
        pathParameters = deeplinkDestinationHolder.mapPathParameterFunction!(
            pathParameters, uri.queryParameters);
      }
    }

    if (deeplinkDestinationHolder.mapQueryParameterFunction != null) {
      queryParameters = deeplinkDestinationHolder.mapQueryParameterFunction!(
          uri.queryParameters, deeplinkPathParameters);
    } else {
      queryParameters = uri.queryParameters;
    }

    if (deeplinkDestinationHolder.mapArgumentsFunction != null) {
      arguments = deeplinkDestinationHolder.mapArgumentsFunction!(
          deeplinkPathParameters, uri.queryParameters);
    }

    if (deeplinkDestinationHolder.mapGlobalDataFunction != null) {
      globalData = deeplinkDestinationHolder.mapGlobalDataFunction!(
          deeplinkPathParameters, uri.queryParameters);
    }

    // Set deeplink destination.
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

    routerDelegate.apply();

    return true;
  }
}
