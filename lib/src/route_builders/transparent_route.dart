import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A transparent page route that allows underlying pages to show through.
///
/// This route type is useful for overlays, modals, or dialogs that should
/// not completely obscure the content beneath them.
class TransparentRoute<T> extends PageRoute<T> {
  TransparentRoute({
    super.settings,
    super.fullscreenDialog,
    required this.builder,
    this.maintainState = true,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    this.barrierColor = Colors.transparent,
  });

  /// Builder function for the route's widget.
  final WidgetBuilder builder;

  /// This route is not opaque, allowing underlying content to show through.
  @override
  bool get opaque => false;

  /// Whether to maintain the state of the route when it's not visible.
  @override
  final bool maintainState;

  /// Builder function for custom route transitions.
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  /// The color of the barrier that blocks interaction with routes below.
  @override
  final Color barrierColor;

  /// The semantic label for the barrier.
  @override
  String get barrierLabel => '';

  /// Determines whether this route can transition to the next route.
  ///
  /// Returns `true` if the transition should proceed, `false` otherwise.
  /// Prevents outgoing animation if the next route is a fullscreen dialog.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog);
  }

  /// Builds the page content for this route.
  ///
  /// Wraps the result in a [Semantics] widget to provide accessibility support.
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

  /// Builds the transition animation for this route.
  ///
  /// Overrides default Android OpenUpwardsPageTransition and iOS CupertinoSlideTransition.
  /// Default Android and iOS transitions apply undesired animations to the route
  /// below. The route below needs to stay the same for transparent pages.
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Override default Android OpenUpwardsPageTransition and iOS CupertinoSlideTransition.
    // Default Android and iOS transitions apply undesired animations to the route
    // below. The route below needs to stay the same for transparent pages.
    return FadeUpwardsPageTransition(routeAnimation: animation, child: child);
  }

  /// The debug label for this route.
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

/// A transparent page that allows underlying pages to show through.
///
/// This page type is useful for overlays, modals, or dialogs that should
/// not completely obscure the content beneath them.
class TransparentPage<T> extends Page<T> {
  /// Creates a transparent page.
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

  /// The color of the barrier that blocks interaction with routes below.
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

/// Mixin that provides fade upwards transition for transparent routes.
///
/// This mixin ensures that transparent routes use a fade upwards animation
/// instead of the default platform animations, which helps preserve
/// the appearance of underlying routes.
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

/// A page transition that fades and slides upwards.
///
/// This transition is used for transparent routes to ensure
/// underlying content remains visible during the transition.
class FadeUpwardsPageTransition extends StatelessWidget {
  /// Creates a fade upwards page transition.
  ///
  /// [routeAnimation] - The route's animation controller.
  /// [child] - The child widget to animate.
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

  /// The child widget to animate.
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
