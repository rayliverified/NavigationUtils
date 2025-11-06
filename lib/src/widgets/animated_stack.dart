import 'package:flutter/material.dart';

/// Function type for building animated widgets.
///
/// Takes a child widget and an animation, returns an animated widget.
typedef AnimationBuilder = Widget Function(
    Widget child, Animation<double> animation);

/// A stack widget that animates transitions between children.
///
/// This widget manages animations for child widgets, providing smooth
/// transitions when children are added, removed, or reordered.
class AnimatedStack extends StatefulWidget {
  /// The name identifier for this widget.
  static const String name = 'animated_stack';

  /// The list of child widgets to display in the stack.
  final List<Widget> children;

  /// Function that builds animated widgets from children and animations.
  final AnimationBuilder animation;

  /// The duration of animations.
  final Duration duration;

  /// Position in the animation timeline where cross-fade occurs (0.0 to 1.0).
  final double crossFadePosition;

  /// Whether to animate the initial child.
  final bool initialAnimation;

  /// How to align the children.
  final AlignmentGeometry alignment;

  /// The text direction for the stack.
  final TextDirection? textDirection;

  /// How to size the non-positioned children.
  final StackFit fit;

  /// The clip behavior for the stack.
  final Clip clipBehavior;

  /// Creates an [AnimatedStack] with the given configuration.
  ///
  /// [children] - List of child widgets (required).
  /// [animation] - Animation builder function (required).
  /// [duration] - Animation duration (required).
  /// [initialAnimation] - Whether to animate the initial child.
  /// [crossFadePosition] - Position for cross-fade transition.
  /// [alignment] - Alignment for children.
  /// [textDirection] - Text direction.
  /// [fit] - How to size non-positioned children.
  /// [clipBehavior] - Clip behavior.
  const AnimatedStack({
    super.key,
    required this.duration,
    required this.animation,
    required this.children,
    this.initialAnimation = true,
    this.crossFadePosition = 0.5,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  State<AnimatedStack> createState() => _AnimatedStackState();
}

class _AnimatedStackState extends State<AnimatedStack>
    with TickerProviderStateMixin {
  Map<Key, AnimationController> controllers = {};

  late Widget? page;
  bool reverse = false;
  int length = 0;
  Widget? dismissingWidget;

  @override
  void initState() {
    super.initState();
    page = widget.children.isNotEmpty ? widget.children.last : null;
    initAnimationControllers();
    if (widget.children.isNotEmpty) {
      if (widget.initialAnimation) {
        controllers[widget.children.last.key]!.forward();
      } else {
        controllers[widget.children.last.key]!.value = 1;
      }
    }
  }

  @override
  void dispose() {
    for (AnimationController controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void initAnimationControllers() {
    for (Widget child in widget.children) {
      if (controllers.containsKey(child.key) == false) {
        controllers[child.key!] = AnimationController(
          vsync: this,
          duration: widget.duration,
        );
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    initAnimationControllers();

    if (page == null && widget.children.isEmpty) return;

    // Top widget hasn't changed.
    if (widget.children.isNotEmpty && page?.key == widget.children.last.key) {
      return;
    }

    // Adding first widget.
    if (page == null) {
      controllers[widget.children.last.key!]?.forward(from: 0);
      page = widget.children.last;
      return;
    }

    if (page != null &&
        widget.children.where((e) => e.key == page?.key).isEmpty) {
      // Remove page.
      dismissingWidget = page;
      controllers[dismissingWidget!.key]?.reverse(from: 1);
      controllers[dismissingWidget!.key]!.addStatusListener((status) {
        if (dismissingWidget == null) return;
        if (status == AnimationStatus.dismissed) {
          controllers[dismissingWidget!.key]!.removeStatusListener((status) {});
          controllers[dismissingWidget!.key]!.reset();
          dismissingWidget = null;
          setState(() {});
        }
      });
      // If pages exist, animate the new top in.
      if (widget.children.isNotEmpty) {
        controllers[widget.children.last.key]?.forward(from: 0);
      }
    } else {
      // Add page.
      controllers[page?.key]?.reverse(from: 1);
      controllers[widget.children.last.key]?.value = 0;
      // Cross fade transition.
      Future.delayed(
        Duration(
            milliseconds:
                (widget.duration.inMilliseconds * widget.crossFadePosition)
                    .round()),
        () {
          controllers[widget.children.last.key]?.forward();
        },
      );
    }

    page = widget.children.isNotEmpty ? widget.children.last : null;
    return;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];

    if (widget.children.length > 2) {
      for (int i = 0; i < widget.children.length - 2; i++) {
        Widget child = widget.children[i];
        stackChildren.add(Offstage(
          key: child.key,
          offstage: true,
          child: widget.animation(
            child,
            controllers[child.key]!.view,
          ),
        ));
      }
    }

    // Add Second Widget.
    if (widget.children.length > 1) {
      Widget secondWidget = widget.children[widget.children.length - 2];
      stackChildren.add(
        Offstage(
          key: secondWidget.key,
          offstage: false,
          child: widget.animation(
            secondWidget,
            controllers[secondWidget.key]!.view,
          ),
        ),
      );
    }

    // Add Top Widget.
    if (widget.children.isNotEmpty) {
      Widget topWidget = widget.children.last;
      stackChildren.add(
        Offstage(
          key: topWidget.key,
          offstage: false,
          child: widget.animation(
            topWidget,
            controllers[topWidget.key]!.view,
          ),
        ),
      );
    }

    // Add copy of removed widget for removal animation.
    if (dismissingWidget != null) {
      stackChildren.add(
        Offstage(
          key: dismissingWidget!.key,
          offstage: false,
          child: widget.animation(
            dismissingWidget!,
            controllers[dismissingWidget!.key]!.view,
          ),
        ),
      );
    }

    return Stack(
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      fit: widget.fit,
      clipBehavior: widget.clipBehavior,
      children: stackChildren,
    );
  }
}
