import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaterialPage Equality Tests', () {
    test('MaterialPages with same properties should be equal', () {
      final page1 = MaterialPage(
        key: const ValueKey('test'),
        name: 'TestPage',
        arguments: {'id': 1},
        child: const Text('Test'),
      );

      final page2 = MaterialPage(
        key: const ValueKey('test'),
        name: 'TestPage',
        arguments: {'id': 1},
        child: const Text('Test'),
      );

      expect(page1 == page2, isTrue,
          reason:
              'MaterialPages with identical properties should be considered equal');
    });

    test('List of MaterialPages considers new instances as different', () {
      final List<Page> originalPages = [
        MaterialPage(
          key: const ValueKey('page1'),
          name: 'Page1',
          child: const Text('Page 1'),
        ),
        MaterialPage(
          key: const ValueKey('page2'),
          name: 'Page2',
          child: const Text('Page 2'),
        ),
      ];

      final List<Page> newPages = [
        MaterialPage(
          key: const ValueKey('page1'),
          name: 'Page1',
          child: const Text('Page 1'),
        ),
        MaterialPage(
          key: const ValueKey('page2'),
          name: 'Page2',
          child: const Text('Page 2'),
        ),
      ];

      expect(listEquals(originalPages, newPages), isTrue,
          reason:
              'Lists with new instances of MaterialPages are incorrectly considered different');
    });
  });
}
