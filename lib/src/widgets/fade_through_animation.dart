import 'package:flutter/material.dart';

/// A fade-through animation widget.
///
/// This widget provides a fade and zoom animation effect, typically used
/// for page transitions. Copied from Flutter animation's private
/// ZoomedFadeInFadeOut widget.
class FadeThroughAnimation extends StatelessWidget {
  /// Creates a [FadeThroughAnimation] with the given animation.
  ///
  /// [animation] - The animation controller (required).
  /// [child] - The child widget to animate.
  const FadeThroughAnimation({super.key, required this.animation, this.child});

  /// The animation controller for the fade-through effect.
  final Animation<double> animation;

  /// The child widget to animate.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return ZoomedFadeIn(
          animation: animation,
          child: child,
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeOut(
          animation: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// A widget that provides a zoomed fade-in animation.
class ZoomedFadeIn extends StatelessWidget {
  /// Creates a [ZoomedFadeIn] widget.
  ///
  /// [animation] - The animation controller (required).
  /// [child] - The child widget to animate.
  const ZoomedFadeIn({
    super.key,
    this.child,
    required this.animation,
  });

  /// The child widget to animate.
  final Widget? child;

  /// The animation controller for the zoomed fade-in effect.
  final Animation<double> animation;

  static final CurveTween _inCurve = CurveTween(
    curve: const Cubic(0.0, 0.0, 0.2, 1.0),
  );
  static final TweenSequence<double> _scaleIn = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.92),
        weight: 6 / 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.92, end: 1.0).chain(_inCurve),
        weight: 14 / 20,
      ),
    ],
  );
  static final TweenSequence<double> _fadeInOpacity = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.0),
        weight: 6 / 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(_inCurve),
        weight: 14 / 20,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInOpacity.animate(animation),
      child: ScaleTransition(
        scale: _scaleIn.animate(animation),
        child: child,
      ),
    );
  }
}

/// A widget that provides a fade-out animation.
class FadeOut extends StatelessWidget {
  /// Creates a [FadeOut] widget.
  ///
  /// [animation] - The animation controller (required).
  /// [child] - The child widget to animate.
  const FadeOut({
    super.key,
    this.child,
    required this.animation,
  });

  /// The child widget to animate.
  final Widget? child;

  /// The animation controller for the fade-out effect.
  final Animation<double> animation;

  static final CurveTween _outCurve = CurveTween(
    curve: const Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static final TweenSequence<double> _fadeOutOpacity = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(_outCurve),
        weight: 6 / 20,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.0),
        weight: 14 / 20,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOutOpacity.animate(animation),
      child: child,
    );
  }
}
