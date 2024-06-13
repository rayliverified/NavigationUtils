import 'package:flutter/material.dart';

/// Determines which type of shared axis transition is used.
enum SharedAxisAnimationType {
  /// Creates a shared axis vertical (y-axis) page transition.
  vertical,

  /// Creates a shared axis horizontal (x-axis) page transition.
  horizontal,

  /// Creates a shared axis scaled (z-axis) page transition.
  scaled,
}

/// A copy of Flutter animations package's private EnterTransition.
class SharedAxisAnimation extends StatelessWidget {
  const SharedAxisAnimation({
    super.key,
    required this.animation,
    required this.transitionType,
    required this.child,
    this.reverse = false,
  });

  final Animation<double> animation;
  final SharedAxisAnimationType transitionType;
  final Widget? child;
  final bool reverse;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: Easing.legacyDecelerate,
  ).chain(CurveTween(curve: const Interval(0.3, 1.0)));

  static final Animatable<double> _scaleDownTransition = Tween<double>(
    begin: 1.10,
    end: 1.00,
  ).chain(CurveTween(curve: Easing.legacy));

  static final Animatable<double> _scaleUpTransition = Tween<double>(
    begin: 0.80,
    end: 1.00,
  ).chain(CurveTween(curve: Easing.legacy));

  @override
  Widget build(BuildContext context) {
    switch (transitionType) {
      case SharedAxisAnimationType.horizontal:
        final Animatable<Offset> slideInTransition = Tween<Offset>(
          begin: Offset(!reverse ? 30.0 : -30.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Easing.legacy));

        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: slideInTransition.evaluate(animation),
                child: child,
              );
            },
            child: child,
          ),
        );
      case SharedAxisAnimationType.vertical:
        final Animatable<Offset> slideInTransition = Tween<Offset>(
          begin: Offset(0.0, !reverse ? 30.0 : -30.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Easing.legacy));

        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: slideInTransition.evaluate(animation),
                child: child,
              );
            },
            child: child,
          ),
        );
      case SharedAxisAnimationType.scaled:
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: (!reverse ? _scaleUpTransition : _scaleDownTransition)
                .animate(animation),
            child: child,
          ),
        );
    }
  }
}

/// Enables creating a flipped [CurveTween].
///
/// This creates a [CurveTween] that evaluates to a result that flips the
/// tween vertically.
///
/// This tween sequence assumes that the evaluated result has to be a double
/// between 0.0 and 1.0.
class FlippedCurveTween extends CurveTween {
  /// Creates a vertically flipped [CurveTween].
  FlippedCurveTween({
    required super.curve,
  });

  @override
  double transform(double t) => 1.0 - super.transform(t);
}
