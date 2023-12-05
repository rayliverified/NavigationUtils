import 'package:flutter/material.dart';

/// A wrapper widget for common top level page widgets.
///
/// Widgets and functionality provided:
/// - Scaffold with configurable [backgroundColor].
/// - MediaQuery to set text scale to 1.0.
class PageWrapper extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// Scaffold background color. Defaults to transparent if null.
  final Color backgroundColor;

  final bool safeArea;

  final PreferredSizeWidget? appBar;

  final Widget? floatingActionButton;

  const PageWrapper(
      {super.key,
      required this.child,
      this.backgroundColor = Colors.white,
      this.safeArea = true,
      this.appBar,
      this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: appBar,
          body: safeArea
              ? SafeArea(
                  child: child,
                )
              : child,
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}
