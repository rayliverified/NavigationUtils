import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation_utils/navigation_utils.dart';
import 'package:provider/provider.dart';

import 'initialization.dart';
import 'models/model_user.dart';
import 'navigation_routes.dart';
import 'services/auth_service.dart';
import 'services/debug_logger.dart';
import 'ui/ui_page_wrapper.dart';

Future<void> main() async =>
    Initialization.main(const AppWrapper(), preInitFunction: () {
      /// Set log controls for debugging.
      DebugLogger.config = DebugLoggerConfig(
          printRebuilds: true, printActions: true, printFunctions: true);
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
    print('Init App');
    init();
  }

  @override
  Future<void> init() async {
    print('Init App Model');
    // Attach navigation callback that hooks into the app state.
    NavigationManager.instance.routerDelegate.setMainRoutes =
        (routes) => setMainRoutes(routes);
    // Set initialization page.
    print('Initialized: $initialized');
    NavigationManager.instance.routerDelegate
        .setOverride(const InitializationPage());
    // Navigate after authentication and user model loads.
    authService.firebaseAuthUserStream.listen(_userModelListener);
    // Get saved auth state, if any.
    // AuthResult authResult = await authService.initAuthState();
    // // No saved auth state. Redirect to unauthenticated start page.
    // if (authResult.success) {
    // } else {
    //   NavigationManager.instance.routerDelegate.set([SignUpForm.name]);
    // }
  }

  @override
  void dispose() {
    GetIt.instance.reset();
    super.dispose();
  }

  Future<void> _userModelListener(User? user) async {
    UserModel userModel = authService.userModel.value;
    print('User Model Stream: $userModel');
    print('User Model Stream Initialized');
    // Attempt to load the initial route URI.
    if (loadInitialRoute) {
      loadInitialRoute = false;
      Uri initialRouteUri =
          NavigationManager.instance.routeInformationParser.initialRouteUri;
      print('Initial Route URI: $initialRouteUri');
      if (initialRouteUri.pathSegments.isNotEmpty) {
        NavigationManager.instance.routerDelegate.set([initialRouteUri.path]);
      }
      NavigationManager.instance.routerDelegate.removeOverride();
    }
  }

  List<DefaultRoute> setMainRoutes(List<DefaultRoute> routes) {
    print('Set Main Routes: $routes');
    List<DefaultRoute> routesHolder = routes;
    // Authenticated route guard.
    if (AuthService.instance.isAuthenticated == false) {
      routesHolder.removeWhere((element) => element.metadata?['auth'] == true);
      if (routesHolder.isEmpty) {
        routesHolder.add(DefaultRoute(label: SignUpForm.name, path: '/signup'));
      }
    }
    print('Final Main Routes: $routes');
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
    return const PageWrapper(
      child: Center(
        child: Text('Home Page'),
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
        child: Center(
          child: Column(
            children: [
              Text(
                model.errorMessage ?? 'Unknown error. Please try again.',
                style: Theme.of(context).textTheme.bodyText1,
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
      ),
    );
  }
}
