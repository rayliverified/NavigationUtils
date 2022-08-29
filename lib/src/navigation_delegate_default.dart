// ignore_for_file: overridden_fields

import 'package:flutter/widgets.dart';
import 'package:navigation_utils/navigation_utils.dart';

class DefaultRouterDelegate extends BaseRouterDelegate {
  @override
  List<NavigationData> namedRoutes = [];

  @override
  bool debugLog = false;

  DefaultRouterDelegate({required this.namedRoutes, this.debugLog = false});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        ...NavigationBuilder(
          routeDataList: defaultRoutes,
          routes: namedRoutes,
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
      observers: [],
    );
  }
}
