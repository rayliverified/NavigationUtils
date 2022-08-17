import 'navigation_delegate.dart';
import 'navigation_information_parser.dart';

class NavigationManager {
  static const String instanceName = 'NavigationManager';

  static NavigationManager? _instance;

  static NavigationManager get instance {
    if (_instance == null) {
      throw Exception(
          'NavigationManager has not been initialized. Call `init()` to initialize before using.');
    }
    return _instance!;
  }

  final MainRouterDelegate routerDelegate;
  final MainRouteInformationParser routeInformationParser;

  NavigationManager._(this.routerDelegate, this.routeInformationParser);

  static NavigationManager init(
      {required MainRouterDelegate mainRouterDelegate,
      required MainRouteInformationParser routeInformationParser}) {
    _instance = NavigationManager._(mainRouterDelegate, routeInformationParser);
    return _instance!;
  }
}
