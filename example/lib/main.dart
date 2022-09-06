import 'package:flutter/material.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      label: MyHomePage.name,
      url: '/',
      builder: (context, routeData, globalData) =>
          const MyHomePage(title: 'Navigation')),
  NavigationData(
      url: '/project/:id',
      builder: (context, routeData, globalData) => ProjectPage(
          id: int.tryParse(routeData.pathParameters['id'] ?? '') ?? 0)),
];

void main() {
  NavigationManager.init(
      mainRouterDelegate: DefaultRouterDelegate(navigationDataRoutes: routes),
      routeInformationParser: DefaultRouteInformationParser());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProjectPage extends StatefulWidget {
  final int id;

  const ProjectPage({super.key, required this.id});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('Init Projects Page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.pinkAccent,
        alignment: Alignment.center,
        child: Column(
          children: [
            Text('Projects Page ${widget.id}',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
