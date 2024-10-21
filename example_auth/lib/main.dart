import 'dart:async';

import 'package:example_auth/models/model_user.dart';
import 'package:example_auth/services/signout_helper.dart';
import 'package:example_auth/services/user_manager.dart';
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

  late StreamSubscription navigationListener;
  late StreamSubscription<String?> firebaseAuthUserListener;
  late StreamSubscription<UserModel> userCreatedListener;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    DebugLogger.instance.printFunction('init', name: App.name);
    // Attach navigation callback that hooks into the app state.
    NavigationManager.instance.setMainRoutes =
        (routes) => setMainRoutes(routes);

    firebaseAuthUserListener = AuthService.instance.firebaseAuthUserStream
        .listen((uid) =>
            uid != null ? onUserAuthenticated(uid) : onUserUnauthenticated());
    userCreatedListener =
        AuthService.instance.userCreatedStream.listen((userModel) {});

    // Set initialization page.
    if (AuthService.instance.isAuthenticated.value) {
      onUserAuthenticated(UserManager.instance.user.value.id);
    } else {
      if (UserManager.instance.user.value.empty == false) {
        // Wait for FirebaseAuth to initialize. FirebaseAuth MUST initialize otherwise Firestore calls fail.
        NavigationManager.instance.pauseNavigation();
      } else {
        NavigationManager.instance.set([SignUpForm.name]);
      }
    }
  }

  @override
  void dispose() {
    firebaseAuthUserListener.cancel();
    userCreatedListener.cancel();
    navigationListener.cancel();
    GetIt.instance.reset();
    super.dispose();
  }

  Future<void> onUserAuthenticated(String uid) async {
    // Attempt to load the initial route URI.
    if (loadInitialRoute) {
      loadInitialRoute = false;
      initialized = true;
      String initialRoute =
          NavigationManager.instance.routeInformationParser.initialRoute;
      DebugLogger.instance.printInfo('Initial Route: $initialRoute');
      NavigationManager.instance.set([initialRoute]);
    } else {
      NavigationManager.instance.set([HomePage.name]);
    }

    DebugLogger.instance.printInfo('Resume Navigation');

    NavigationManager.instance.resumeNavigation();
  }

  Future<void> onUserUnauthenticated() async {
    // Automatically navigate to auth screen when user is logged out.
    if (NavigationManager.instance.currentRoute?.metadata?['auth'] == true) {
      NavigationManager.instance.set([SignUpForm.name]);
    }
    NavigationManager.instance.resumeNavigation();
    // This function can be called multiple times by the Auth library so it is not safe to rely on for signout.
    // Instead, call the signout function. This calls this signout function duplicate times so the signout
    // function must handle correctly.
    SignoutHelper.signOut();
  }

  List<DefaultRoute> setMainRoutes(List<DefaultRoute> routes) {
    DebugLogger.instance.printFunction('setMainRoutes(routes: $routes)',
        name: NavigationManager.name);
    List<DefaultRoute> routesHolder = routes;
    // Authenticated route guard.
    if (AuthService.instance.isAuthenticated.value == false) {
      routesHolder.removeWhere((element) => element.metadata?['auth'] == true);
      if (routesHolder.isEmpty) {
        routesHolder.add(DefaultRoute(label: SignUpForm.name, path: '/signup'));
        // Handle edge case where UserModel is cached but FirebaseAuth has logged out.
        NavigationManager.instance.resumeNavigation();
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
    DebugLogger.instance.printFunction('setMainRoutesNew(routes: $routes)',
        name: NavigationManager.name);
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
    return const PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Home Page'),
              MaterialButton(
                onPressed: SignoutHelper.signOut,
                color: Colors.blue,
                child:
                    Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
