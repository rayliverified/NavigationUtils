import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navigation_utils/navigation_utils.dart';

import '../ui/ui_page_wrapper.dart';

/// Initialization placeholder with a loading indicator.
///
/// Used to resolve loading destination.
class InitializationPage extends StatelessWidget {
  static const String name = 'initialization';

  const InitializationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

/// Initialization placeholder with a loading indicator.
///
/// Used to resolve loading destination.
class InitializationErrorPage extends StatelessWidget {
  static const String name = 'initialization_error';

  final VoidCallback? onRetry;
  final String? errorMessage;

  const InitializationErrorPage({super.key, this.onRetry, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage ?? 'Unknown error. Please try again.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            Container(
              height: 15,
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reload',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

class UnknownPage extends StatelessWidget {
  static const String name = 'unknown';

  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '404',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            Container(
              height: 15,
            ),
            ElevatedButton(
              onPressed: () =>
                  NavigationManager.instance.routerDelegate.routes.length > 1
                      ? NavigationManager.instance.pop()
                      : NavigationManager.instance.pushReplacement('/'),
              child: const Text('Back',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
