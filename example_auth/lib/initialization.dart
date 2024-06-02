import 'dart:async';

import 'package:example_auth/services/shared_preferences_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:navigation_utils/navigation_utils.dart';

import 'firebase_options.dart';
import 'navigation_routes.dart';
import 'pages/page_initializaton.dart';
import 'services/auth_service.dart';

class Initialization {
  /// Initialization wrapper for consolidating main setup code.
  /// [preInitFunction] runs before all initialization code. Run
  /// init configuration code here.
  /// [postInitFunction] runs after initialization code. Run code that
  /// depends on Managers here. [AsyncCallback] allows us to wait until
  /// managers are initialized.
  static Future<void> main(Widget app,
      {Function? preInitFunction, AsyncCallback? postInitFunction}) async {
    // This creates a [Zone] that contains the Flutter
    // application and establishes an error handler
    // that captures errors and reports them.
    WidgetsFlutterBinding.ensureInitialized();

    // Run pre-initialization functions.
    preInitFunction?.call();

    if (kIsWeb) {
      usePathUrlStrategy();
    }

    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      SharedPreferencesHelper.init(),
    ]);

    AuthService.instance.init();

    NavigationManager.init(
        mainRouterDelegate: DefaultRouterDelegate(
          navigationDataRoutes: routes,
          debugLog: true,
          onUnknownRoute: (route) => const MaterialPage(
              name: '/${UnknownPage.name}', child: UnknownPage()),
          authenticated: AuthService.instance.isAuthenticated,
        ),
        routeInformationParser: DefaultRouteInformationParser(debugLog: true));
    NavigationManager.instance.pauseNavigation();

    // Run post functions.
    await postInitFunction?.call();
    runApp(app);
  }
}
