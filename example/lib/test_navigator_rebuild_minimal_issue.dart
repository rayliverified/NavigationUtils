// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';

/// Example of working Navigator comparison behavior.
/// Both default MaterialPage and Custom equality pages match.
/// When the page variable is reused, equality works.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Page Rebuild Test',
      home: const PageRebuildTest(),
    );
  }
}

class PageRebuildTest extends StatefulWidget {
  const PageRebuildTest({super.key});

  @override
  State<PageRebuildTest> createState() => _PageRebuildTestState();
}

class _PageRebuildTestState extends State<PageRebuildTest> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int _pageCount = 1;
  bool _optimizedList = false;

  @override
  void initState() {
    super.initState();
  }

  List<Page> buildPages(int count) {
    List<Page> pagesHolder = [];

    for (int i = 1; i <= count; i++) {
      if (_optimizedList) {
        pagesHolder.add(OptimizedMaterialPage(
          key: ValueKey('page$i'),
          child: _TestPage(key: ValueKey('page$i'), title: 'Page $i'),
        ));
      } else {
        pagesHolder.add(MaterialPage(
          key: ValueKey('page$i'),
          name: 'page$i',
          arguments: null,
          fullscreenDialog: false,
          child: _TestPage(key: ValueKey('page$i'), title: 'Page $i'),
        ));
      }
    }

    return pagesHolder;
  }

  void _addPage() {
    setState(() {
      _pageCount++;
    });
  }

  void _toggleOptimizedList(bool value) {
    setState(() {
      _optimizedList = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_optimizedList ? 'Optimized Pages' : 'Material Pages'),
        actions: [
          Row(
            children: [
              const Text('Optimized List'),
              Switch(
                value: _optimizedList,
                onChanged: _toggleOptimizedList,
              ),
            ],
          ),
        ],
      ),
      body: Navigator(
        key: navigatorKey,
        pages: [
          ...buildPages(_pageCount),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          setState(() {
            if (_pageCount > 1) _pageCount--;
          });
          return true;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TestPage extends StatelessWidget {
  final String title;

  const _TestPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    print('Building $title'); // This print statement helps track rebuilds
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

class OptimizedMaterialPage<T> extends Page<T> {
  final Widget child;

  const OptimizedMaterialPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute<T>(
      settings: this,
      builder: (BuildContext context) => child,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool result = other is OptimizedMaterialPage &&
        other.key == key &&
        other.name == name &&
        other.arguments == arguments;
    debugPrint('Page Equality: $result');
    return result;
  }

  @override
  int get hashCode => Object.hash(key, name, arguments);
}
