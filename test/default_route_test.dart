import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('DefaultRoute', () {
    test('Invalid Query Parameter in Path', () {
      DefaultRoute defaultRoute =
          DefaultRoute(path: '/page/nested?id=123&type=abc');
      Uri uri = Uri(path: '/page/nested?id=123&type=abc');
      expect(defaultRoute.uri.path, '/page/nested%3Fid=123&type=abc');
      expect(defaultRoute.uri, isNot(uri));
    });
  });
}
