import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TransparentRoute<T> extends PageRoute<T> {
  TransparentRoute({
    super.settings,
    super.fullscreenDialog,
    required this.builder,
    this.maintainState = true,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    this.barrierColor = Colors.transparent,
  });

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  final bool maintainState;

  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  final Color barrierColor;

  @override
  String get barrierLabel => '';

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = builder(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Override default Android OpenUpwardsPageTransition and iOS CupertinoSlideTransition.
    // Default Android and iOS transitions apply undesired animations to the route
    // below. The route below needs to stay the same for transparent pages.
    return FadeUpwardsPageTransition(routeAnimation: animation, child: child);
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

Widget _defaultTransitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child) {
  return child;
}

class TransparentPage<T> extends Page<T> {
  /// Creates a material page.
  const TransparentPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.barrierColor = Colors.transparent,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.PageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  final Color barrierColor;

  @override
  Route<T> createRoute(BuildContext context) {
    return _TransparentPageRoute<T>(page: this);
  }
}

class _TransparentPageRoute<T> extends PageRoute<T>
    with FadeUpwardsRouteTransitionMixin<T> {
  _TransparentPageRoute({
    required TransparentPage<T> page,
  }) : super(settings: page);

  @override
  bool get opaque => false;

  TransparentPage<T> get _page => settings as TransparentPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  Color get barrierColor => _page.barrierColor;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

mixin FadeUpwardsRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialRouteTransitionMixin &&
            !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoRouteTransitionMixin &&
            !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = buildContent(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Override default Android OpenUpwardsPageTransition and iOS CupertinoSlideTransition.
    // Default Android and iOS transitions apply undesired animations to the route
    // below. The route below needs to stay the same for transparent pages.
    return FadeUpwardsPageTransition(routeAnimation: animation, child: child);
  }
}

class FadeUpwardsPageTransition extends StatelessWidget {
  FadeUpwardsPageTransition({
    super.key,
    required Animation<double>
        routeAnimation, // The route's linear 0.0 - 1.0 animation.
    required this.child,
  })  : _positionAnimation =
            routeAnimation.drive(_bottomUpTween.chain(_fastOutSlowInTween)),
        _opacityAnimation = routeAnimation.drive(_easeInTween);

  // Fractional offset from 1/4 screen below the top to fully on screen.
  static final Tween<Offset> _bottomUpTween = Tween<Offset>(
    begin: const Offset(0.0, 0.25),
    end: Offset.zero,
  );
  static final Animatable<double> _fastOutSlowInTween =
      CurveTween(curve: Curves.fastOutSlowIn);
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);

  final Animation<Offset> _positionAnimation;
  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _positionAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: child,
      ),
    );
  }
}
