import 'dart:async';

import 'package:example_auth/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigation_utils/navigation_utils.dart';

import 'navigation_routes.dart';
import 'repositories/firebase_repository_base.dart';

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

    await FirebaseRepositoryBase.initialize();
    AuthService.initialize();

    NavigationManager.init(
        mainRouterDelegate: DefaultRouterDelegate(navigationDataRoutes: routes),
        routeInformationParser: DefaultRouteInformationParser());

    // Run post functions.
    await postInitFunction?.call();
    runApp(app);
  }
}
