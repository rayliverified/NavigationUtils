import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

// Mock router delegate for testing
class MockRouterDelegate extends BaseRouterDelegate {
  List<String> pushedRoutes = [];
  List<String> pushedUrls = [];
  bool applyCalled = false;
  Map<String, dynamic> lastPushData = {};
  // ignore: prefer_final_fields
  List<DefaultRoute> _mockRoutes = [];

  @override
  List<DefaultRoute> get routes => _mockRoutes;

  @override
  Widget build(BuildContext context) => Container();

  @override
  Future<dynamic> push(String name,
      {Map<String, String>? queryParameters,
      Object? arguments,
      Map<String, dynamic> data = const {},
      Map<String, String> pathParameters = const {},
      bool apply = true}) async {
    // For testing purposes, don't require navigation data to exist
    NavigationData? navigationData =
        NavigationUtils.getNavigationDataFromName(navigationDataRoutes, name);

    String path;
    if (navigationData != null) {
      // Use the real logic if navigation data exists
      if (name.startsWith('/') && name.contains(':') == false) {
        path = name;
      } else if (navigationData.path.contains(':')) {
        // Simple pattern replacement for testing
        path = navigationData.path;
        pathParameters.forEach((key, value) {
          path = path.replaceAll(':$key', value);
        });
      } else {
        path = navigationData.path;
      }
    } else {
      // For testing, create a simple path if navigation data doesn't exist
      path = name.startsWith('/') ? name : '/$name';
    }

    pushedRoutes.add(name);
    lastPushData = {
      'name': name,
      'path': path,
      'queryParameters': queryParameters,
      'arguments': arguments,
      'data': data,
      'pathParameters': pathParameters,
      'apply': apply,
    };

    // Create a mock route and add it to the routes list
    DefaultRoute route = DefaultRoute(
      label: navigationData?.label ?? name,
      path: path,
      pathParameters: pathParameters,
      queryParameters: queryParameters ?? {},
      arguments: arguments,
    );
    _mockRoutes.add(route);

    if (apply) {
      applyCalled = true;
      onRouteChanged(route);
    }
    return null;
  }

  @override
  void apply() {
    if (_mockRoutes.isNotEmpty) {
      applyCalled = true;
      onRouteChanged(_mockRoutes.last);
    }
  }

  void reset() {
    pushedRoutes.clear();
    pushedUrls.clear();
    applyCalled = false;
    lastPushData.clear();
    _mockRoutes.clear();
  }
}

