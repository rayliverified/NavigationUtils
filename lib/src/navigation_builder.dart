import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navigation_utils/navigation_utils.dart';

typedef NavigationPageFactory = Widget Function(BuildContext context,
    DefaultRoute routeData, Map<String, dynamic> globalData);

typedef OnUnknownRoute = Page Function(DefaultRoute route);

class NavigationData {
  final String? label;
  final String url;
  final NavigationPageFactory builder;
  final PageType? pageType;
  final bool? fullScreenDialog;
  final Color? barrierColor;
  final Map<String, dynamic> metadata;

  String get path => Uri.tryParse(url)?.path ?? '';
  Map<String, String> get queryParameters =>
      Uri.tryParse(url)?.queryParameters ?? {};

  NavigationData(
      {this.label,
      required this.url,
      required this.builder,
      this.pageType,
      this.fullScreenDialog,
      this.barrierColor,
      this.metadata = const {}})
      : assert(
            url.startsWith('/'), 'Path must be prefixed with / to match URLs.');

  @override
  String toString() =>
      'NavigationData(label: $label, url: $url, metadata: $metadata)';
}

/// Custom navigation builder for gradual migration support.
/// Wrapper the legacy navigation page builder with this function.
typedef NavigationPageBuilder = Page? Function(
    BuildContext context, dynamic routeData);

enum PageType {
  material,
  transparent,
  cupertino,
}

class NavigationBuilder {
  final List<Object> routeDataList;
  final List<NavigationData> routes;
  final OnUnknownRoute? onUnknownRoute;
  final NavigationPageBuilder? pageBuilder;

  NavigationBuilder(
      {required this.routeDataList,
      this.routes = const [],
      this.onUnknownRoute,
      this.pageBuilder});

  List<Page> build(BuildContext context) {
    BaseRouterDelegate? mainRouterDelegate =
        (Router.of(context).routerDelegate as BaseRouterDelegate);
    List<Page> pages = [];
    for (Object route in routeDataList) {
      if (route is DefaultRoute) {
        NavigationData? navigationData =
            NavigationUtils.getNavigationDataFromRoute(
                routes: routes, route: route);

        // TODO: Add wildcard support.

        if (navigationData != null) {
          Map<String, String> pathParameters = {};
          if (navigationData.path.contains(':')) {
            pathParameters = NavigationUtils.extractPathParametersWithPattern(
                route.path, navigationData.path);
          }
          // Inject dynamic data to page builder.
          Map<String, dynamic> globalData = mainRouterDelegate.globalData;
          Map<String, dynamic>? globalPageData = {};
          if (navigationData.label != null) {
            // Get global data via name.
            globalPageData = globalData[navigationData.label];
          } else {
            // Get global data via path.
            globalPageData = globalData[navigationData.path];
          }
          Widget child = navigationData.builder(
              context,
              route.copyWith(pathParameters: pathParameters),
              globalPageData ?? {});

          if (mainRouterDelegate.pageOverride != null) {
            child = mainRouterDelegate.pageOverride!;
          }

          Page page = buildPage(navigationData, child,
              queryParameters: route.queryParameters,
              arguments: route.arguments,
              pageType: navigationData.pageType ?? PageType.material,
              fullScreenDialog: navigationData.fullScreenDialog,
              barrierColor: navigationData.barrierColor);
          pages.add(page);
          continue;
        }
      }

      Page? customPage = pageBuilder?.call(context, route);
      if (customPage != null) {
        pages.add(customPage);
        continue;
      }

      if (onUnknownRoute != null) {
        pages.add(onUnknownRoute!.call(route as DefaultRoute));
      }
    }

    return pages;
  }

  Page buildPage(NavigationData navigationData, Widget child,
      {Map<String, String> queryParameters = const {},
      Object? arguments,
      PageType pageType = PageType.material,
      bool? fullScreenDialog,
      Color? barrierColor}) {
    String name =
        Uri(path: navigationData.path, queryParameters: queryParameters)
            .toString();
    name = _trimRight(name, '?');
    if (name.startsWith('/') == false) name = '/$name';

    switch (pageType) {
      case PageType.material:
        return MaterialPage(
            name: name,
            arguments: arguments,
            fullscreenDialog: fullScreenDialog ?? false,
            child: child);
      case PageType.transparent:
        return TransparentPage(
            name: name,
            arguments: arguments,
            fullscreenDialog: fullScreenDialog ?? false,
            barrierColor: barrierColor ?? Colors.transparent,
            child: child);
      case PageType.cupertino:
        return CupertinoPage(
            name: name,
            arguments: arguments,
            fullscreenDialog: fullScreenDialog ?? false,
            child: child);
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
