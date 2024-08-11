import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('getNavigationDataFromRoute', () {
    test('Simple Matching', () {
      NavigationData pageNavigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (context, routeData, globalData) => Container(),
      );
      NavigationData? navigationData =
          NavigationUtils.getNavigationDataFromRoute(routes: [
        pageNavigationData,
      ], route: DefaultRoute(path: '/page'));
      expect(navigationData, pageNavigationData);

      navigationData = NavigationUtils.getNavigationDataFromRoute(routes: [
        pageNavigationData,
      ], route: DefaultRoute(label: 'page', path: '/hello'));
      expect(navigationData, navigationData,
          reason: 'Label match is prioritized above path match.');

      navigationData = NavigationUtils.getNavigationDataFromRoute(routes: [
        pageNavigationData,
      ], route: DefaultRoute(label: 'hello', path: '/hello'));
      expect(null, null, reason: 'No match.');
    });

    test('Query Parameter Matching', () {
      NavigationData pageNavigationData = NavigationData(
        label: 'page',
        url: '/page',
        builder: (context, routeData, globalData) => Container(),
      );
      Map<String, String> queryParametersMap = const {
        'id': '123',
        'type': 'abc'
      };
      NavigationData? navigationData =
          NavigationUtils.getNavigationDataFromRoute(
              routes: [
            pageNavigationData,
          ],
              route: DefaultRoute(
                  path: '/page', queryParameters: queryParametersMap));
      expect(navigationData, pageNavigationData);
      expect(navigationData!.queryParameters, {},
          reason:
              'NavigationData is independent from query parameters. Query parameters are not used for path routing.');
      // The query parameter is injected later when building the route.

      navigationData = NavigationUtils.getNavigationDataFromRoute(routes: [
        pageNavigationData,
      ], route: DefaultRoute(path: '/page?id=123&type=abc'));
      expect(null, null,
          reason:
              'Path represents the absolute URI path and should not contain query parameters.');
    });

    test('Exact Path Matching', () {
      NavigationData pageNavigationData = NavigationData(
        url: '/page/nested?id=123&type=abc',
        builder: (context, routeData, globalData) => Container(),
      );
      NavigationData? navigationData =
          NavigationUtils.getNavigationDataFromRoute(
              routes: [
            pageNavigationData,
          ],
              route: DefaultRoute(
                  path: '/page/nested',
                  queryParameters: const {'id': '123', 'type': 'abc'}));
      expect(navigationData, pageNavigationData);

      navigationData = NavigationUtils.getNavigationDataFromRoute(routes: [
        pageNavigationData,
      ], route: DefaultRoute(path: '/page/nested'));
      // Uri '/page/nested?id=123&type=abc' != '/page/nested'.
      // Uri.path '/page/nested' == '/page/nested'.
      expect(navigationData, navigationData,
          reason: 'Path excludes query parameters so it should match.');
    });
  });
}
