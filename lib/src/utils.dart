// ignore_for_file: avoid_classes_with_only_static_members

import 'package:navigation_utils/navigation_utils.dart';

/// String utility functions.
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Utility functions for canonicalizing URIs (paths/urls).
String canonicalUri(String uri) {
  if (uri.isEmpty) return '';

  /// Trim leading and trailing slashes.
  if (uri.startsWith('/')) {
    uri = uri.substring(1);
  }
  if (uri.endsWith('/')) {
    uri = uri.substring(0, uri.length - 1);
  }
  return uri;
}

/// An easy-to-use, extendable, maintainable, and scalable navigation utility
/// for Flutter web and mobile.
///
/// This class offers an opinionated and structured solution for managing
/// navigation for Flutter applications. It includes utility functions to
/// improve route navigation and deeplink handling. In addition, it provides
/// conditional navigation support, parameterized routing, redirection, global
/// navigation data, and customizable backstack support for deeplinks.
class NavigationUtils {
  /// Finds a [NavigationData] object from a label or url.
  ///
  /// If the navigation data cannot be found, this returns `null`.
  static NavigationData? getNavigationDataFromLabel(
      List<NavigationData> navigationDataRoutes, String label) {
    for (NavigationData navigationData in navigationDataRoutes) {
      if (navigationData.label == label) {
        return navigationData;
      }
    }
    return null;
  }

  /// Finds a [NavigationData] object from a name (label or url).
  ///
  /// If the navigation data cannot be found, this returns `null`.
  static NavigationData? getNavigationDataFromName(
      List<NavigationData> navigationDataRoutes, String name) {
    // Check if there is an exact match (label or path).
    for (NavigationData navigationData in navigationDataRoutes) {
      if (navigationData.label == name) {
        return navigationData;
      }
    }
    for (NavigationData navigationData in navigationDataRoutes) {
      if (navigationData.path == name) {
        return navigationData;
      }
    }
    // Check if there is a pattern match (path parameters).
    for (NavigationData navigationData in navigationDataRoutes) {
      if (navigationData.path.contains(':')) {
        if (matchesPattern(name, navigationData.path)) {
          return navigationData;
        }
      }
    }
    return null;
  }

  /// Finds a [NavigationData] object from a url.
  ///
  /// If the navigation data cannot be found, this returns `null`.
  static NavigationData? getNavigationDataFromPath(
      List<NavigationData> navigationDataRoutes, String path) {
    // Check if there is an exact match (path).
    for (NavigationData navigationData in navigationDataRoutes) {
      if (navigationData.path == path) {
        return navigationData;
      }
    }
    // Check if there is a pattern match (path parameters).
    for (NavigationData navigationData in navigationDataRoutes) {
      if (navigationData.path.contains(':')) {
        if (matchesPattern(path, navigationData.path)) {
          return navigationData;
        }
      }
    }
    return null;
  }

  /// Checks if a given [path] matches the [pattern].
  ///
  /// Example: matchesPattern('/user/123', '/user/:id') returns true.
  static bool matchesPattern(String path, String pattern) {
    // Canonicalize both path and pattern.
    path = canonicalUri(path);
    pattern = canonicalUri(pattern);
    List<String> pathSegments = path.split('/');
    List<String> patternSegments = pattern.split('/');

    if (pathSegments.length != patternSegments.length) return false;

    for (int i = 0; i < patternSegments.length; i++) {
      if (patternSegments[i].startsWith(':')) continue;
      if (patternSegments[i] != pathSegments[i]) return false;
    }
    return true;
  }

  /// Extracts path parameters from a [path] given a [pattern].
  ///
  /// Example: extractPathParametersWithPattern('/user/123', '/user/:id')
  /// returns {'id': '123'}.
  static Map<String, String> extractPathParametersWithPattern(
      String path, String pattern) {
    // Canonicalize both path and pattern.
    path = canonicalUri(path);
    pattern = canonicalUri(pattern);
    Map<String, String> parameters = {};
    List<String> pathSegments = path.split('/');
    List<String> patternSegments = pattern.split('/');

    if (pathSegments.length != patternSegments.length) return parameters;

    for (int i = 0; i < patternSegments.length; i++) {
      if (patternSegments[i].startsWith(':')) {
        String key = patternSegments[i].substring(1);
        parameters[key] = pathSegments[i];
      }
    }
    return parameters;
  }

  /// Checks whether a deeplink destination can be opened, or if
  /// navigation should be blocked.
  ///
  /// The function evaluates several conditions: whether the given
  /// [deeplinkDestination] exists, whether the user is [authenticated] (if
  /// authentication is required), whether the current route is in the
  /// deny-list ([excludeDeeplinkNavigationPages]), and whether any custom
  /// [shouldNavigateDeeplinkFunction] allows navigation.
  ///
  /// The [uri] parameter contains the URI for the deeplink.
  ///
  /// The [deeplinkDestinations] parameter contains a list of all available [DeeplinkDestination] instances.
  ///
  /// The [routerDelegate] parameter is the router delegate managing app navigation.
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

    // Check if we can navigate to the destination.
    bool canNavigate = canOpenDeeplinkDestination(
        uri: uri,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: routerDelegate,
        deeplinkDestination: deeplinkDestinationHolder,
        pathParameters: pathParameters,
        authenticated: authenticated,
        currentRoute: currentRoute,
        excludeDeeplinkNavigationPages: excludeDeeplinkNavigationPages);

    // Always run the runFunction regardless of whether navigation happens.
    // Store this in a variable to execute it at the end.
    void executeRunFunction() {
      if (deeplinkDestinationHolder.runFunction != null) {
        deeplinkDestinationHolder.runFunction!(pathParameters, queryParameters);
      }
    }

    // If we cannot navigate, call runFunction and return early.
    if (canNavigate == false) {
      executeRunFunction();
      return false;
    }

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

        // Call runFunction after redirect completes
        executeRunFunction();
      })
          .then((value) {
        if (value == false) {
          navigateFunctionHolder();
          routerDelegate.apply();
          // Call runFunction after navigation completes
          executeRunFunction();
        }
      });

      return true;
    } else {
      navigateFunctionHolder();
      routerDelegate.apply();
      // Call runFunction after navigation completes
      executeRunFunction();
    }

    return true;
  }

  /// Gets the [DeeplinkDestination] from a deeplink url string.
  ///
  /// If no matching destination is found, this returns `null`.
  static DeeplinkDestination? getDeeplinkDestinationFromUrl(
      List<DeeplinkDestination> deeplinkDestinations, String? url) {
    if (url == null || url.isEmpty) return null;

    url = canonicalUri(url);

    for (DeeplinkDestination destination in deeplinkDestinations) {
      String destinationUrl = canonicalUri(destination.deeplinkUrl);

      // Check for exact match.
      if (destinationUrl == url) {
        return destination;
      }

      // Check for pattern match (path parameters).
      if (destinationUrl.contains(':')) {
        if (matchesPattern(url, destinationUrl)) {
          return destination;
        }
      }
    }
    return null;
  }

  /// Gets the [DeeplinkDestination] from a deeplink [Uri].
  ///
  /// If no matching destination is found, this returns `null`.
  static DeeplinkDestination? getDeeplinkDestinationFromUri(
      List<DeeplinkDestination> deeplinkDestinations, Uri? uri) {
    if (uri == null) return null;
    return getDeeplinkDestinationFromUrl(deeplinkDestinations, uri.path);
  }
}
