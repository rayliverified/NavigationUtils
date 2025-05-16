import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'navigation_delegate.dart';
import 'path_utils_go_router.dart';
import 'route_builders/transparent_route.dart';
import 'utils.dart';

typedef NavigationPageFactory = Widget Function(BuildContext context,
    DefaultRoute routeData, Map<String, dynamic> globalData);

typedef OnUnknownRoute = Page Function(DefaultRoute route);

typedef CustomPageBuilder = Page Function(
  ValueKey<String>? key,
  String? name,
  Widget child,
  DefaultRoute routeData,
  Map<String, dynamic> globalData,
  Object? arguments,
);

class NavigationData {
  final String? label;
  final String url;
  final NavigationPageFactory builder;
  final PageType? pageType;
  final bool? fullScreenDialog;
  final Color? barrierColor;
  final Map<String, dynamic> metadata;
  final CustomPageBuilder? pageBuilder;

  /// Routes can be grouped together by setting
  /// a common `group` name.
  ///
  /// By default, Flutter identifies routes with unique URLs as unique pages.
  /// Setting a `group` alias overrides the default behavior
  /// and identifies those routes as the same page.
  ///
  /// Example:
  /// An app has 3 tabs on the HomePage.
  /// - Home
  /// - Games
  /// - Apps
  ///
  /// Each tab is assigned a top level URL
  /// `/`, `/games`, `/apps` in NavigationData.
  /// The pages themselves are nested in the HomePage() widget.
  /// To avoid stacking new HomePage widgets when
  /// switching tabs, group the pages with a common name.
  ///
  /// ```dart
  ///  NavigationData(
  ///     label: GamesPage.name,
  ///     url: '/games',
  ///     builder: (context, routeData, globalData) =>
  ///         const HomePage(tab: GamesPage.name),
  ///     group: HomePage.name,
  ///   ),
  /// ```
  final String? group;

  Uri get uri => Uri.tryParse(url) ?? Uri();
  String get path => canonicalUri(Uri.tryParse(url)?.path ?? '');
  Map<String, String> get queryParameters =>
      Uri.tryParse(url)?.queryParameters ?? {};

  NavigationData(
      {this.label,
      required this.url,
      required this.builder,
      this.pageType,
      this.fullScreenDialog,
      this.barrierColor,
      this.metadata = const {},
      this.group,
      this.pageBuilder})
      : assert(url.startsWith('/'),
            'URLs must be prefixed with /. A NavigationData contains a `url` value that is not prefixed with a /.');

  @override
  String toString() =>
      'NavigationData(label: $label, url: $url, metadata: $metadata, path: $path)';
}

/// Custom navigation builder for gradual migration support.
/// Wrapper the legacy navigation page builder with this function.
typedef MigrationPageBuilder = Page? Function(
    BuildContext context, dynamic routeData);

enum PageType {
  material,
  transparent,
  cupertino,
}

class NavigationBuilder {
  NavigationBuilder();

  // Cache pages directly
  static final Map<String, Page> _pageCache = {};
  static final Map<String, int> _routeIndices = {};

  /// Generates a cache key for the route
  /// This method is public so it can be used when creating routes
  static String generateCacheKey(
      NavigationData navigationData, DefaultRoute route) {
    // If there's a group, use it as the primary cache key
    if (navigationData.group != null) {
      return navigationData.group!;
    }

    // For non-grouped routes, include an index for duplicates
    String basePath = route.name ?? route.path;
    _routeIndices[basePath] = (_routeIndices[basePath] ?? 0) + 1;

    // Only add index suffix if this is a duplicate (count > 1)
    return _routeIndices[basePath] != null && _routeIndices[basePath]! > 1
        ? '$basePath-${_routeIndices[basePath]}'
        : basePath;
  }

