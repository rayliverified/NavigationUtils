import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

/// Tests for custom pageBuilder with grouped routes
///
/// These tests verify that grouped routes work correctly when using custom
/// page builders. This is a critical test because many apps use custom page
/// builders to control transitions (e.g., NoTransitionPage).

// Test widget that tracks lifecycle events
class LifecycleTrackingWidget extends StatefulWidget {
  final String identifier;
  final VoidCallback? onInit;
  final VoidCallback? onUpdate;
  final VoidCallback? onDispose;

  const LifecycleTrackingWidget({
    Key? key,
    required this.identifier,
    this.onInit,
    this.onUpdate,
    this.onDispose,
  }) : super(key: key);

  @override
  State<LifecycleTrackingWidget> createState() =>
      _LifecycleTrackingWidgetState();
}

class _LifecycleTrackingWidgetState extends State<LifecycleTrackingWidget> {
  late String _currentIdentifier;

  @override
  void initState() {
    super.initState();
    _currentIdentifier = widget.identifier;
    widget.onInit?.call();
  }

  @override
  void didUpdateWidget(LifecycleTrackingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentIdentifier = widget.identifier;
    widget.onUpdate?.call();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current: $_currentIdentifier'),
            Text('Widget: ${widget.identifier}'),
          ],
        ),
      ),
    );
  }
}

/// BROKEN: Custom page that uses PageRouteBuilder (captures child in closure)
///
/// This demonstrates the WRONG way to implement a custom page.
/// The child is captured when createRoute is called and NEVER updates.
class BrokenNoTransitionPage extends Page<void> {
  final Widget child;

  const BrokenNoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    // PROBLEM: child is captured in the closure at this moment
    // Even when the Page is updated, this closure keeps the OLD child
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

/// CORRECT: Custom page that reads child at build time
///
/// This demonstrates the CORRECT way to implement a custom page.
/// The Route reads _page.child in buildPage(), getting the CURRENT child.
class CorrectNoTransitionPage extends Page<void> {
  final Widget child;

  const CorrectNoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    return _CorrectNoTransitionRoute(page: this);
  }
}

class _CorrectNoTransitionRoute extends PageRoute<void> {
  _CorrectNoTransitionRoute({required CorrectNoTransitionPage page})
      : super(settings: page);

  CorrectNoTransitionPage get _page => settings as CorrectNoTransitionPage;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // CORRECT: Read child from CURRENT page settings at build time
    // When Page is updated, settings points to the new Page with new child
    return _page.child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// CORRECT: Custom page with scale transition that reads child at build time
///
/// This demonstrates a custom transition animation that works correctly
/// with grouped routes because it reads _page.child at build time.
class ScaleTransitionPage extends Page<void> {
  final Widget child;

  const ScaleTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    return _ScaleTransitionRoute(page: this);
  }
}

class _ScaleTransitionRoute extends PageRoute<void> {
  _ScaleTransitionRoute({required ScaleTransitionPage page})
      : super(settings: page);

  ScaleTransitionPage get _page => settings as ScaleTransitionPage;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _page.child; // Read child from CURRENT page at build time
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return ScaleTransition(
      scale: animation,
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// CORRECT: Custom page with slide transition that reads child at build time
class RightToLeftTransitionPage extends Page<void> {
  final Widget child;

  const RightToLeftTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    return _RightToLeftRoute(page: this);
  }
}

class _RightToLeftRoute extends PageRoute<void> {
  _RightToLeftRoute({required RightToLeftTransitionPage page})
      : super(settings: page);

  RightToLeftTransitionPage get _page => settings as RightToLeftTransitionPage;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _page.child; // Read child at build time
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

void main() {
  group('Custom PageBuilder with Grouped Routes', () {
    testWidgets('CORRECT implementation: didUpdateWidget is called',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;
      int disposeCount = 0;

      // Router with custom pageBuilder using CORRECT implementation
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'login',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
              onDispose: () => disposeCount++,
            ),
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'signup',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
              onDispose: () => disposeCount++,
            ),
          ),
        ],
        pageBuilder: (key, name, child, routeData, globalData, arguments) {
          return CorrectNoTransitionPage(
            key: key,
            name: name,
            arguments: arguments,
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Navigate to login
      routerDelegate.push('login');
      await tester.pumpAndSettle();

      expect(find.text('Current: login'), findsOneWidget);
      expect(initCount, 1, reason: 'initState called once for initial page');

      final initCountBefore = initCount;
      final updateCountBefore = updateCount;

      // Switch to signup (same group)
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      // Verify didUpdateWidget was called, NOT initState
      expect(initCount, initCountBefore,
          reason: 'initState should NOT be called for grouped route switch');
      expect(updateCount, greaterThan(updateCountBefore),
          reason: 'didUpdateWidget SHOULD be called for grouped route switch');
      expect(disposeCount, 0,
          reason: 'dispose should NOT be called for grouped route switch');

      // Verify UI shows correct page
      expect(find.text('Current: signup'), findsOneWidget);
      expect(find.text('Widget: signup'), findsOneWidget);
    });

