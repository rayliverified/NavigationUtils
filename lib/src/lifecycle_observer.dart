import 'package:flutter/material.dart';

/// Base [AppLifecycleState] callback class.
///
/// This class observes app lifecycle state changes and invokes
/// the appropriate callbacks when the app state changes.
class LifecycleObserver extends WidgetsBindingObserver {
  /// Callback invoked when the app enters the resumed state.
  final VoidCallback? onResumeCallback;

  /// Callback invoked when the app enters the paused state.
  final VoidCallback? onPauseCallback;

  /// Callback invoked when the app enters the detached state.
  final VoidCallback? onDetachedCallback;

  /// Callback invoked when the app enters the inactive state.
  final VoidCallback? onInactiveCallback;

  /// Callback invoked when the app enters the hidden state.
  final VoidCallback? onHiddenCallback;

  /// Creates a [LifecycleObserver] with optional callbacks for each lifecycle state.
  ///
  /// All callbacks are optional and can be null if not needed.
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

/// A mixin that provides lifecycle observation capabilities to any class.
///
/// This mixin allows classes to observe app lifecycle state changes
/// by automatically setting up a [LifecycleObserver] and registering
/// it with the widget binding.
mixin LifecycleObserverMixin {
  /// The lifecycle observer instance.
  late LifecycleObserver lifecycleObserver;

  /// Initializes the lifecycle observer with callbacks.
  ///
  /// This method should be called to set up lifecycle observation.
  /// It creates a [LifecycleObserver] with the mixin's callback methods
  /// and registers it with [WidgetsBinding].
  void initLifecycleObserver() {
    lifecycleObserver = LifecycleObserver(
        onPauseCallback: onPaused,
        onResumeCallback: onResumed,
        onDetachedCallback: onDetached,
        onInactiveCallback: onInactive,
        onHiddenCallback: onHidden);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  /// Called when the app enters the paused state.
  ///
  /// Override this method to handle app pause events.
  void onPaused() {}

  /// Called when the app enters the resumed state.
  ///
  /// Override this method to handle app resume events.
  void onResumed() {}

  /// Called when the app enters the inactive state.
  ///
  /// Override this method to handle app inactive events.
  void onInactive() {}

  /// Called when the app enters the detached state.
  ///
  /// Override this method to handle app detached events.
  void onDetached() {}

  /// Called when the app enters the hidden state.
  ///
  /// Override this method to handle app hidden events.
  void onHidden() {}

  /// Disposes the lifecycle observer and removes it from the widget binding.
  ///
  /// This method should be called when lifecycle observation is no longer needed.
  void disposeLifecycleObserver() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
  }
}

/// A mixin that provides lifecycle observation capabilities to [State] classes.
///
/// This mixin automatically initializes lifecycle observation in [initState]
/// and disposes it in [dispose], making it convenient for use in StatefulWidgets.
mixin LifecycleObserverStateMixin<T extends StatefulWidget> on State<T> {
  /// The lifecycle observer instance.
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

  /// Called when the app enters the paused state.
  ///
  /// Override this method to handle app pause events.
  void onPaused() {}

  /// Called when the app enters the resumed state.
  ///
  /// Override this method to handle app resume events.
  void onResumed() {}

  /// Called when the app enters the inactive state.
  ///
  /// Override this method to handle app inactive events.
  void onInactive() {}

  /// Called when the app enters the detached state.
  ///
  /// Override this method to handle app detached events.
  void onDetached() {}

  /// Called when the app enters the hidden state.
  ///
  /// Override this method to handle app hidden events.
  void onHidden() {}
}

/// A mixin that provides lifecycle observation capabilities to [ChangeNotifier] classes.
///
/// This mixin allows ChangeNotifier classes to observe app lifecycle state changes.
/// The lifecycle observer is automatically disposed when the ChangeNotifier is disposed.
mixin LifecycleObserverChangeNotifierMixin on ChangeNotifier {
  /// The lifecycle observer instance.
  late LifecycleObserver lifecycleObserver;

  /// Initializes the lifecycle observer with callbacks.
  ///
  /// This method should be called to set up lifecycle observation.
  /// It creates a [LifecycleObserver] with the mixin's callback methods
  /// and registers it with [WidgetsBinding].
  void initLifecycleObserverListener() {
    lifecycleObserver = LifecycleObserver(
        onPauseCallback: onPaused,
        onResumeCallback: onResumed,
        onDetachedCallback: onDetached,
        onInactiveCallback: onInactive,
        onHiddenCallback: onHidden);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  }

  /// Called when the app enters the paused state.
  ///
  /// Override this method to handle app pause events.
  void onPaused() {}

  /// Called when the app enters the resumed state.
  ///
  /// Override this method to handle app resume events.
  void onResumed() {}

  /// Called when the app enters the inactive state.
  ///
  /// Override this method to handle app inactive events.
  void onInactive() {}

  /// Called when the app enters the detached state.
  ///
  /// Override this method to handle app detached events.
  void onDetached() {}

  /// Called when the app enters the hidden state.
  ///
  /// Override this method to handle app hidden events.
  void onHidden() {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);
    super.dispose();
  }
}
