// ignore_for_file: overridden_fields

import 'package:flutter/widgets.dart';

import 'navigation_builder.dart';
import 'navigation_delegate.dart';

class DefaultRouterDelegate extends BaseRouterDelegate {
  @override
  List<NavigationData> navigationDataRoutes = [];

  @override
  bool debugLog = false;

  @override
  OnUnknownRoute? onUnknownRoute;

  DefaultRouterDelegate(
      {required this.navigationDataRoutes,
      this.debugLog = false,
      this.onUnknownRoute});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        ...NavigationBuilder(
          routeDataList: routes,
          routes: navigationDataRoutes,
          onUnknownRoute: onUnknownRoute,
        ).build(context),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        if (canPop) {
          pop(result);
        }
        return true;
      },
      observers: const [],
    );
  }
}
