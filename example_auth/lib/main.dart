import 'package:example_auth/pages/auth/auth_components.dart';
import 'package:example_auth/services/auth_service.dart';
import 'package:example_auth/services/shared_preferences_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation_utils/navigation_utils.dart';

import 'initialization.dart';
import 'navigation_routes.dart' as navigation_routes;
import 'services/debug_logger.dart';
import 'ui/ui_page_wrapper.dart';
import 'utils/value_response.dart';

Future<void> main() async =>
    Initialization.main(const App(), preInitFunction: () {
      /// Set log controls for debugging.
      DebugLogger.config = DebugLoggerConfig(
          printRebuilds: true,
          printActions: true,
          printFunctions: true,
          printInProduction: true,
          printInfo: true);
    }, postInitFunction: () async {
      ValueResponse signInResponse = await AuthService.instance
          .signInWithEmailAndPassword('test@testuser.com', '12345678');
      if (signInResponse.isError) {
        debugPrint('Sign In Error: ${signInResponse.error.toString()}');
      }
    });

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  /// First time initialization flag.
  bool initialized = false;
  bool loadInitialRoute = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    DebugLogger.instance.printFunction('initState');
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
    SharedPreferencesHelper.instance.get('user');
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
    DebugLogger.instance.printFunction('Set Routes Old: $routes');
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
    DebugLogger.instance.printFunction('Set Routes New: $routes');
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
