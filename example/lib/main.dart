import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      label: MyHomePage.name,
      url: '/',
      builder: (context, routeData, globalData) => const MyHomePage()),
  NavigationData(
      label: ProjectPage.name,
      url: '/project/:id',
      builder: (context, routeData, globalData) => ProjectPage(
          id: int.tryParse(routeData.pathParameters['id'] ?? '') ?? 0)),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              onPressed: () => NavigationManager.instance.push('/project/1'),
              child: const Text('Open Project Path'),
            ),
            MaterialButton(
              onPressed: () => NavigationManager.instance
                  .push(ProjectPage.name, pathParameters: {'id': '2'}),
              child: const Text('Open Project Named'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectPage extends StatefulWidget {
  static const String name = 'project';

  final int id;

  const ProjectPage({super.key, required this.id});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('Init Projects Page: ${widget.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project ${widget.id}'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          children: [
            Text('Projects Page ${widget.id}',
                style: const TextStyle(color: Colors.white)),
            MaterialButton(
              onPressed: () => NavigationManager.instance.push(ProjectPage.name,
                  pathParameters: {'id': (widget.id + 1).toString()}),
              child: Text('Open Project Page ${(widget.id + 1).toString()}'),
            ),
            MaterialButton(
                onPressed: () => NavigationManager.instance.pop(),
                child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}
