import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'navigation_delegate.dart';
import 'path_utils_go_router.dart';
import 'route_builders/transparent_route.dart';

typedef NavigationPageFactory = Widget Function(BuildContext context,
    DefaultRoute routeData, Map<String, dynamic> globalData);

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
  String toString() => 'NavigationData(label: $label, path: $path)';
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
  final Object? onGenerateRoutes;
  final NavigationPageBuilder? pageBuilder;

  NavigationBuilder(
      {required this.routeDataList,
      this.routes = const [],
      this.onGenerateRoutes = const {},
      this.pageBuilder});

  List<Page> build(BuildContext context) {
    BaseRouterDelegate? mainRouterDelegate =
        (Router.of(context).routerDelegate as BaseRouterDelegate);
    List<Page> pages = [];
    for (Object route in routeDataList) {
      if (route is DefaultRoute) {
        NavigationData? navigationData;

        // Named routing.
        try {
          navigationData = routes.firstWhere((element) =>
              ((element.label?.isNotEmpty ?? false) &&
                  element.label == route.label));
        } on StateError {
          // ignore: empty_catches
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
        Map<String, String> pathParameters = {};
        if (navigationData == null) {
          try {
            navigationData = routes.firstWhere((element) {
              if ((element.path.isNotEmpty && route.path.isNotEmpty)) {
                if (element.path.contains(':')) {
                  final List<String> paramNames = <String>[];
                  RegExp regExp = patternToRegExp(element.path, paramNames);
                  final String? match = regExp.stringMatch(route.path);
                  if (match == route.path) {
                    final RegExpMatch match = regExp.firstMatch(route.path)!;
                    pathParameters = extractPathParameters(paramNames, match);
                    return true;
                  }
                }
              }
              return false;
            });
          } on StateError {
            // ignore: empty_catches
          }
        }

        // TODO: Add wildcard support.

        if (navigationData != null) {
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
    }

    return pages;
  }

  Page buildPage(NavigationData navigationData, Widget child,
      {Map<String, String> queryParameters = const {},
      Object? arguments,
      PageType pageType = PageType.material,
      bool? fullScreenDialog,
      Color? barrierColor}) {
    print(navigationData.queryParameters);
    String name =
        Uri(path: navigationData.path, queryParameters: queryParameters)
            .toString();
    name = _trimRight(name, '?');
    if (name.startsWith('/') == false) name = '/$name';

    print('Name: $name');

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
