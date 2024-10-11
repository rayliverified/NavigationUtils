import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      url: '/', builder: (context, routeData, globalData) => MyPage(id: 0)),
  NavigationData(
      url: '/:id',
      label: MyPage.name,
      builder: (context, routeData, globalData) =>
          MyPage(id: int.tryParse(routeData.pathParameters['id'] ?? '') ?? 0)),
];

/// Test Navigation library page equality comparison behavior.
/// When pages are stored in a variable and reused, equality is preserved.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  NavigationManager.init(
      mainRouterDelegate:
          DefaultRouterDelegate(navigationDataRoutes: routes, debugLog: true),
      routeInformationParser: DefaultRouteInformationParser());
  // NavigationManager.instance.routerDelegate.pages = [
  //   MaterialPage(
  //     key: const ValueKey(0),
  //     child: const MyPage(
  //       key: ValueKey('page1'),
  //       id: 0,
  //     ),
  //   )
  // ];
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   title: 'Page Rebuild Test',
    //   home: MyPage(id: 0),
    // );

    return MaterialApp.router(
      title: 'Page Rebuild Test',
      routerDelegate: NavigationManager.instance.routerDelegate,
      routeInformationParser: NavigationManager.instance.routeInformationParser,
    );
  }
}

class MyPage extends StatefulWidget {
  static const String name = 'my_page';

  final int id;

  const MyPage({super.key, required this.id});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    debugPrint('Rebuild Page: ${widget.id}');

    return Scaffold(
      backgroundColor: Colors.amber,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.id.toString(),
              style: TextStyle(color: Colors.white, fontSize: 48),
            ),
            ElevatedButton(
                onPressed: () {
                  NavigationManager.instance.push(MyPage.name,
                      pathParameters: {'id': (widget.id + 1).toString()});

                  // final currentPages =
                  //     NavigationManager.instance.routerDelegate.pages;
                  // final newPageIndex = currentPages.length + 1;
                  // final newPages = currentPages.map((page) {
                  //   if (page is MaterialPage) {
                  //     return MaterialPage(
                  //       key: ValueKey('${page.key}'),
                  //       name: page.name,
                  //       arguments: page.arguments,
                  //       fullscreenDialog: page.fullscreenDialog,
                  //       child: page.child,
                  //     );
                  //   }
                  //   return page;
                  // }).toList();

                  // newPages.add(MaterialPage(
                  //   key: ValueKey('page$newPageIndex'),
                  //   name: 'page$newPageIndex',
                  //   arguments: null,
                  //   fullscreenDialog: false,
                  //   child: MyPage(
                  //     key: ValueKey('page$newPageIndex'),
                  //     id: newPageIndex,
                  //   ),
                  // ));

                  // NavigationManager.instance.routerDelegate.pages = newPages;
                  // NavigationManager.instance.routerDelegate.notifyListeners();
                },
                child: Text('Next page')),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go back')),
          ],
        ),
      ),
    );
  }
}
