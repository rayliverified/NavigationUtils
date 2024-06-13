import 'package:flutter/material.dart';

typedef AnimationBuilder = Widget Function(
    Widget child, Animation<double> animation);

class AnimatedStack extends StatefulWidget {
  static const String name = 'animated_stack';

  final List<Widget> children;
  final AnimationBuilder animation;
  final Duration duration;
  final double crossFadePosition;
  final bool initialAnimation;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit fit;
  final Clip clipBehavior;

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