  static List<Page> build(
      {required BuildContext context,
      required List<Object> routeDataList,
      required List<NavigationData> routes,
      OnUnknownRoute? onUnknownRoute,
      CustomPageBuilder? pageBuilder,
      MigrationPageBuilder? migrationPageBuilder,
      String? group}) {
    BaseRouterDelegate? mainRouterDelegate =
        (Router.of(context).routerDelegate as BaseRouterDelegate);
    List<Page> pages = [];
    _pageKeys.clear();
    _routeIndices.clear();

    // Create temporary cache for this build
    final Map<String, Page> newCache = {};

    for (int i = 0; i < routeDataList.length; i++) {
      Object route = routeDataList[i];
      if (route is DefaultRoute) {
        NavigationData? navigationData =
            NavigationUtils.getNavigationDataFromRoute(
                routes: routes, route: route);

        // TODO: Add wildcard support.
        if (navigationData != null &&
            (group == null || navigationData.group == group)) {
          // Skip building duplicated groups.
          if (group == null &&
              navigationData.group != null &&
              i < routeDataList.length - 1 &&
              (routeDataList[i + 1] as DefaultRoute).group ==
                  navigationData.group) {
            continue;
          }

          Map<String, String> pathParameters = {};
          pathParameters.addAll(route.pathParameters);
          if (navigationData.path.contains(':')) {
            pathParameters.addAll(
                NavigationUtils.extractPathParametersWithPattern(
                    route.path, navigationData.path));
          }

          // Use the route's assigned cacheKey or generate one if missing
          String cacheKey =
              route.cacheKey ?? generateCacheKey(navigationData, route);

          // Update the route with the cache key if it wasn't already set
          if (route.cacheKey == null) {
            route = route.copyWith(cacheKey: cacheKey);
          }

          // For groups, use the group name as the unique key
          ValueKey<String> pageKey;
          if (navigationData.group != null) {
            pageKey = _getUniqueKey(navigationData.group);
          } else {
            pageKey = _getUniqueKey(route.name);
          }

          // For grouped pages, always create new page to get updated child
          // For non-grouped pages, use cache
          Page page;
          final CustomPageBuilder? effectivePageBuilder =
              navigationData.pageBuilder ?? pageBuilder;

          if (effectivePageBuilder != null) {
            page = effectivePageBuilder(
              pageKey,
              route.name,
              navigationData.builder(
                  context,
                  route.copyWith(pathParameters: pathParameters),
                  mainRouterDelegate.globalData[route.path] ?? {}),
              route.copyWith(pathParameters: pathParameters),
              mainRouterDelegate.globalData[route.path] ?? {},
              route.arguments,
            );
          } else {
            if (navigationData.group != null) {
              page = buildPage(
                key: pageKey,
                name: route.name,
                child: navigationData.builder(
                    context,
                    route.copyWith(pathParameters: pathParameters),
                    mainRouterDelegate.globalData[route.path] ?? {}),
                arguments: route.arguments,
                pageType: navigationData.pageType ?? PageType.material,
                fullScreenDialog: navigationData.fullScreenDialog,
                barrierColor: navigationData.barrierColor,
              );
            } else {
              page = _pageCache[cacheKey] ??
                  buildPage(
                    key: pageKey,
                    name: route.name,
                    child: navigationData.builder(
                        context,
                        route.copyWith(pathParameters: pathParameters),
                        mainRouterDelegate.globalData[route.path] ?? {}),
                    arguments: route.arguments,
                    pageType: navigationData.pageType ?? PageType.material,
                    fullScreenDialog: navigationData.fullScreenDialog,
                    barrierColor: navigationData.barrierColor,
                  );
            }
          }

          newCache[cacheKey] = page;
          pages.add(page);
          continue;
        }
      }

      Page? customPage = migrationPageBuilder?.call(context, route);
      if (customPage != null) {
        pages.add(customPage);
        continue;
      }

      if (onUnknownRoute != null) {
        pages.add(onUnknownRoute.call(route as DefaultRoute));
      }
    }

    // Replace old cache with new one
    _pageCache.clear();
    _pageCache.addAll(newCache);

    return pages;
  }

  static final Map<String, int> _pageKeys = {};

