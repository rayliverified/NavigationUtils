import 'navigation_delegate.dart';
import 'path_utils_go_router.dart';

typedef ShouldNavigateDeeplinkFunction = bool Function(Uri deeplink,
    Map<String, String> pathParameters, Map<String, String> queryParameters);
typedef MapPathParameterFunction = Map<String, String> Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);
typedef MapQueryParameterFunction = Map<String, String> Function(
    Map<String, String> queryParameters, Map<String, String> pathParameters);
typedef MapArgumentsFunction = Object? Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);
typedef MapGlobalDataFunction = Map<String, dynamic> Function(
    Map<String, String> pathParameters, Map<String, String> queryParameters);
typedef RedirectFunction = Future<bool> Function(
    Map<String, String> pathParameters,
    Map<String, String> queryParameters,
    Function(
            String? url,
            String? label,
            Map<String, String>? pathParameters,
            Map<String, String>? queryParameters,
            Map<String, dynamic> globalData,
            Object? arguments)
        redirect);

class DeeplinkDestination {
  final String deeplinkUrl;
  final String destinationLabel;
  final String destinationUrl;
  final List<String>? backstack;
  final List<DefaultRoute>? backstackRoutes;
  final List<String> excludeDeeplinkNavigationPages;
  final ShouldNavigateDeeplinkFunction? shouldNavigateDeeplinkFunction;
  final MapPathParameterFunction? mapPathParameterFunction;
  final MapQueryParameterFunction? mapQueryParameterFunction;
  final MapArgumentsFunction? mapArgumentsFunction;
  final MapGlobalDataFunction? mapGlobalDataFunction;
  final RedirectFunction? redirectFunction;
  final bool authenticationRequired;
  // TODO: Add platform filter parameter.

  Uri get uri => Uri.tryParse(deeplinkUrl) ?? Uri();
  String get path => canonicalUri(Uri.tryParse(deeplinkUrl)?.path ?? '');

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
      this.authenticationRequired = false})
      : assert(deeplinkUrl != '', 'Deeplink URL required.'),
        assert(destinationLabel != '' || destinationUrl != '',
            'Deeplink destination required.'),
        assert(backstack == null || backstackRoutes == null,
            'Cannot set both url backstacks and route object backstacks.');

  @override
  String toString() =>
      'DeeplinkDestination(deeplinkUrl: $deeplinkUrl, destinationLabel: $destinationLabel, destinationUrl: $destinationUrl)';
}