    testWidgets(
        'BROKEN implementation: initState is called instead of didUpdateWidget',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;
      int disposeCount = 0;

      // Router with custom pageBuilder using BROKEN implementation
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'login',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
              onDispose: () => disposeCount++,
            ),
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'signup',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
              onDispose: () => disposeCount++,
            ),
          ),
        ],
        pageBuilder: (key, name, child, routeData, globalData, arguments) {
          return BrokenNoTransitionPage(
            key: key,
            name: name,
            arguments: arguments,
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Navigate to login
      routerDelegate.push('login');
      await tester.pumpAndSettle();

      expect(find.text('Current: login'), findsOneWidget);
      expect(initCount, 1);

      final initCountBefore = initCount;

      // Switch to signup (same group)
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      // With BrokenNoTransitionPage, the child is captured in a closure
      // and NEVER updates. The UI still shows login even though we navigated
      // to signup. This is the bug!

      // The test verifies the BROKEN behavior - the page doesn't change
      // because the closure captured the old child
      expect(find.text('Current: login'), findsOneWidget,
          reason: 'BrokenNoTransitionPage captures child - UI never updates');

      // Note: This test documents the WRONG behavior to help developers
      // understand why PageRouteBuilder doesn't work for grouped routes
    });

    testWidgets('Default page builder (no custom) works correctly',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;

      // Router WITHOUT custom pageBuilder (uses library default)
      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'login',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'signup',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
        ],
        // No pageBuilder - uses default _UpdateableMaterialPage
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      routerDelegate.push('login');
      await tester.pumpAndSettle();

      expect(find.text('Current: login'), findsOneWidget);
      expect(initCount, 1);

      final initCountBefore = initCount;
      final updateCountBefore = updateCount;

      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      // Default page builder works correctly
      expect(initCount, initCountBefore,
          reason: 'Default page builder should reuse widget');
      expect(updateCount, greaterThan(updateCountBefore),
          reason: 'Default page builder should call didUpdateWidget');
      expect(find.text('Current: signup'), findsOneWidget);
    });

    testWidgets('Multiple switches with correct implementation',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;

      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'login',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'signup',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
          NavigationData(
            label: 'reset',
            url: '/reset',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'reset',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
        ],
        pageBuilder: (key, name, child, routeData, globalData, arguments) {
          return CorrectNoTransitionPage(
            key: key,
            name: name,
            arguments: arguments,
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      // Initial navigation
      routerDelegate.push('login');
      await tester.pumpAndSettle();
      expect(initCount, 1);

      final initAfterLogin = initCount;

      // Multiple switches
      routerDelegate.push('signup');
      await tester.pumpAndSettle();
      expect(find.text('Current: signup'), findsOneWidget);

      routerDelegate.push('reset');
      await tester.pumpAndSettle();
      expect(find.text('Current: reset'), findsOneWidget);

      routerDelegate.push('login');
      await tester.pumpAndSettle();
      expect(find.text('Current: login'), findsOneWidget);

      routerDelegate.push('signup');
      await tester.pumpAndSettle();
      expect(find.text('Current: signup'), findsOneWidget);

      // Only ONE initState should have been called
      expect(initCount, initAfterLogin,
          reason:
              'Widget should never be recreated for grouped route switches');

      // Multiple updates should have occurred
      expect(updateCount, greaterThanOrEqualTo(4),
          reason: 'didUpdateWidget should be called for each switch');
    });
  });

  group('ScaleTransitionPage with Grouped Routes', () {
    testWidgets('ScaleTransitionPage works correctly with grouped routes',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;

      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'login',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'signup',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
        ],
        pageBuilder: (key, name, child, routeData, globalData, arguments) {
          return ScaleTransitionPage(
            key: key,
            name: name,
            arguments: arguments,
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      routerDelegate.push('login');
      await tester.pumpAndSettle();

      expect(find.text('Current: login'), findsOneWidget);
      expect(initCount, 1);

      final initCountBefore = initCount;
      final updateCountBefore = updateCount;

      // Switch to signup (same group)
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      // Verify didUpdateWidget was called, NOT initState
      expect(initCount, initCountBefore,
          reason: 'ScaleTransitionPage should reuse widget for grouped routes');
      expect(updateCount, greaterThan(updateCountBefore),
          reason: 'didUpdateWidget should be called for grouped route switch');
      expect(find.text('Current: signup'), findsOneWidget);
    });
  });

  group('RightToLeftTransitionPage with Grouped Routes', () {
    testWidgets('RightToLeftTransitionPage works correctly with grouped routes',
        (WidgetTester tester) async {
      int initCount = 0;
      int updateCount = 0;

      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'login',
            url: '/login',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'login',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
          NavigationData(
            label: 'signup',
            url: '/signup',
            group: 'auth',
            builder: (context, route, _) => LifecycleTrackingWidget(
              identifier: 'signup',
              onInit: () => initCount++,
              onUpdate: () => updateCount++,
            ),
          ),
        ],
        pageBuilder: (key, name, child, routeData, globalData, arguments) {
          return RightToLeftTransitionPage(
            key: key,
            name: name,
            arguments: arguments,
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      routerDelegate.push('login');
      await tester.pumpAndSettle();

      expect(find.text('Current: login'), findsOneWidget);
      expect(initCount, 1);

      final initCountBefore = initCount;
      final updateCountBefore = updateCount;

      // Switch to signup (same group)
      routerDelegate.push('signup');
      await tester.pumpAndSettle();

      // Verify didUpdateWidget was called, NOT initState
      expect(initCount, initCountBefore,
          reason:
              'RightToLeftTransitionPage should reuse widget for grouped routes');
      expect(updateCount, greaterThan(updateCountBefore),
          reason: 'didUpdateWidget should be called for grouped route switch');
      expect(find.text('Current: signup'), findsOneWidget);
    });
  });

  group('PageRouteBuilder Closure Capture Issue', () {
    testWidgets('Documents why PageRouteBuilder fails for grouped routes',
        (WidgetTester tester) async {
      // This test documents the closure capture issue with PageRouteBuilder
      //
      // When PageRouteBuilder.createRoute is called:
      //   pageBuilder: (context, animation, secondaryAnimation) => child
      //
      // The `child` variable is captured in the closure at that moment.
      // Even when the Page is updated (via canUpdate returning true),
      // the closure still references the OLD child.
      //
      // This is fundamentally different from MaterialPageRoute which has:
      //   Widget buildContent(BuildContext context) => _page.child
      //
      // Where _page.child is read at BUILD TIME, getting the CURRENT child.

      final List<String> capturedChildren = [];

      final routerDelegate = DefaultRouterDelegate(
        navigationDataRoutes: [
          NavigationData(
            label: 'page1',
            url: '/page1',
            group: 'test',
            builder: (context, route, _) {
              capturedChildren.add('page1');
              return const Text('Page 1');
            },
          ),
          NavigationData(
            label: 'page2',
            url: '/page2',
            group: 'test',
            builder: (context, route, _) {
              capturedChildren.add('page2');
              return const Text('Page 2');
            },
          ),
        ],
        pageBuilder: (key, name, child, routeData, globalData, arguments) {
          // Each time a Page is created, the builder is called and
          // child is passed to the Page. But if the Page uses PageRouteBuilder,
          // that child is captured in a closure.
          return BrokenNoTransitionPage(
            key: key,
            name: name,
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp.router(
        routerDelegate: routerDelegate,
        routeInformationParser: DefaultRouteInformationParser(),
      ));

      capturedChildren.clear();

      routerDelegate.push('page1');
      await tester.pumpAndSettle();

      // Builder was called for page1
      expect(capturedChildren.contains('page1'), isTrue);

      capturedChildren.clear();

      routerDelegate.push('page2');
      await tester.pumpAndSettle();

      // Builder WAS called for page2 (NavigationUtils calls the builder)
      expect(capturedChildren.contains('page2'), isTrue);

      // BUT the UI still shows Page 1 because PageRouteBuilder captured
      // the old child in its closure!
      expect(find.text('Page 1'), findsOneWidget,
          reason: 'PageRouteBuilder keeps showing old child due to closure');
      expect(find.text('Page 2'), findsNothing,
          reason: 'New child is never displayed');
    });
  });
}
