import 'package:flutter/material.dart';

/// Base [AppLifecycleState] callback class.
class LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onResumeCallback;
  final VoidCallback? onPauseCallback;
  final VoidCallback? onDetachedCallback;
  final VoidCallback? onInactiveCallback;
  final VoidCallback? onHiddenCallback;

  LifecycleObserver({
    this.onResumeCallback,
    this.onPauseCallback,
    this.onDetachedCallback,
    this.onInactiveCallback,
    this.onHiddenCallback,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onPauseCallback?.call();
        break;
      case AppLifecycleState.resumed:
        onResumeCallback?.call();
        break;
      case AppLifecycleState.detached:
        onDetachedCallback?.call();
        break;
      case AppLifecycleState.inactive:
        onInactiveCallback?.call();
        break;
      case AppLifecycleState.hidden:
        onHiddenCallback?.call();
        break;
      default:
        break;
    }
  }
}

mixin LifecycleObserverMixin {
  late LifecycleObserver lifecycleObserver;

  void initLifecycleObserver() {
    lifecycleObserver = LifecycleObserver(
        onPauseCallback: onPaused,
        onResumeCallback: onResumed,
        onDetachedCallback: onDetached,
        onInactiveCallback: onInactive,
        onHiddenCallback: onHidden);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  void onPaused() {}

  void onResumed() {}

  void onInactive() {}

  void onDetached() {}

  void onHidden() {}

  void disposeLifecycleObserver() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
  }
}

mixin LifecycleObserverStateMixin<T extends StatefulWidget> on State<T> {
  late LifecycleObserver lifecycleObserver;

  @override
  void initState() {
    super.initState();
    lifecycleObserver = LifecycleObserver(
        onPauseCallback: onPaused,
        onResumeCallback: onResumed,
        onDetachedCallback: onDetached,
        onInactiveCallback: onInactive,
        onHiddenCallback: onHidden);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
    super.dispose();
  }

  void onPaused() {}

  void onResumed() {}

  void onInactive() {}

  void onDetached() {}

  void onHidden() {}
}

mixin LifecycleObserverChangeNotifierMixin on ChangeNotifier {
  late LifecycleObserver lifecycleObserver;

  void initLifecycleObserverListener() {
    lifecycleObserver = LifecycleObserver(
        onPauseCallback: onPaused,
        onResumeCallback: onResumed,
        onDetachedCallback: onDetached,
        onInactiveCallback: onInactive,
        onHiddenCallback: onHidden);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  void onPaused() {}

  void onResumed() {}

  void onInactive() {}

  void onDetached() {}

  void onHidden() {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
    super.dispose();
  }
}
