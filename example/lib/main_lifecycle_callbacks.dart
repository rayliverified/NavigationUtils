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
      url: '/project/:id',
      label: ProjectPage.name,
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

class _MyHomePageState extends State<MyHomePage>
    with NavigationListenerStateMixin, LifecycleObserverStateMixin {
  // Navigation Callbacks
  @override
  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {
    debugPrint(
        'Home onRoutePause: oldRouteName: $oldRouteName, newRouteName: $newRouteName');
  }

  @override
  void onRouteResume() {
    debugPrint('Home onRouteResume');
  }

  // Lifecycle Callbacks
  @override
  void onPaused() {
    debugPrint('Home onPaused');
  }

  @override
  void onResumed() {
    debugPrint('Home onResumed');
  }

  @override
  void onInactive() {
    debugPrint('Home onInactive');
  }

  @override
  void onDetached() {
    debugPrint('Home onDetached');
  }

  @override
  void onHidden() {
    debugPrint('Home onHidden');
  }

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

class _ProjectPageState extends State<ProjectPage>
    with NavigationListenerStateMixin, LifecycleObserverStateMixin {
  @override
  void initState() {
    super.initState();
    debugPrint('Init Projects Page: ${widget.id}');
  }

  // Navigation Callbacks
  @override
  void onRoutePause(
      {required String oldRouteName, required String newRouteName}) {
    debugPrint(
        'Page ${widget.id} onRoutePause: oldRouteName: $oldRouteName, newRouteName: $newRouteName');
  }

  @override
  void onRouteResume() {
    debugPrint('Page ${widget.id} onRouteResume');
  }

  // Lifecycle Callbacks
  @override
  void onPaused() {
    debugPrint('Page ${widget.id} onPaused');
  }

  @override
  void onResumed() {
    debugPrint('Page ${widget.id} onResumed');
  }

  @override
  void onInactive() {
    debugPrint('Page ${widget.id} onInactive');
  }

  @override
  void onDetached() {
    debugPrint('Page ${widget.id} onDetached');
  }

  @override
  void onHidden() {
    debugPrint('Page ${widget.id} onHidden');
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
