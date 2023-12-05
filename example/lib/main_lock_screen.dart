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
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with LifecycleObserverMixin {
  bool passcodeEnabled = true;

  @override
  void initState() {
    super.initState();
    initLifecycleObserver();
    if (passcodeEnabled) showPasscodeLock();
  }

  @override
  void dispose() {
    disposeLifecycleObserver();
    super.dispose();
  }

  @override
  void onPaused() {
    showPasscodeLock();
  }

  void showPasscodeLock() {
    // Show lock screen when use switches app or app is backgrounded.
    NavigationManager.instance.setOverlay(
      (name) => MaterialPage(
        name: name,
        child: Scaffold(
          body: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Passcode'),
                ElevatedButton(
                    onPressed: () => NavigationManager.instance.removeOverlay(),
                    child: const Text('Unlock')),
              ],
            ),
          ),
        ),
      ),
    );
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
