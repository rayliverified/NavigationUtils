import 'package:flutter/material.dart';

class LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onResumeCallback;
  final VoidCallback? onPauseCallback;
  final VoidCallback? onDetachedCallback;
  final VoidCallback? onInactiveCallback;

  LifecycleObserver({
    this.onResumeCallback,
    this.onPauseCallback,
    this.onDetachedCallback,
    this.onInactiveCallback,
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
        onInactiveCallback: onInactive);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  void onPaused() {}

  void onResumed() {}

  void onInactive() {}

  void onDetached() {}

  void disposeLifecycleObserver() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
  }
}

mixin LifecycleObserverChangeNotifierMixin on ChangeNotifier {
  late LifecycleObserver lifecycleObserver;

  void initLifecycleObserverListener() {
    lifecycleObserver = LifecycleObserver(
        onPauseCallback: onPaused,
        onResumeCallback: onResumed,
        onDetachedCallback: onDetached,
        onInactiveCallback: onInactive);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  void onPaused() {}

  void onResumed() {}

  void onInactive() {}

  void onDetached() {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
    super.dispose();
  }
}
