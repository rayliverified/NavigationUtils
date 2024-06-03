import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:navigation_utils/navigation_utils.dart';

import 'initialization.dart';
import 'navigation_routes.dart' as navigation_routes;
import 'pages/auth/auth_components.dart';
import 'services/auth_service.dart';
import 'services/debug_logger.dart';
import 'ui/ui_page_wrapper.dart';

/// Test Credentials
/// test@testuser.com
/// 12345678

Future<void> main() async =>
    Initialization.main(const App(), preInitFunction: () {
      /// Set log controls for debugging.
      Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print(record.message);
      });
      if (kDebugMode) {
        // DebugLogger.instance.config.setHighlight(name: AuthService.name);
      }
    }, postInitFunction: () async {});

class App extends StatefulWidget {
  static const String name = 'app';

  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  /// First time initialization flag.
  bool initialized = false;
  bool loadInitialRoute = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    DebugLogger.instance.printFunction('initState', name: App.name);
    // Attach navigation callback that hooks into the app state.
    NavigationManager.instance.setMainRoutes =
        (routes) => setMainRoutes(routes);
    // Navigate after authentication and user model loads.
    AuthService.instance.firebaseAuthUserStream
        .asBroadcastStream()
        .listen(_firebaseAuthUserListener);
    init();
  }

  Future<void> init() async {
    // Initialize app cycle dependent initialization here.
  }

  @override
  void dispose() {
    GetIt.instance.reset();
    super.dispose();
  }

  Future<void> _firebaseAuthUserListener(User? user) async {
    DebugLogger.instance.printInfo('firebaseAuthUserListener: $user');
    // Attempt to load the initial route URI.
    if (loadInitialRoute) {
      loadInitialRoute = false;
      initialized = true;
      String initialRoute =
          NavigationManager.instance.routeInformationParser.initialRoute;
      DebugLogger.instance.printInfo('Initial Route: $initialRoute');
      NavigationManager.instance.set([initialRoute]);
      NavigationManager.instance.resumeNavigation();
    } else if (AuthService.instance.isAuthenticated.value) {
      NavigationManager.instance.set([HomePage.name]);
    }
    // Automatically navigate to auth screen when user is logged out.
    if (AuthService.instance.isAuthenticated.value == false) {
      if (NavigationManager.instance.currentRoute?.metadata?['auth'] == true) {
        NavigationManager.instance.set([SignUpForm.name]);
      }
    }
  }

  List<DefaultRoute> setMainRoutes(List<DefaultRoute> routes) {
    DebugLogger.instance
        .printFunction('setMainRoutes: $routes', name: App.name);
    List<DefaultRoute> routesHolder = routes;
    // Authenticated route guard.
    if (AuthService.instance.isAuthenticated.value == false &&
        initialized == true) {
      routesHolder.removeWhere((element) => element.metadata?['auth'] == true);
      if (routesHolder.isEmpty) {
        routesHolder.add(DefaultRoute(label: SignUpForm.name, path: '/signup'));
      }
    }
    // Remove login and signup page guard.
    if (AuthService.instance.isAuthenticated.value) {
      routesHolder
          .removeWhere((element) => element.metadata?['type'] == 'auth');
      if (routesHolder.isEmpty) {
        routesHolder.add(NavigationUtils.buildDefaultRouteFromName(
            navigation_routes.routes, '/'));
      }
    }
    DebugLogger.instance
        .printFunction('Set Routes New: $routes', name: App.name);
    return routesHolder;
  }

  @override
  Widget build(BuildContext context) {
    // On Android 10+, extend background color into bottom bar area.
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: true,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark));

    return MaterialApp.router(
      title: 'Example Auth',
      routerDelegate: NavigationManager.instance.routerDelegate,
      routeInformationParser: NavigationManager.instance.routeInformationParser,
    );
  }
}

class HomePage extends StatefulWidget {
  static const String name = 'home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Home Page'),
              MaterialButton(
                onPressed: AuthService.instance.signOut,
                color: Colors.blue,
                child:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