void main() {
  late MockRouterDelegate mockRouterDelegate;

  setUp(() {
    mockRouterDelegate = MockRouterDelegate();
  });

  tearDown(() {
    mockRouterDelegate.reset();
  });

  group('getDeeplinkDestination', () {
    test('Empty', () {
      // Method should not crash when null.
      NavigationUtils.getDeeplinkDestinationFromUrl([], null);
      NavigationUtils.getDeeplinkDestinationFromUrl([], '');
      NavigationUtils.getDeeplinkDestinationFromUri([], null);
      NavigationUtils.getDeeplinkDestinationFromUri([], Uri());
    });
    test('Match Path Parameter', () {
      DeeplinkDestination deeplinkDestination = const DeeplinkDestination(
          deeplinkUrl: '/link/post/:postId', destinationUrl: '/post/:postId');
      List<DeeplinkDestination> deeplinkDestinations = [
        deeplinkDestination,
      ];

      // Match post ID.
      expect(
          NavigationUtils.getDeeplinkDestinationFromUrl(
              deeplinkDestinations, '/link/post/1'),
          deeplinkDestination);

      // Match post ID with trailing slash.
      expect(
          NavigationUtils.getDeeplinkDestinationFromUrl(
              deeplinkDestinations, '/link/post/1/'),
          deeplinkDestination);

      // No post ID, do not match.
      expect(
          NavigationUtils.getDeeplinkDestinationFromUrl(
              deeplinkDestinations, '/link/post'),
          null);
    });
  });

  group('openDeeplinkDestination', () {
    test('Function call only', () async {
      bool functionCalled = false;
      Map<String, String> capturedPathParams = {};
      Map<String, String> capturedQueryParams = {};

      final deeplinkDestination = DeeplinkDestination(
        deeplinkUrl: '/test/function/:id',
        runFunction: (pathParameters, queryParameters) async {
          functionCalled = true;
          capturedPathParams = pathParameters;
          capturedQueryParams = queryParameters;
        },
      );

      final deeplinkDestinations = [deeplinkDestination];
      final uri = Uri.parse('/test/function/123?source=app&version=1.0');

      // First check if we can find the deeplink destination
      final foundDestination = NavigationUtils.getDeeplinkDestinationFromUri(
          deeplinkDestinations, uri);
      expect(foundDestination, isNotNull);
      expect(foundDestination!.deeplinkUrl, '/test/function/:id');

      final result = NavigationUtils.openDeeplinkDestination(
        uri: uri,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: mockRouterDelegate,
      );

      expect(result, true);
      expect(functionCalled, true);
      expect(capturedPathParams['id'], '123');
      expect(capturedQueryParams['source'], 'app');
      expect(capturedQueryParams['version'], '1.0');
      // Should not navigate
      expect(mockRouterDelegate.pushedRoutes, isEmpty);
    });

    test('Navigation and function call', () async {
      bool functionCalled = false;
      Map<String, String> capturedPathParams = {};
      Map<String, String> capturedQueryParams = {};

      final deeplinkDestination = DeeplinkDestination(
        deeplinkUrl: '/test/both/:id',
        destinationLabel: 'test_page',
        runFunction: (pathParameters, queryParameters) async {
          functionCalled = true;
          capturedPathParams = pathParameters;
          capturedQueryParams = queryParameters;
        },
      );

      final deeplinkDestinations = [deeplinkDestination];
      final uri = Uri.parse('/test/both/456?type=premium&campaign=summer');

      final result = NavigationUtils.openDeeplinkDestination(
        uri: uri,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: mockRouterDelegate,
      );

      // Wait for async function to complete
      await Future.delayed(Duration.zero);

      expect(result, true);
      // Should navigate first
      expect(mockRouterDelegate.pushedRoutes, ['test_page']);
      // Then function should be called
      expect(functionCalled, true);
      expect(capturedPathParams['id'], '456');
      expect(capturedQueryParams['type'], 'premium');
      expect(capturedQueryParams['campaign'], 'summer');
    });

    test('Function call with redirect', () async {
      bool functionCalled = false;
      Map<String, String> capturedPathParams = {};
      Map<String, String> capturedQueryParams = {};

      final deeplinkDestination = DeeplinkDestination(
        deeplinkUrl: '/test/redirect/:id',
        destinationLabel: 'original_page',
        redirectFunction: (pathParameters, queryParameters, redirect) async {
          // Simulate redirect logic
          if (pathParameters['id'] == '999') {
            redirect(
              label: 'redirected_page',
              pathParameters: pathParameters,
              queryParameters: queryParameters,
            );
            return true;
          }
          return false;
        },
        runFunction: (pathParameters, queryParameters) async {
          functionCalled = true;
          capturedPathParams = pathParameters;
          capturedQueryParams = queryParameters;
        },
      );

      final deeplinkDestinations = [deeplinkDestination];
      final uri = Uri.parse('/test/redirect/999?source=redirect_test');

      final result = NavigationUtils.openDeeplinkDestination(
        uri: uri,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: mockRouterDelegate,
      );

      // Wait for async operations to complete
      await Future.delayed(Duration.zero);

      expect(result, true);
      // Should redirect to different page
      expect(mockRouterDelegate.pushedRoutes, ['redirected_page']);
      expect(mockRouterDelegate.applyCalled, true);
      // Function should still be called after redirect
      expect(functionCalled, true);
      expect(capturedPathParams['id'], '999');
      expect(capturedQueryParams['source'], 'redirect_test');
    });

    test(
        'runFunction is called even when shouldNavigateDeeplinkFunction returns false',
        () async {
      bool functionCalled = false;
      bool shouldNavigateCalled = false;
      Map<String, String> capturedPathParams = {};
      Map<String, String> capturedQueryParams = {};

      final deeplinkDestination = DeeplinkDestination(
        deeplinkUrl: '/test/blocked/:id',
        destinationLabel: 'blocked_page',
        shouldNavigateDeeplinkFunction: (uri, pathParameters, queryParameters) {
          shouldNavigateCalled = true;
          // Block navigation
          return false;
        },
        runFunction: (pathParameters, queryParameters) async {
          functionCalled = true;
          capturedPathParams = pathParameters;
          capturedQueryParams = queryParameters;
        },
      );

      final deeplinkDestinations = [deeplinkDestination];
      final uri = Uri.parse('/test/blocked/789?analytics=track&event=click');

      final result = NavigationUtils.openDeeplinkDestination(
        uri: uri,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: mockRouterDelegate,
      );

      // Wait for async function to complete
      await Future.delayed(Duration.zero);

      // openDeeplinkDestination should return false because navigation is blocked
      expect(result, false);
      // shouldNavigateDeeplinkFunction should have been called
      expect(shouldNavigateCalled, true);
      // Navigation should NOT have happened
      expect(mockRouterDelegate.pushedRoutes, isEmpty);
      expect(mockRouterDelegate.applyCalled, false);

      // BUT runFunction SHOULD still be called despite navigation being blocked
      expect(functionCalled, true);
      expect(capturedPathParams['id'], '789');
      expect(capturedQueryParams['analytics'], 'track');
      expect(capturedQueryParams['event'], 'click');
    });

    test('No matching deeplink destination', () {
      final deeplinkDestination = DeeplinkDestination(
        deeplinkUrl: '/test/match',
        destinationLabel: 'test_page',
      );

      final deeplinkDestinations = [deeplinkDestination];
      final uri = Uri.parse('/test/no-match');

      final result = NavigationUtils.openDeeplinkDestination(
        uri: uri,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: mockRouterDelegate,
      );

      expect(result, false);
      expect(mockRouterDelegate.pushedRoutes, isEmpty);
      expect(mockRouterDelegate.applyCalled, false);
    });

    test('Null URI handling', () {
      final deeplinkDestination = DeeplinkDestination(
        deeplinkUrl: '/test/null',
        destinationLabel: 'test_page',
      );

      final deeplinkDestinations = [deeplinkDestination];

      final result = NavigationUtils.openDeeplinkDestination(
        uri: null,
        deeplinkDestinations: deeplinkDestinations,
        routerDelegate: mockRouterDelegate,
      );

      expect(result, false);
      expect(mockRouterDelegate.pushedRoutes, isEmpty);
      expect(mockRouterDelegate.applyCalled, false);
    });
  });
}
