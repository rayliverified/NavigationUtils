import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  late DefaultRouterDelegate delegate;
  late NavigationManager navigation;

  Future<void> mount(WidgetTester tester) async {
    delegate = DefaultRouterDelegate(navigationDataRoutes: [
      NavigationData(
        label: 'home',
        url: '/home',
        builder: (_, __, ___) => const Scaffold(body: Text('Home')),
      ),
      NavigationData(
        label: 'guidelines',
        url: '/guidelines',
        pageType: PageType.cupertino,
        fullScreenDialog: true,
        builder: (_, __, ___) => const Scaffold(body: Text('Guidelines')),
      ),
    ]);
    navigation = NavigationManager.init(
      mainRouterDelegate: delegate,
      routeInformationParser: DefaultRouteInformationParser(),
    );
    await tester.pumpWidget(MaterialApp.router(
      routerDelegate: delegate,
      routeInformationParser: navigation.routeInformationParser,
    ));
    navigation.set(['home']);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    navigation.push('guidelines');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Guidelines'), findsOneWidget);
  }

  testWidgets('system back pops managed route exactly once', (tester) async {
    await mount(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(navigation.routes.map((route) => route.label), ['home']);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Guidelines'), findsNothing);
  });

  testWidgets('imperative pop above managed page preserves router stack',
      (tester) async {
    await mount(tester);
    final context = delegate.navigatorKey.currentContext!;
    Navigator.of(context).push(CupertinoPageRoute<void>(
      builder: (overlayContext) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(overlayContext).pop(),
          child: const Text('Close overlay'),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Close overlay'), findsOneWidget);
    await tester.tap(find.text('Close overlay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        navigation.routes.map((route) => route.label), ['home', 'guidelines']);
    expect(find.text('Guidelines'), findsOneWidget);
  });

  testWidgets('system back on page overlay preserves managed route',
      (tester) async {
    await mount(tester);
    delegate.setOverlay((_) => const MaterialPage<void>(
          key: ValueKey('overlay'),
          child: Scaffold(body: Text('Overlay')),
        ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Overlay'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        navigation.routes.map((route) => route.label), ['home', 'guidelines']);
    expect(find.text('Overlay'), findsNothing);
    expect(find.text('Guidelines'), findsOneWidget);
  });

  testWidgets('system back above an imperative route preserves managed page',
      (tester) async {
    await mount(tester);
    Navigator.of(delegate.navigatorKey.currentContext!).push(
      CupertinoPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Imperative overlay')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        navigation.routes.map((route) => route.label), ['home', 'guidelines']);
    expect(find.text('Guidelines'), findsOneWidget);
  });
}
