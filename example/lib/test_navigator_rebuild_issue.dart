import 'package:flutter/material.dart';

/*
 * Minimal reproduction of navigation rebuilding issue.
 * It showcases the difference between recreating the entire navigation stack and simply
 * adding new pages to the existing stack.
 * 
 * Toggle between recreating the page list versus maintaining the instances of the page models.
 * When the pages are recreated, every route is rebuilt when navigating. Watch the console for duplicate build print statements.
 *
 * https://github.com/flutter/flutter/issues/156551
 */

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Rebuild Test',
      home: const NavigationRebuildTest(),
    );
  }
}

class NavigationRebuildTest extends StatefulWidget {
  const NavigationRebuildTest({super.key});

  @override
  State<NavigationRebuildTest> createState() => _NavigationRebuildTestState();
}

class _NavigationRebuildTestState extends State<NavigationRebuildTest> {
  List<Page<dynamic>> currentPages = [];
  bool recreateList = true;

  @override
  void initState() {
    super.initState();
    currentPages = [
      MaterialPage(
        key: const ValueKey('page1'),
        child: const TestPage(title: 'Page 1'),
      ),
    ];
  }

  void _addPage() {
    setState(() {
      if (recreateList) {
        currentPages = [
          ...currentPages.map((page) {
            if (page is MaterialPage) {
              return MaterialPage(
                key: ValueKey('${page.key}'),
                name: page.name,
                arguments: page.arguments,
                fullscreenDialog: page.fullscreenDialog,
                child: page.child,
              );
            }
            return page;
          }),
          MaterialPage(
            key: ValueKey('page${currentPages.length + 1}'),
            child: TestPage(title: 'Page ${currentPages.length + 1}'),
          ),
        ];
      } else {
        currentPages = [
          ...currentPages,
          MaterialPage(
            key: ValueKey('page${currentPages.length + 1}'),
            child: TestPage(title: 'Page ${currentPages.length + 1}'),
          ),
        ];
      }
    });
  }

  void _toggleRecreateList(bool value) {
    setState(() {
      recreateList = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Rebuild Test'),
        actions: [
          Row(
            children: [
              const Text('Recreate List'),
              Switch(
                value: recreateList,
                onChanged: _toggleRecreateList,
              ),
            ],
          ),
        ],
      ),
      body: Navigator(
        pages: currentPages,
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          setState(() {
            currentPages.removeLast();
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

class TestPage extends StatelessWidget {
  final String title;

  const TestPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building $title'); // This print statement helps track rebuilds

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
