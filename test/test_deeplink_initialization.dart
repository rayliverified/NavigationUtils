import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  testWidgets('Deeplink initialization with empty routes should not crash',
      (WidgetTester tester) async {
    // Setup test data
    final List<NavigationData> navigationDataRoutes = [
      NavigationData(
        url: '/home',
        builder: (context, routeData, globalData) => const Text('Home Page'),
      ),
      NavigationData(
        url: '/profile',
        builder: (context, routeData, globalData) => Text('Profile Page'),
      ),
    ];

    final List<DeeplinkDestination> deeplinkDestinations = [
      DeeplinkDestination(
        deeplinkUrl: '/profile',
        destinationUrl: '/profile',
      ),
    ];

    // Create router delegate with initial deeplink route
    final routerDelegate = DefaultRouterDelegate(
      navigationDataRoutes: navigationDataRoutes,
      deeplinkDestinations: deeplinkDestinations,
      debugLog: true,
    );

    // Create route information parser with debug logging
    DefaultRouteInformationParser routeInformationParser = DefaultRouteInformationParser(
      defaultRoutePath: '/profile',
      debugLog: true,
    );

    // Build our app with router
    await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: routeInformationParser,
    ));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Profile Page'), findsOneWidget);
  });
}
