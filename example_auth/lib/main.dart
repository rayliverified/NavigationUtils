import 'package:example_auth/pages/auth/auth_components.dart';
import 'package:example_auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation_utils/navigation_utils.dart';
import 'package:provider/provider.dart';

import 'initialization.dart';
import 'models/model_user.dart';
import 'services/debug_logger.dart';
import 'ui/ui_page_wrapper.dart';

Future<void> main() async =>
    Initialization.main(const AppWrapper(), preInitFunction: () {
      /// Set log controls for debugging.
      DebugLogger.config = DebugLoggerConfig(
          printRebuilds: true,
          printActions: true,
          printFunctions: true,
          printInProduction: true,
          printInfo: true);
    });

/// Provide [AppModel] to [App].
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppModelBase>(
      create: (context) => AppModel(context: context),
      lazy:
          false, // IMPORTANT: By default, models are created only when called. AppModel needs to be initialized before layout.
      child: const App(),
    );
  }
}

abstract class AppModelBase with ChangeNotifier {
  BuildContext? context;

  /// First time initialization flag.
  bool initialized = false;

  bool loadInitialRoute = true;

  String? errorMessage;

  AppModelBase({this.context});

  Future<void> init();
}

class AppModel extends AppModelBase {
  final AuthServiceBase authService = GetIt.instance.get<AuthServiceBase>();

  AppModel({super.context}) {
    init();
  }

  @override
  Future<void> init() async {
    DebugLogger.instance.printFunction('Init App');
    // Attach navigation callback that hooks into the app state.
    NavigationManager.instance.routerDelegate.setMainRoutes =
        (routes) => setMainRoutes(routes);
    // Set initialization page.
    NavigationManager.instance.routerDelegate
        .setOverride(const InitializationPage());
    // Navigate after authentication and user model loads.
    authService.firebaseAuthUserStream
        .asBroadcastStream()
        .listen(_userModelListener);
  }

  @override
  void dispose() {
    GetIt.instance.reset();
    super.dispose();
  }

  Future<void> _userModelListener(User? user) async {
    UserModel userModel = authService.userModel.value;
    DebugLogger.instance.printInfo('User Model Stream: $userModel');
    // Attempt to load the initial route URI.
    if (loadInitialRoute) {
      loadInitialRoute = false;
      Uri initialRouteUri =
          NavigationManager.instance.routeInformationParser.initialRouteUri;
      DebugLogger.instance.printInfo('Initial Route URI: $initialRouteUri');
      NavigationManager.instance.routerDelegate.set([initialRouteUri.path]);
      NavigationManager.instance.routerDelegate.removeOverride();
    }
    // Automatically navigate to auth screen when user is logged out.
    if (AuthService.instance.isAuthenticated == false) {
      if (NavigationManager.instance.routerDelegate.currentConfiguration
              ?.metadata?['auth'] ==
          true) {
        NavigationManager.instance.routerDelegate.set([SignUpForm.name]);
      }
    }
  }

  List<DefaultRoute> setMainRoutes(List<DefaultRoute> routes) {
    DebugLogger.instance.printFunction('Set Main Routes Old: $routes');
    List<DefaultRoute> routesHolder = routes;
    // Authenticated route guard.
    if (AuthService.instance.isAuthenticated == false) {
      routesHolder.removeWhere((element) => element.metadata?['auth'] == true);
      if (routesHolder.isEmpty) {
        routesHolder.add(DefaultRoute(label: SignUpForm.name, path: '/signup'));
      }
    }
    // Remove login and signup page guard.
    if (AuthService.instance.isAuthenticated) {
      routesHolder
          .removeWhere((element) => element.metadata?['type'] == 'auth');
      if (routesHolder.isEmpty) {
        routesHolder.add(DefaultRoute(label: HomePage.name, path: '/'));
      }
    }
    DebugLogger.instance.printFunction('Set Main Routes New: $routes');
    return routesHolder;
  }
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
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

  const HomePage({Key? key}) : super(key: key);

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
                onPressed: () {
                  AuthService.instance.signOut();
                },
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

/// Initialization placeholder with a loading indicator.
///
/// Used to resolve loading destination.
class InitializationPage extends StatelessWidget {
  static const String name = 'initialization';

  const InitializationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

/// Initialization placeholder with a loading indicator.
///
/// Used to resolve loading destination.
class InitializationErrorPage extends StatelessWidget {
  static const String name = 'initialization_error';

  const InitializationErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppModelBase model =
        Provider.of<AppModelBase>(context, listen: false);

    return PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              model.errorMessage ?? 'Unknown error. Please try again.',
              style: Theme.of(context).textTheme.headline4,
              textAlign: TextAlign.center,
            ),
            Container(
              height: 15,
            ),
            TextButton(
              onPressed: model.init,
              child: const Text('Reload',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

class UnknownPage extends StatelessWidget {
  static const String name = 'unknown';

  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '404',
              style: Theme.of(context).textTheme.headline1,
              textAlign: TextAlign.center,
            ),
            Container(
              height: 15,
            ),
            MaterialButton(
              onPressed: () => NavigationManager.instance.routerDelegate.pop(),
              color: Colors.blue,
              child: const Text('Back',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
