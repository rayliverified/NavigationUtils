import 'package:flutter/material.dart';

/// A widget that conditionally applies a builder based on the current route.
///
/// This widget checks if the current route matches certain criteria and
/// applies a builder function if the condition is met. Useful for applying
/// route-specific styling or wrapping.
class ConditionalRouteWidget extends StatelessWidget {
  /// List of route names to include.
  ///
  /// If provided, the builder is applied only when the current route
  /// is in this list. Cannot be used together with [routesExcluded].
  final List<String>? routes;

  /// List of route names to exclude.
  ///
  /// If provided, the builder is applied only when the current route
  /// is NOT in this list. Cannot be used together with [routes].
  final List<String>? routesExcluded;

  /// Builder function to apply when the condition is met.
  final TransitionBuilder builder;

  /// The child widget to conditionally wrap.
  final Widget child;

  /// Creates a [ConditionalRouteWidget] with the given configuration.
  ///
  /// Either [routes] or [routesExcluded] must be provided, but not both.
  ///
  /// [routes] - List of routes to include.
  /// [routesExcluded] - List of routes to exclude.
  /// [builder] - Builder function to apply (required).
  /// [child] - Child widget to conditionally wrap (required).
  const ConditionalRouteWidget(
      {super.key,
      this.routes,
      this.routesExcluded,
      required this.builder,
      required this.child})
      : assert(routes == null || routesExcluded == null,
            'Cannot include `routes` and `routesExcluded`. Please provide an list of routes to include or exclude, not both.');

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    if (routes != null && routes!.contains(currentRoute)) {
      return builder(context, child);
    } else if (routesExcluded != null &&
        routesExcluded!.contains(currentRoute) == false) {
      return builder(context, child);
    }

    return child;
  }
}
