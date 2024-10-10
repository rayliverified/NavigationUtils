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
  _PageRebuildTestState createState() => _PageRebuildTestState();
}

class _PageRebuildTestState extends State<PageRebuildTest> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  List<Page> _pages = [];
  bool _useOptimizedPage = false;

  @override
  void initState() {
    super.initState();
    _updatePages();
  }

  void _updatePages() {
    setState(() {
      _pages = [
        if (_useOptimizedPage)
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
      _pages.add(
        _useOptimizedPage
            ? OptimizedMaterialPage(
                key: ValueKey('page${_pages.length + 1}'),
                child: _TestPage(
                    key: ValueKey('page${_pages.length + 1}'),
                    title: 'Page ${_pages.length + 1}'),
              )
            : MaterialPage(
                key: ValueKey('page${_pages.length + 1}'),
                name: 'page${_pages.length + 1}',
                arguments: null,
                fullscreenDialog: false,
                child: _TestPage(
                    key: ValueKey('page${_pages.length + 1}'),
                    title: 'Page ${_pages.length + 1}'),
              ),
      );
    });
  }

  void _togglePageType() {
    setState(() {
      _useOptimizedPage = !_useOptimizedPage;
      _updatePages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_useOptimizedPage ? 'Optimized Pages' : 'Material Pages'),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addPage,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _togglePageType,
            child: const Icon(Icons.swap_horiz),
          ),
        ],
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
    return other is OptimizedMaterialPage &&
        other.child.runtimeType == child.runtimeType &&
        other.key == key &&
        other.name == name &&
        other.arguments == arguments;
  }

  @override
  int get hashCode => Object.hash(child.runtimeType, key, name, arguments);
}
