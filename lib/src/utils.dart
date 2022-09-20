import 'package:navigation_utils/navigation_utils.dart';

class NavigationUtils {
  static NavigationData? getNavigationDataFromUri(
      {required List<NavigationData> routes, required Uri uri}) {
    NavigationData? navigationData;
    try {
      navigationData = routes.firstWhere((element) =>
          Uri(path: element.path, queryParameters: element.queryParameters) ==
          uri);
    } on StateError {
      // ignore: empty_catches
    }

    return navigationData;
  }

  static String _trimRight(String from, String pattern) {
    if (from.isEmpty || pattern.isEmpty || pattern.length > from.length) {
      return from;
    }

    while (from.endsWith(pattern)) {
      from = from.substring(0, from.length - pattern.length);
    }
    return from;
  }
}
