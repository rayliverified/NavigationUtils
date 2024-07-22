import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('Navigation Delegate Default', () {
    testWidgets('onPopPage', (WidgetTester tester) async {
      bool capturePop = false;
      NavigationManager.init(
          mainRouterDelegate: DefaultRouterDelegate(
            navigationDataRoutes: [
              NavigationData(
                  url: '/',
                  builder: (context, routeData, globalData) =>
                      const SizedBox.shrink()),
              NavigationData(
                url: '/page1',
                builder: (context, routeData, globalData) =>
                    const SizedBox.shrink(),
              ),
            ],
            onPopPage: (route, result) {
              if (capturePop) {
                expect(result, 'Pop Captured');
                return false;
              }
              return true;
            },
          ),
          routeInformationParser: DefaultRouteInformationParser());
      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: NavigationManager.instance.routerDelegate,
        routeInformationParser:
            NavigationManager.instance.routeInformationParser,
      ));
      NavigationManager.instance.set(['/', '/page1'], apply: false);

      // Handle pop in onPopPage override.
      capturePop = true;
      BuildContext context = tester.element(find.byType(SizedBox));
      Navigator.pop(context, 'Pop Captured');
      expect(NavigationManager.instance.routes.length, 2);

      // Disable pop callback override. Pop page.
      capturePop = false;
      Navigator.pop(context);
      expect(NavigationManager.instance.routes.length, 1);
    });
  });
}
