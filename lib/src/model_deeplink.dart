import 'navigation_delegate.dart';
import 'path_utils_go_router.dart';

typedef ShouldNavigateDeeplinkFunction = bool Function();
typedef MapPathParameterFunction = Map<String, String> Function(
    Map<String, String> pathParameters);
typedef MapQueryParameterFunction = Map<String, String> Function(
    Map<String, String> queryParameters);

class DeeplinkDestination {
  final String deeplinkUrl;
  final String destinationLabel;
  final String destinationUrl;
  final List<String>? backstack;
  final List<DefaultRoute>? backstackRoutes;
  final List<String> ignoreDeeplinkWhenOnThisPageList;
  final ShouldNavigateDeeplinkFunction? shouldNavigateDeeplinkFunction;
  final MapPathParameterFunction? mapPathParameterFunction;
  final MapQueryParameterFunction? mapQueryParameterFunction;
  final bool authenticationRequired;

  Uri get uri => Uri.tryParse(deeplinkUrl) ?? Uri();
  String get path => canonicalUri(Uri.tryParse(deeplinkUrl)?.path ?? '');

  const DeeplinkDestination(
      {this.deeplinkUrl = '',
      this.destinationLabel = '',
      this.destinationUrl = '',
      this.backstack,
      this.backstackRoutes,
      this.ignoreDeeplinkWhenOnThisPageList = const [],
      this.shouldNavigateDeeplinkFunction,
      this.mapPathParameterFunction,
      this.mapQueryParameterFunction,
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
