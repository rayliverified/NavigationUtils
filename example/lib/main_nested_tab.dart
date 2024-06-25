import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      label: MyHomePage.name,
      url: '/',
      builder: (context, routeData, globalData) => const MyHomePage(),
      group: MyHomePage.name),
  NavigationData(
      label: FirstPage.name,
      url: '/',
      builder: (context, routeData, globalData) => const MyHomePage(),
      group: MyHomePage.name),
  NavigationData(
      label: SecondPage.name,
      url: '/second',
      builder: (context, routeData, globalData) => const MyHomePage(),
      group: MyHomePage.name),
  NavigationData(
      label: NestedFirstPage.name,
      url: '/second/1',
      builder: (context, routeData, globalData) => const MyHomePage(),
      group: MyHomePage.name),
  NavigationData(
      label: NestedSecondPage.name,
      url: '/second/2',
      builder: (context, routeData, globalData) => const MyHomePage(),
      group: MyHomePage.name),
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  NavigationManager.init(
      mainRouterDelegate: DefaultRouterDelegate(navigationDataRoutes: routes),
      routeInformationParser: DefaultRouteInformationParser());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Navigation Utils Demo',
      routerDelegate: NavigationManager.instance.routerDelegate,
      routeInformationParser: NavigationManager.instance.routeInformationParser,
    );
  }
}

class MyHomePage extends StatefulWidget {
  static const String name = 'home';

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  List<NavigationData> pages = [
    NavigationData(
      label: FirstPage.name,
      url: '/',
      builder: (context, routeData, globalData) =>
          const FirstPage(key: ValueKey(FirstPage.name)),
    ),
    NavigationData(
      label: SecondPage.name,
      url: '/second',
      builder: (context, routeData, globalData) =>
          const SecondPage(key: ValueKey(SecondPage.name)),
    ),
    NavigationData(
      label: NestedFirstPage.name,
      url: '/second/1',
      builder: (context, routeData, globalData) =>
          const SecondPage(key: ValueKey(SecondPage.name)),
    ),
    NavigationData(
      label: NestedSecondPage.name,
      url: '/second/2',
      builder: (context, routeData, globalData) =>
          const SecondPage(key: ValueKey(SecondPage.name)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('Routes: ${NavigationManager.instance.routerDelegate.routes}');

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              if (index == 0) {
                NavigationManager.instance.push(FirstPage.name);
              } else {
                NavigationManager.instance.push(SecondPage.name);
              }

              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.looks_one_rounded),
                selectedIcon: Icon(Icons.looks_one_outlined),
                label: Text('First'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.looks_two_outlined),
                selectedIcon: Icon(Icons.looks_two_rounded),
                label: Text('Second'),
              ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedStack(
                duration: const Duration(milliseconds: 500),
                crossFadePosition: 0.3,
                alignment: Alignment.topCenter,
                initialAnimation: false,
                animation: (child, animation) {
                  return SharedAxisAnimation(
                      key: child.key,
                      animation: animation,
                      transitionType: SharedAxisAnimationType.vertical,
                      child: child);
                },
                children: NavigationManager.instance
                    .nested(context: context, routes: pages),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FirstPage extends StatefulWidget {
  static const String name = 'first';

  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      alignment: Alignment.center,
      child: const Text(
        'First Page',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  static const String name = 'second';

  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueAccent,
      alignment: Alignment.center,
      child: const Text(
        'Second Page',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class NestedFirstPage extends StatefulWidget {
  static const String name = 'second';

  const NestedFirstPage({super.key});

  @override
  State<NestedFirstPage> createState() => _NestedFirstPageState();
}

class _NestedFirstPageState extends State<NestedFirstPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepOrangeAccent,
      alignment: Alignment.center,
      child: const Text(
        'Nested First Page',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class NestedSecondPage extends StatefulWidget {
  static const String name = 'second';

  const NestedSecondPage({super.key});

  @override
  State<NestedSecondPage> createState() => _NestedSecondPageState();
}

class _NestedSecondPageState extends State<NestedSecondPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightGreen,
      alignment: Alignment.center,
      child: const Text(
        'Nested Second Page',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
