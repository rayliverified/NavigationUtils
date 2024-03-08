// ignore_for_file: overridden_fields

import 'package:flutter/material.dart';

import 'model_deeplink.dart';
import 'navigation_builder.dart';
import 'navigation_delegate.dart';
import 'utils.dart';

class DefaultRouterDelegate extends BaseRouterDelegate {
  @override
  List<NavigationData> navigationDataRoutes = [];

  @override
  bool debugLog = false;

  @override
  OnUnknownRoute? onUnknownRoute;

  NavigationPageBuilder? pageBuilder;

  List<NavigatorObserver> observers;

  List<DeeplinkDestination> deeplinkDestinations;

  bool? Function(Uri uri)? customDeeplinkHandler;

  bool authenticated;

  List<String> excludeDeeplinkNavigationPages;

  DefaultRouterDelegate(
      {required this.navigationDataRoutes,
      this.debugLog = false,
      this.onUnknownRoute,
      this.pageBuilder,
      this.observers = const [],
      this.deeplinkDestinations = const [],
      this.customDeeplinkHandler,
      this.authenticated = true,
      this.excludeDeeplinkNavigationPages = const []});

  @override
  Widget build(BuildContext context) {
    if (debugLog) debugPrint('NavigationUtils: Build Navigation: $routes');

    return Navigator(
      key: navigatorKey,
      pages: [
        if (pageOverride != null)
          pageOverride!(currentConfiguration?.name ?? '')
        else ...[
          ...NavigationBuilder(
            routeDataList: routes,
            routes: navigationDataRoutes,
            pageBuilder: pageBuilder,
            onUnknownRoute: onUnknownRoute ?? _buildUnknownRouteDefault,
          ).build(context),
          if (pageOverlay != null)
            pageOverlay!(currentConfiguration?.name ?? '')
        ],
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        if (canPop) {
          pop(result);
        }
        return true;
      },
      observers: observers,
    );
  }

  @override
  Future<void> setNewRoutePath(DefaultRoute configuration) async {
    bool? openedCustomDeeplink =
        customDeeplinkHandler?.call(configuration.uri) ?? false;
    if (openedCustomDeeplink) return;

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
      return Future.value();
    }

    return super.setNewRoutePath(configuration);
  }

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
