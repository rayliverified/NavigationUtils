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
  List<Page> _pages = [];
  bool _optimizedList = false;

  @override
  void initState() {
    super.initState();
    _updatePages();
  }

  void _updatePages() {
    setState(() {
      _pages = [
        if (_optimizedList)
          OptimizedMaterialPage(
            key: const ValueKey('page1'),
            child: const _TestPage(key: ValueKey('page1'), title: 'Page 1'),
          )
        else
          MaterialPage(
            key: const ValueKey('page1'),
            child: const _TestPage(key: ValueKey('page1'), title: 'Page 1'),
          ),
      ];
    });
  }

  void _addPage() {
    debugPrint('Pages: ${_pages} addPage');
    setState(() {
      final newPageIndex = _pages.length + 1;
      List<Page> newPages = [];
      newPages = _pages.map((page) {
        if (page is MaterialPage) {
          return MaterialPage(
            key: page.key,
            name: page.name,
            arguments: page.arguments,
            fullscreenDialog: page.fullscreenDialog,
            child: page.child,
          );
        } else if (page is OptimizedMaterialPage) {
          return OptimizedMaterialPage(
            key: page.key,
            name: page.name,
            arguments: page.arguments,
            child: page.child,
          );
        }
        return page;
      }).toList();
      _pages.clear();

      newPages.add(
        _optimizedList
            ? OptimizedMaterialPage(
                key: ValueKey('page$newPageIndex'),
                child: _TestPage(
                    key: ValueKey('page$newPageIndex'),
                    title: 'Page $newPageIndex'),
              )
            : MaterialPage(
                key: ValueKey('page$newPageIndex'),
                name: 'page$newPageIndex',
                arguments: null,
                fullscreenDialog: false,
                child: _TestPage(
                    key: ValueKey('page$newPageIndex'),
                    title: 'Page $newPageIndex'),
              ),
      );
      _pages = newPages;
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
        pages: List.from(_pages), // Create a new list from _pages
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          setState(() {
            _pages.removeLast();
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
        other.child.runtimeType == child.runtimeType &&
        other.key == key &&
        other.name == name &&
        other.arguments == arguments;
    debugPrint('Page Equality: $result');
    return result;
  }

  @override
  int get hashCode => Object.hash(child.runtimeType, key, name, arguments);
}
