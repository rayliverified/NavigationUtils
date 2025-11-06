import '../navigation_delegate.dart';
import '../path_utils_go_router.dart';

/// Function type that determines whether a deeplink should be navigated to.
///
/// Returns `true` if navigation should proceed, `false` otherwise.
typedef ShouldNavigateDeeplinkFunction = bool Function(Uri deeplink,
    Map<String, String> pathParameters, Map<String, String> queryParameters);

/// Function type that maps path parameters to new path parameters.
///
/// Used to transform path parameters before navigation.
typedef MapPathParameterFunction = Map<String, String> Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);

/// Function type that maps query parameters to new query parameters.
///
/// Used to transform query parameters before navigation.
typedef MapQueryParameterFunction = Map<String, String> Function(
    Map<String, String> queryParameters, Map<String, String> pathParameters);

/// Function type that maps path and query parameters to route arguments.
///
/// Used to create custom arguments object from parameters.
typedef MapArgumentsFunction = Object? Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);

/// Function type that maps path and query parameters to global data.
///
/// Used to create custom global data map from parameters.
typedef MapGlobalDataFunction = Map<String, dynamic> Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);

/// Function type that handles deeplink redirection.
///
/// The redirect callback can be used to programmatically navigate
/// to a different route. Returns `true` if redirect was handled,
/// `false` to use default navigation behavior.
typedef RedirectFunction = Future<bool> Function(
    Map<String, String> pathParameters,
    Map<String, String> queryParameters,
    void Function(
            {String? label,
            String? url,
            Map<String, String>? pathParameters,
            Map<String, String>? queryParameters,
            Map<String, dynamic>? globalData,
            Object? arguments})
        redirect);

/// Function type that runs custom logic when a deeplink is opened.
///
/// This function is called regardless of whether navigation occurs,
/// allowing for side effects like analytics tracking.
typedef RunFunction = Future<void> Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);

/// Configuration for handling deeplink destinations.
///
/// This class defines how a deeplink URI should be processed and where
/// it should navigate to, including optional transformations and callbacks.
class DeeplinkDestination {
  /// The deeplink URL pattern to match against incoming deeplinks.
  final String deeplinkUrl;

  /// The label of the destination route to navigate to.
  ///
  /// This should match a route label defined in your navigation routes.
  final String destinationLabel;

  /// The URL of the destination route to navigate to.
  ///
  /// Alternative to [destinationLabel] for URL-based navigation.
  final String destinationUrl;

  /// Optional list of route labels to set as backstack before navigating.
  ///
  /// If provided, these routes will be pushed onto the navigation stack
  /// before navigating to the destination.
  final List<String>? backstack;

  /// Optional list of route objects to set as backstack before navigating.
  ///
  /// Alternative to [backstack] for more control over route configuration.
  /// Cannot be used together with [backstack].
  final List<DefaultRoute>? backstackRoutes;

  /// List of route names/paths from which deeplink navigation should be excluded.
  ///
  /// If the current route matches any of these, the deeplink will not be processed.
  final List<String> excludeDeeplinkNavigationPages;

  /// Optional function to determine if deeplink navigation should proceed.
  ///
  /// If provided, this function is called to check if navigation should occur.
  /// Return `false` to prevent navigation.
  final ShouldNavigateDeeplinkFunction? shouldNavigateDeeplinkFunction;

  /// Optional function to transform path parameters before navigation.
  final MapPathParameterFunction? mapPathParameterFunction;

  /// Optional function to transform query parameters before navigation.
  final MapQueryParameterFunction? mapQueryParameterFunction;

  /// Optional function to create route arguments from parameters.
  final MapArgumentsFunction? mapArgumentsFunction;

  /// Optional function to create global data from parameters.
  final MapGlobalDataFunction? mapGlobalDataFunction;

  /// Optional function to handle custom deeplink redirection logic.
  ///
  /// If provided, this function can programmatically navigate to a different route.
  final RedirectFunction? redirectFunction;

  /// Optional function to run custom logic when deeplink is opened.
  ///
  /// This function is called regardless of whether navigation occurs.
  final RunFunction? runFunction;

  /// Whether authentication is required to navigate to this deeplink destination.
  final bool authenticationRequired;
  // TODO: Add platform filter parameter.

  /// The parsed URI from [deeplinkUrl].
  Uri get uri => Uri.tryParse(deeplinkUrl) ?? Uri();

  /// The canonical path from [deeplinkUrl].
  String get path => canonicalUri(Uri.tryParse(deeplinkUrl)?.path ?? '');

  /// Creates a [DeeplinkDestination] with the given configuration.
  ///
  /// Either [destinationLabel], [destinationUrl], or [runFunction] must be provided.
  /// [backstack] and [backstackRoutes] cannot both be provided.
  const DeeplinkDestination(
      {this.deeplinkUrl = '',
      this.destinationLabel = '',
      this.destinationUrl = '',
      this.backstack,
      this.backstackRoutes,
      this.excludeDeeplinkNavigationPages = const [],
      this.shouldNavigateDeeplinkFunction,
      this.mapPathParameterFunction,
      this.mapQueryParameterFunction,
      this.mapArgumentsFunction,
      this.mapGlobalDataFunction,
      this.redirectFunction,
      this.runFunction,
      this.authenticationRequired = false})
      : assert(deeplinkUrl != '', 'Deeplink URL required.'),
        assert(
            destinationLabel != '' ||
                destinationUrl != '' ||
                runFunction != null,
            'Deeplink destination or runFunction required.'),
        assert(backstack == null || backstackRoutes == null,
            'Cannot set both url backstacks and route object backstacks.');

  @override
  String toString() =>
      'DeeplinkDestination(deeplinkUrl: $deeplinkUrl, destinationLabel: $destinationLabel, destinationUrl: $destinationUrl)';
}
