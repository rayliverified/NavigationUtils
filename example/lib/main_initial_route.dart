import 'package:example/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  NavigationManager.init(
      mainRouterDelegate:
          DefaultRouterDelegate(navigationDataRoutes: routes, debugLog: true),
      routeInformationParser: DefaultRouteInformationParser(debugLog: true));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NavigationManager.instance.setInitialRoutePathFunction = handleInitialRoute;
  }

  String handleInitialRoute(Uri initialRoute) {
    NavigationData? navigationData = NavigationUtils.getNavigationDataFromName(
        routes, initialRoute.toString());
    // If the initial URL does not match an existing page,
    // redirect the user.
    // Here, the user is directed to the home page.
    // The user can also be directed to a 404 page.
    if (navigationData == null) return '/';

    // Add custom initial route processing logic here.
    // For example, custom URL parsing.
    // if (initialRoute.toString().contains('/oldRoute')) return '/newRoute';

    return initialRoute.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Navigation Utils Demo',
      routerDelegate: NavigationManager.instance.routerDelegate,
      routeInformationParser: NavigationManager.instance.routeInformationParser,
    );
  }
}
