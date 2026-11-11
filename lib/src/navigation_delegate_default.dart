// ignore_for_file: overridden_fields

import 'package:flutter/material.dart';

import 'models/model_deeplink.dart';
import 'navigation_builder.dart';
import 'navigation_delegate.dart';
import 'utils.dart';

/// Default implementation of [BaseRouterDelegate].
///
/// This class provides a complete router delegate implementation with
/// support for deeplinks, custom page builders, and navigation observers.
class DefaultRouterDelegate extends BaseRouterDelegate {
  @override
  List<NavigationData> navigationDataRoutes = [];

  @override
  bool debugLog = false;

  @override
  OnUnknownRoute? onUnknownRoute;

  /// Optional custom page builder for all routes.
  CustomPageBuilder? pageBuilder;

  /// Optional migration page builder for legacy route support.
  MigrationPageBuilder? migrationPageBuilder;

  /// List of navigation observers to attach to the Navigator.
  List<NavigatorObserver> observers;

  /// List of deeplink destinations to handle.
  List<DeeplinkDestination> deeplinkDestinations;

  /// Optional custom deeplink handler function.
  ///
  /// If provided, this function is called for all incoming deeplinks.
  /// Return `true` if the deeplink was handled, `false` otherwise.
  bool? Function(Uri uri)? customDeeplinkHandler;

  /// Whether the user is currently authenticated.
  ///
  /// Used to determine if authenticated deeplinks can be opened.
  bool authenticated;

  /// List of route names/paths to exclude from deeplink navigation.
  List<String> excludeDeeplinkNavigationPages;

  /// Optional callback for handling pop page events.
  PopPageCallback? onPopPage;

  /// The page produced by [pageOverlay] on the last Navigator build.
  Page<dynamic>? _builtOverlayPage;

  /// Creates a [DefaultRouterDelegate] with the given configuration.
  ///
  /// [navigationDataRoutes] - List of navigation routes (required).
  /// [debugLog] - Whether to enable debug logging.
  /// [onUnknownRoute] - Handler for unknown routes.
  /// [pageBuilder] - Custom page builder.
  /// [migrationPageBuilder] - Migration page builder for legacy routes.
  /// [observers] - Navigation observers.
  /// [deeplinkDestinations] - Deeplink destinations to handle.
  /// [customDeeplinkHandler] - Custom deeplink handler.
  /// [authenticated] - Whether user is authenticated.
  /// [excludeDeeplinkNavigationPages] - Routes to exclude from deeplink navigation.
  /// [onPopPage] - Pop page callback.
  DefaultRouterDelegate({
    required this.navigationDataRoutes,
    this.debugLog = false,
    this.onUnknownRoute,
    this.pageBuilder,
    this.migrationPageBuilder,
    this.observers = const [],
    this.deeplinkDestinations = const [],
    this.customDeeplinkHandler,
    this.authenticated = true,
    this.excludeDeeplinkNavigationPages = const [],
    this.onPopPage,
  });

  @override
  Widget build(BuildContext context) {
    if (debugLog) {
      debugPrint(
          'NavigationUtils Build: Current Route: ${routes.last} Routes: $routes');
    }

    _builtOverlayPage = pageOverlay?.call(currentConfiguration?.name ?? '');
    return Navigator(
      key: navigatorKey,
      pages: [
        if (pageOverride != null)
          pageOverride!(currentConfiguration?.name ?? '')
        else ...[
          ...NavigationBuilder.build(
            context: context,
            routeDataList: routes,
            routes: navigationDataRoutes,
            pageBuilder: pageBuilder,
            migrationPageBuilder: migrationPageBuilder,
            onUnknownRoute: onUnknownRoute ?? _buildUnknownRouteDefault,
          ),
          if (_builtOverlayPage != null) _builtOverlayPage!
        ],
      ],
      onPopPage: (route, result) {
        if (onPopPage?.call(route, result) == false) {
          return false;
        }
        // If the route handled pop internally, return false.
        if (route.didPop(result) == false) {
          return false;
        }
        // An overlay is a Page in the Navigator, but not a route in the
        // manager's stack. Removing the top managed route here would expose a
        // stale page and leave the overlay blocking the screen after back.
        final settings = route.settings;
        if (_builtOverlayPage != null &&
            (identical(settings, _builtOverlayPage) ||
                (settings is Page &&
                    settings.key != null &&
                    settings.key == _builtOverlayPage!.key))) {
          removeOverlay();
          return true;
        }
        pop(result);
        return true;
      },
      observers: observers,
    );
  }

  @override
  Future<void> setNewRoutePath(DefaultRoute configuration) async {
    bool? openedCustomDeeplink =
        customDeeplinkHandler?.call(configuration.uri) ?? false;
    if (openedCustomDeeplink) {
      // When the user provides a custom deeplink handler, they can process the deeplink without navigating or handle asynchronously.
      // Initial app open requires a route to be set so fallback and set route.
      if (routes.isEmpty) {
        return super.setNewRoutePath(configuration);
      }
      return;
    }

    DeeplinkDestination? deeplinkDestination;
    if (deeplinkDestinations.isNotEmpty) {
      deeplinkDestination = NavigationUtils.getDeeplinkDestinationFromUri(
          deeplinkDestinations, configuration.uri);
    }

    if (deeplinkDestinations.isNotEmpty && deeplinkDestination != null) {
      NavigationUtils.openDeeplinkDestination(
          uri: configuration.uri,
          deeplinkDestinations: deeplinkDestinations,
          routerDelegate: this,
          deeplinkDestination: deeplinkDestination,
          authenticated: authenticated,
          currentRoute: currentConfiguration,
          excludeDeeplinkNavigationPages: excludeDeeplinkNavigationPages);
      return;
    }

    return super.setNewRoutePath(configuration);
  }

  /// Default handler for unknown routes.
  ///
  /// Displays a 404 page with a back button.
  /// Override [onUnknownRoute] to provide custom unknown route handling.
  Page<dynamic> _buildUnknownRouteDefault(DefaultRoute route) {
    return MaterialPage(
      name: route.name,
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '404',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              Container(
                height: 15,
              ),
              ElevatedButton(
                onPressed: () =>
                    routes.length > 1 ? pop() : pushReplacement('/'),
                child: const Text('Back', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
