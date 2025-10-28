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

    // Do not clear _routeIndices here - it needs to persist between builds

    // Create temporary cache for this build
    final Map<String, Page> newCache = {};

    // Track groups to handle contiguous group items correctly
    final Map<String, int> lastGroupIndex = {};
    final Set<String> processedGroups = {};

    // First pass: identify contiguous groups and mark them for skipping
    for (int i = 0; i < routeDataList.length; i++) {
      Object route = routeDataList[i];
      if (route is DefaultRoute && route.group != null) {
        String groupName = route.group!;

        // If this is a new group, start tracking it
        if (!lastGroupIndex.containsKey(groupName)) {
          lastGroupIndex[groupName] = i;
        }
        // If this is a contiguous group item, update the last index
        else if (lastGroupIndex[groupName]! == i - 1) {
          lastGroupIndex[groupName] = i;
        }
        // If this is a non-contiguous group item, start a new tracking
        else {
          lastGroupIndex[groupName] = i;
        }
      }
    }

    // Second pass: build pages, skipping contiguous group items except the last one
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
          // Skip non-top contiguous group items
          if (navigationData.group != null) {
            String groupName = navigationData.group!;

            // Skip if this is part of a contiguous group but not the last item
            if (i < lastGroupIndex[groupName]!) {
              continue;
            }

            // For grouped routes, track first instance of group in this route stack
            // to determine cache key assignment
            if (!processedGroups.contains(groupName)) {
              processedGroups.add(groupName);
            }
          }

          Map<String, String> pathParameters = {};
          pathParameters.addAll(route.pathParameters);
          if (navigationData.path.contains(':')) {
            pathParameters.addAll(
                NavigationUtils.extractPathParametersWithPattern(
                    route.path, navigationData.path));
          }

          // Generate a cache key if not already assigned to this route
          // Use routeDataList to get existing routes in the current build context
          List<DefaultRoute> existingRoutes = routeDataList
              .whereType<DefaultRoute>()
              .where((r) => r.cacheKey != null)
              .toList();
          String cacheKey = route.cacheKey ??
              generateCacheKey(navigationData, route, existingRoutes);
          // Update the route with the cache key if it wasn't already set
          // Only update if route exists in delegate's routes list at the same index
          if (route.cacheKey == null &&
              i < mainRouterDelegate.routes.length &&
              mainRouterDelegate.routes[i].path == route.path) {
            mainRouterDelegate.routes[i] =
                mainRouterDelegate.routes[i].copyWith(cacheKey: cacheKey);
          }

          // Key for the page - use the cache key for uniqueness
          // This ensures Flutter Navigator can distinguish between duplicate routes
          ValueKey<String> pageKey = ValueKey<String>(cacheKey);

          // For grouped pages, always create new page to get updated child
          // For non-grouped pages, either create new or reuse based on cacheKey
          Page page;
          final CustomPageBuilder? effectivePageBuilder =
              navigationData.pageBuilder ?? pageBuilder;

          if (effectivePageBuilder != null) {
            page = effectivePageBuilder(
              pageKey,
              route.path,
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
                name: route.path,
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
              // For non-groups, always rebuild the page with updated child
              // The page key stays the same (based on cacheKey) so Flutter recognizes
              // it as the same page and calls didUpdateWidget on the child widget
              page = buildPage(
                key: pageKey, // Use the same cache key for the page key
                name: route
                    .path, // Use path (not name) so query params don't affect page identity
                child: navigationData.builder(
                    context,
                    route.copyWith(pathParameters: pathParameters),
                    mainRouterDelegate.globalData[route.path] ?? {}),
                // Pass query parameters as arguments so Flutter can detect changes
                arguments: route.queryParameters.isNotEmpty
                    ? route.queryParameters
                    : route.arguments,
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
        return _UpdateableMaterialPage(
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

  /// Generates a cache key for the route
  /// This method is public so it can be used when creating routes
  ///
  /// [navigationData] - The navigation data for the route
  /// [route] - The route to generate a cache key for
  /// [existingRoutes] - Optional list of existing routes to check for duplicates
  static String generateCacheKey(
      NavigationData navigationData, DefaultRoute route,
      [List<DefaultRoute>? existingRoutes]) {
    // If the route already has a cacheKey, don't generate a new one
    if (route.cacheKey != null) {
      return route.cacheKey!;
    }

    // For groups, always use the group name as the cache key
    if (navigationData.group != null) {
      return navigationData.group!;
    }

    // For non-grouped routes, use path as base key (ignore query parameters)
    // This ensures routes with same path but different query params get the same cache key
    String basePath = route.path;

    // If existingRoutes is provided, check against actual routes in the stack
    // This ensures we generate indexed keys for duplicates correctly
    if (existingRoutes != null && existingRoutes.isNotEmpty) {
      List<String> existingCacheKeys = existingRoutes
          .where((r) => r.cacheKey != null)
          .map((r) => r.cacheKey!)
          .toList();

      // If this path doesn't exist yet, use the base path
      if (!existingCacheKeys.contains(basePath)) {
        return basePath;
      }

      // Path exists, need to generate indexed key
      int index = 2;
      String candidateKey = '$basePath-$index';

      while (existingCacheKeys.contains(candidateKey)) {
        index++;
        candidateKey = '$basePath-$index';
      }

      return candidateKey;
    }

    // Fallback for when existingRoutes is not provided
    // Just return the base path - indexing should only happen when checking
    // against actual existing routes in the stack
    return basePath;
  }

  // Add method to clear cache when needed
  static void clearCache() {
    _pageCache.clear();
    _routeIndices.clear();
  }

  /// Clears cached route entries related to a specific route
  ///
  /// Uses the route's assigned cacheKey for more reliable cache management
  /// Properly maintains index counters to ensure correct cache key generation
  static void clearCachedRoute(DefaultRoute route) {
    // If the route has an explicit cache key, use it directly
    if (route.cacheKey != null) {
      _pageCache.remove(route.cacheKey);

      // Handle index suffix for indexed routes
      if (route.cacheKey!.contains('-')) {
        // Extract the base key and index
        List<String> parts = route.cacheKey!.split('-');
        if (parts.length == 2) {
          String baseKey = parts[0];
          int removedIndex = int.tryParse(parts[1]) ?? 0;

          // If we're removing the highest index, find the next highest available index
          if (_routeIndices.containsKey(baseKey) &&
              _routeIndices[baseKey] == removedIndex) {
            // Find the highest existing index less than the removed one
            int nextHighestIndex = 0;

            // Check for the existence of cache keys with lower indices
            for (int i = removedIndex - 1; i >= 1; i--) {
              if (_pageCache.containsKey('$baseKey-$i')) {
                nextHighestIndex = i;
                break;
              }
            }

            // If we found a lower index or there's a base path without index
            if (nextHighestIndex > 0 || _pageCache.containsKey(baseKey)) {
              _routeIndices[baseKey] = nextHighestIndex;
            } else {
              // No other instances of this route exist, remove tracking
              _routeIndices.remove(baseKey);
            }
          }
        }
      } else {
        // Removing a base route without an index
        // Check if there are any indexed versions before removing the counter
        bool hasIndexedVersions = false;
        String baseKey = route.cacheKey!;

        for (int i = 2; i <= (_routeIndices[baseKey] ?? 1); i++) {
          if (_pageCache.containsKey('$baseKey-$i')) {
            hasIndexedVersions = true;
            break;
          }
        }

        // If no indexed versions exist, remove the counter
        if (!hasIndexedVersions) {
          _routeIndices.remove(baseKey);
        }
      }
      return;
    }

    // For routes without explicit cache key
    String cacheKey = route.group ?? route.name ?? route.path;

    // Remove the main entry
    _pageCache.remove(cacheKey);

    // The group check is needed because group routes use a different caching strategy
    // For non-grouped routes, we need to manage indices
    if (route.group == null) {
      // Check if any indexed variants exist
      bool hasIndexedVariants = false;

      for (int i = 2; i <= (_routeIndices[cacheKey] ?? 1); i++) {
        if (_pageCache.containsKey('$cacheKey-$i')) {
          hasIndexedVariants = true;
          break;
        }
      }

      // If no indexed variants exist, remove tracking entirely
      if (!hasIndexedVariants) {
        _routeIndices.remove(cacheKey);
      }
    }
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

/// Custom MaterialPage that properly handles updates when only arguments change
/// This ensures that when a page with the same key is rebuilt with new arguments,
/// the widget tree is updated (didUpdateWidget called) rather than recreated
class _UpdateableMaterialPage<T> extends Page<T> {
  const _UpdateableMaterialPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final bool maintainState;
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedMaterialPageRoute<T>(page: this);
  }

  @override
  bool canUpdate(Page other) {
    // Allow updates if the key and type match
    // This enables didUpdateWidget to be called on the child
    return other.runtimeType == runtimeType && other.key == key;
  }
}

/// Custom MaterialPageRoute that preserves state during updates
class _PageBasedMaterialPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _PageBasedMaterialPageRoute({
    required _UpdateableMaterialPage<T> page,
  }) : super(settings: page);

  _UpdateableMaterialPage<T> get _page =>
      settings as _UpdateableMaterialPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
