import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_utils/navigation_utils.dart';

void main() {
  group('getDeeplinkDestination', () {
    test('Empty', () {
      NavigationUtils.getDeeplinkDestinationFromUrl([], null);
      NavigationUtils.getDeeplinkDestinationFromUrl([], '');
      NavigationUtils.getDeeplinkDestinationFromUri([], null);
      NavigationUtils.getDeeplinkDestinationFromUri([], Uri());
    });
    test('Match Path Parameter', () {
      DeeplinkDestination deeplinkDestination = const DeeplinkDestination(
          deeplinkUrl: '/link/post/:postId', destinationUrl: '/post/:postId');
      List<DeeplinkDestination> deeplinkDestinations = [
        deeplinkDestination,
      ];

      // Match post ID.
      expect(
          NavigationUtils.getDeeplinkDestinationFromUrl(
              deeplinkDestinations, '/link/post/1'),
          deeplinkDestination);

      // Match post ID with trailing slash.
      expect(
          NavigationUtils.getDeeplinkDestinationFromUrl(
              deeplinkDestinations, '/link/post/1/'),
          deeplinkDestination);

      // No post ID, do not match.
      expect(
          NavigationUtils.getDeeplinkDestinationFromUrl(
              deeplinkDestinations, '/link/post'),
          null);
    });
  });
}
