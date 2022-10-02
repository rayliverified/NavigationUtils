import 'package:navigation_utils/navigation_utils.dart';

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
      if (navigationData == null) {
        try {
          navigationData =
              routes.firstWhere((element) => (element.url == name));
        } on StateError {
          // ignore: empty_catches
        }
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
}
