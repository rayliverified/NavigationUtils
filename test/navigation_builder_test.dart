import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('NavigationBuilder Cache Tests', () {
    late DefaultRouterDelegate routerDelegate;

    setUp(() {
      final baseRoutes = [
        NavigationData(
          label: 'home',
          url: '/',
          builder: (context, routeData, globalData) => const SizedBox(),
        ),
      ];

      routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: baseRoutes,
      );

      routerDelegate.setNewRoutePath(DefaultRoute(path: '/'));
    });

    tearDown(() {
      // Clear the NavigationBuilder cache between tests
      NavigationBuilder.clearCache();
    });

    testWidgets('Grouped pages share the same widget instance',
        (WidgetTester tester) async {
      final routes = [
        NavigationData(
          label: 'home',
          url: '/',
          builder: (context, routeData, globalData) =>
              const HomePage(tab: 'home'),
          group: 'home_page',
        ),
        NavigationData(
          label: 'community',
          url: '/community',
          builder: (context, routeData, globalData) =>
              const HomePage(tab: 'community'),
          group: 'home_page',
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      final routeDataList = [
        DefaultRoute(path: '/', group: 'home_page'),
        DefaultRoute(path: '/community', group: 'home_page'),
      ];

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(
            uri: Uri.parse('/'),
          ),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(Navigator));

      final pages = NavigationBuilder.build(
        context: context,
        routeDataList: routeDataList,
        routes: routes,
      );

      expect(pages.length, 1,
          reason: 'Grouped pages should only create one page instance');

      final homePage = pages[0] as Page;
      expect((homePage as dynamic).child, isA<HomePage>());
    });

    testWidgets('Duplicate non-grouped pages create unique instances',
        (WidgetTester tester) async {
      final routes = [
        NavigationData(
          label: 'post',
          url: '/post/:id',
          builder: (context, routeData, globalData) => PostPage(
            id: routeData.pathParameters['id'] ?? '',
          ),
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      final routeDataList = [
        DefaultRoute(path: '/post/1', pathParameters: {'id': '1'}),
        DefaultRoute(path: '/post/1', pathParameters: {'id': '1'}),
      ];

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(Navigator));

      final pages = NavigationBuilder.build(
        context: context,
        routeDataList: routeDataList,
        routes: routes,
      );

      expect(pages.length, 2,
          reason: 'Duplicate routes should create separate pages');
    });

    // This test fails. The instance is not preserved for some reason.
    testWidgets('Cache cleanup maintains correct page instances',
        (WidgetTester tester) async {
      final routes = [
        NavigationData(
          label: 'post',
          url: '/post/:id',
          builder: (context, routeData, globalData) => PostPage(
            id: routeData.pathParameters['id'] ?? '',
          ),
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      final routeDataList1 = [
        DefaultRoute(path: '/post/1', pathParameters: {'id': '1'}),
        DefaultRoute(path: '/post/2', pathParameters: {'id': '2'}),
      ];

      late Page page1;
      late Page page2;

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();
      final BuildContext context = tester.element(find.byType(Navigator));

      final pages = NavigationBuilder.build(
        context: context,
        routeDataList: routeDataList1,
        routes: routes,
      );

      expect(pages.length, 2);

      final updatedPages = NavigationBuilder.build(
        context: context,
        routeDataList: [routeDataList1[0]],
        routes: routes,
      );

      expect(updatedPages.length, 1);
      expect(updatedPages[0], pages[0]);
      expect(updatedPages.contains(pages[1]), isFalse);
    });

    testWidgets('Consecutive duplicate pages are skipped',
        (WidgetTester tester) async {
      final routes = [
        NavigationData(
          label: 'post',
          url: '/post/:id',
          builder: (context, routeData, globalData) => PostPage(
            id: routeData.pathParameters['id'] ?? '',
          ),
          group: 'post',
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      final routeDataList = [
        DefaultRoute(path: '/post/1', group: 'post'),
        DefaultRoute(path: '/post/1', group: 'post'),
      ];

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();
      final BuildContext context = tester.element(find.byType(Navigator));

      final pages = NavigationBuilder.build(
        context: context,
        routeDataList: routeDataList,
        routes: routes,
      );

      expect(pages.length, 1,
          reason: 'Consecutive duplicate group pages should be skipped');
    });

    testWidgets('Non-sequential duplicate pages are added',
        (WidgetTester tester) async {
      final routes = [
        NavigationData(
          label: 'post',
          url: '/post/:id',
          builder: (context, routeData, globalData) => PostPage(
            id: routeData.pathParameters['id'] ?? '',
          ),
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      final routeDataList = [
        DefaultRoute(path: '/post/1'),
        DefaultRoute(path: '/post/2'),
        DefaultRoute(path: '/post/1'),
      ];

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();
      final BuildContext context = tester.element(find.byType(Navigator));

      final pages = NavigationBuilder.build(
        context: context,
        routeDataList: routeDataList,
        routes: routes,
      );

      expect(pages.length, 3,
          reason: 'Non-sequential duplicate pages should be added');
    });

    testWidgets('Group page updates existing instance',
        (WidgetTester tester) async {
      final routes = [
        NavigationData(
          label: 'home',
          url: '/',
          builder: (context, routeData, globalData) =>
              HomePage(tab: routeData.path),
          group: 'home',
        ),
        NavigationData(
          label: 'community',
          url: '/community',
          builder: (context, routeData, globalData) =>
              HomePage(tab: routeData.path),
          group: 'home',
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();
      final BuildContext context = tester.element(find.byType(Navigator));

      final initialPages = NavigationBuilder.build(
        context: context,
        routeDataList: [DefaultRoute(path: '/', group: 'home')],
        routes: routes,
      );

      final homePage = initialPages[0] as Page;
      final initialWidget = (homePage as dynamic).child as HomePage;
      expect(initialWidget.tab, equals('/'));

      // Push the community page
      routerDelegate.push('community');
      await tester.pumpAndSettle();

      // Get the updated pages and verify
      final updatedPages = NavigationBuilder.build(
        context: context,
        routeDataList: [DefaultRoute(path: '/community', group: 'home')],
        routes: routes,
      );

      expect(updatedPages.length, 1);
      final updatedPage = updatedPages[0] as Page;
      final updatedWidget = (updatedPage as dynamic).child as HomePage;
      expect(updatedPage.key, equals(homePage.key));
      expect(updatedWidget.tab, equals('/community'));
    });

    testWidgets('Query parameter changes behavior',
        (WidgetTester tester) async {
      final routes = [
        // Grouped page that should update instance
        NavigationData(
          label: 'home',
          url: '/',
          builder: (context, routeData, globalData) =>
              HomePage(tab: routeData.queryParameters['tab'] ?? 'default'),
          group: 'home',
        ),
        // Non-grouped page that should create new instance
        NavigationData(
          label: 'post',
          url: '/post',
          builder: (context, routeData, globalData) =>
              PostPage(id: routeData.queryParameters['id'] ?? ''),
        ),
      ];

      routerDelegate.navigationDataRoutes = routes;

      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
        builder: (context, child) => child ?? const SizedBox(),
      ));

      await tester.pumpAndSettle();
      final BuildContext context = tester.element(find.byType(Navigator));

      // Test grouped page (should update instance)
      routerDelegate.push('home', queryParameters: {'tab': 'tab1'});
      await tester.pumpAndSettle();

      final initialPages = NavigationBuilder.build(
        context: context,
        routeDataList: [
          DefaultRoute(
              path: '/', group: 'home', queryParameters: {'tab': 'tab1'})
        ],
        routes: routes,
      );

      final homePage = initialPages[0] as Page;
      final initialWidget = (homePage as dynamic).child as HomePage;
      expect(initialWidget.tab, equals('tab1'));

      // Update query parameters for grouped page
      routerDelegate.push('home', queryParameters: {'tab': 'tab2'});
      await tester.pumpAndSettle();

      final updatedPages = NavigationBuilder.build(
        context: context,
        routeDataList: [
          DefaultRoute(
              path: '/', group: 'home', queryParameters: {'tab': 'tab2'})
        ],
        routes: routes,
      );

      final updatedPage = updatedPages[0] as Page;
      final updatedWidget = (updatedPage as dynamic).child as HomePage;
      expect(updatedPage.key, equals(homePage.key),
          reason: 'Grouped pages should maintain same instance');
      expect(updatedWidget.tab, equals('tab2'));

      // Test non-grouped page (should create new instance)
      routerDelegate.push('post', queryParameters: {'id': '1'});
      await tester.pumpAndSettle();

      final initialPostPages = NavigationBuilder.build(
        context: context,
        routeDataList: [
          DefaultRoute(path: '/post', queryParameters: {'id': '1'})
        ],
        routes: routes,
      );

      final postPage = initialPostPages[0] as Page;
      final initialPostWidget = (postPage as dynamic).child as PostPage;
      expect(initialPostWidget.id, equals('1'));

      // Update query parameters for non-grouped page
      routerDelegate.push('post', queryParameters: {'id': '2'});
      await tester.pumpAndSettle();

      final updatedPostPages = NavigationBuilder.build(
        context: context,
        routeDataList: [
          DefaultRoute(path: '/post', queryParameters: {'id': '2'})
        ],
        routes: routes,
      );

      final updatedPostPage = updatedPostPages[0] as Page;
      final updatedPostWidget = (updatedPostPage as dynamic).child as PostPage;
      expect(updatedPostWidget.id, equals('2'));
    });
  });
}

// Test widgets
class HomePage extends StatelessWidget {
  final String tab;
  const HomePage({super.key, required this.tab});
  @override
  Widget build(BuildContext context) => Text(tab);
}

class PostPage extends StatelessWidget {
  final String id;
  const PostPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Text(id);
}

// Additional test widget
class StatefulHomePage extends StatefulWidget {
  final String tab;

  StatefulHomePage({required this.tab})
      : super(key: GlobalKey<StatefulHomePageState>());

  @override
  State<StatefulHomePage> createState() => StatefulHomePageState();
}

class StatefulHomePageState extends State<StatefulHomePage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) => Text('${widget.tab}: $counter');
}