  static Page buildPage({
    required String? name,
    required Widget child,
    ValueKey<String>? key,
    Object? arguments,
    PageType pageType = PageType.material,
    bool? fullScreenDialog,
    Color? barrierColor,
  }) {
    switch (pageType) {
      case PageType.material:
        return MaterialPage(
            key: key,
            name: name,
            arguments: arguments,
            fullscreenDialog: fullScreenDialog ?? false,
            child: child);
      case PageType.transparent:
        return TransparentPage(
            key: key,
            name: name,
            arguments: arguments,
            fullscreenDialog: fullScreenDialog ?? false,
            barrierColor: barrierColor ?? Colors.transparent,
            child: child);
      case PageType.cupertino:
        return CupertinoPage(
            key: key,
            name: name,
            arguments: arguments,
            fullscreenDialog: fullScreenDialog ?? false,
            child: child);
    }
  }

  static List<Widget> buildWidgets(
      {required BuildContext context,
      required List<Object> routeDataList,
      required List<NavigationData> routes,
      String? group}) {
    List<Widget> widgets = [];

    for (Object route in routeDataList) {
      if (route is DefaultRoute) {
        NavigationData? navigationData =
            NavigationUtils.getNavigationDataFromRoute(
                routes: routes, route: route);

        if (navigationData != null &&
            (group == null || navigationData.group == group)) {
          Map<String, String> pathParameters = {};
          pathParameters.addAll(route.pathParameters);
          if (navigationData.path.contains(':')) {
            pathParameters.addAll(
                NavigationUtils.extractPathParametersWithPattern(
                    route.path, navigationData.path));
          }

          Widget child = navigationData.builder(
              context, route.copyWith(pathParameters: pathParameters), {});
          widgets.add(child);
        }
      }
    }

    return widgets;
  }

  // Helper method to get a unique key
  static ValueKey<String> _getUniqueKey(String? name) {
    if (name == null) {
      return const ValueKey('');
    }

    _pageKeys[name] = (_pageKeys[name] ?? 0) + 1;
    return _pageKeys[name]! > 1
        ? ValueKey('$name-${_pageKeys[name]}')
        : ValueKey(name);
  }

  // Add method to clear cache when needed
  static void clearCache() {
    _pageCache.clear();
    _routeIndices.clear(); // Also clear route indices
  }

  /// Clears cached route entries related to a specific route
  ///
  /// Uses the route's assigned cacheKey for more reliable cache management
  /// Properly maintains index counters to ensure correct cache key generation
  static void clearCachedRoute(DefaultRoute route) {
    if (route.cacheKey != null) {
      // Use the assigned cache key directly
      _pageCache.remove(route.cacheKey);

      // Handle index suffix for indexed routes
      if (route.cacheKey!.contains('-')) {
        // Extract the base key and index
        List<String> parts = route.cacheKey!.split('-');
        if (parts.length == 2) {
          String baseKey = parts[0];
          int removedIndex = int.tryParse(parts[1]) ?? 0;

          // If this was the highest index for this base path,
          // decrement the counter to the next highest index
          if (_routeIndices.containsKey(baseKey) &&
              _routeIndices[baseKey] == removedIndex) {
            _routeIndices[baseKey] = removedIndex - 1;
          }
        }
      }
      return;
    }

    // Fallback for routes without assigned cache keys
    if (route.group != null) {
      _pageCache.remove(route.group);
      return;
    }

    // For routes with neither cacheKey nor group
    // Use the path or name as the base key
    String basePath = route.name ?? route.path;
    _pageCache.remove(basePath);
  }

  // Trim character functions.
  // https://stackoverflow.com/a/60957386/6211703

  String _trimLeft(String from, String pattern) {
    if (from.isEmpty || pattern.isEmpty || pattern.length > from.length) {
      return from;
    }

    while (from.startsWith(pattern)) {
      from = from.substring(pattern.length);
    }
    return from;
  }

  String _trimRight(String from, String pattern) {
    if (from.isEmpty || pattern.isEmpty || pattern.length > from.length) {
      return from;
    }

    while (from.endsWith(pattern)) {
      from = from.substring(0, from.length - pattern.length);
    }
    return from;
  }

  // ignore: unused_element
  String _trim(String from, String pattern) {
    return _trimLeft(_trimRight(from, pattern), pattern);
  }
}
