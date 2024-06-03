import 'package:logging/logging.dart';

/// A robust logging utility for managing extensive logs in Dart applications.
///
/// This logger excels in managing a high volume of log messages, providing sophisticated
/// filtering and highlighting capabilities according to the criteria specified in `DebugLoggerConfig`.
///
/// Specialized logging functions.
/// - `printRebuild`: Logs widget rebuilds to assist in identifying performance issues.
/// - `printAction`: Logs user actions, useful for tracking user interactions and behaviors.
/// - `printFunction`: Logs detailed function call information, aiding in debugging complex operations.
/// - `printInfo`: Provides a general-purpose logging method for informational messages.
///
/// Example:
/// ```dart
/// void main() {
///   // Create a new configuration.
///   DebugLogger.instance.config.enableCategory(DebugCategory.info)
///     ..setHighlight(name: AuthService.name);
/// }
/// ```
///
/// Setting up Filtering Capabilities:
/// Configure logging for specific categories, and set highlights for better debugging visibility.
///
/// ### Enabling and Disabling Categories
/// You can specify which categories of logs should be recorded or ignored. This is useful to reduce noise
/// in the log output and focus on relevant information.
///
/// ```dart
/// config.enableCategory(DebugCategory.function);
/// config.disableCategory(DebugCategory.info);
/// ```
///
/// ### Highlighting Logs
/// Highlighting log messages by name or category.
///
/// ```dart
/// config.setHighlight(name: AuthService.name);
/// ```
class DebugLogger {
  static DebugLogger? _instance;
  static DebugLogger get instance {
    _instance ??= DebugLogger();
    return _instance!;
  }

  DebugLoggerConfig _config = DebugLoggerConfig();
  DebugLoggerConfig get config => _config;

  DebugLogger({DebugLoggerConfig? config}) {
    if (config != null) _config = config;
  }

  void setConfig(DebugLoggerConfig config) {
    _config = config;
  }

  /// Logs a message with optional category, name, and level.
  ///
  /// Filters messages based on the configuration settings such as enabled and
  /// disabled categories, and highlights.
  void log(Object? message,
      {String? category, String? name, Level level = Level.INFO}) {
    try {
      // Print only highlighted and enabled category messages.
      if (config.highlights.isNotEmpty) {
        if (config.isHighlighted(category: category, name: name)) {
          print(message, category: category, name: name, level: level);
          return;
        }

        if (_config.enabledCategories.isNotEmpty) {
          if (_config.isCategoryEnabled(category ?? '')) {
            print(message, category: category, name: name, level: level);
            return;
          }
        }

        return;
      }

      if (_config.isCategoryDisabled(category ?? '')) {
        return;
      }

      if (_config.isCategoryEnabled(category ?? '')) {
        print(message, category: category, name: name, level: level);
        return;
      }

      // Return and only print enabled categories if enabled categories are provided.
      if (_config.enabledCategories.isNotEmpty) {
        return;
      }

      // Print all by default.
      print(message, category: category, name: name, level: level);
    } catch (e) {
      print(e, category: DebugCategory.error, level: Level.WARNING);
    }
  }

  /// Prints a log message to the console using the [Logger] library.
  void print(Object? message,
      {String? category, String? name, Level level = Level.INFO}) {
    final logMessage = StringBuffer();
    if (name?.isNotEmpty ?? false) {
      logMessage.write('[$name] ');
    }
    logMessage.write(message);

    Logger.root.log(level, logMessage.toString());
  }

  /// [Level.FINEST] Specialized logging function used to trace widget rebuilds in Flutter applications.
  /// This method helps in debugging unnecessary widget rebuilds by logging
  /// detailed rebuild information whenever a widget's `build` method is invoked.
  ///
  /// Example:
  /// ```dart
  /// class MyWidget extends StatelessWidget {
  /// static const String name = 'ui_my_widget';
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   DebugLogger.instance.printRebuild(name);
  ///   return Container(...);
  /// }
  /// }
  /// ```
  void printRebuild(String name) {
    log('Rebuild',
        category: DebugCategory.rebuild, name: name, level: Level.FINEST);
  }

  /// [Level.FINEST] Specialized logging function used for tracing user actions within an application.
  /// This method was designed to log significant user interactions which could be crucial for
  /// understanding user behavior and for debugging purposes.
  ///
  /// Example:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () {
  ///     DebugLogger.instance.printAction("Login button clicked", name: LoginPage.name);
  ///     // Perform action
  ///   },
  ///   child: Text('Login'),
  /// )
  /// ```
  void printAction(Object? message, {String? name}) {
    log(message,
        category: DebugCategory.action, name: name, level: Level.FINEST);
  }

  /// [Level.FINEST] Logs detailed information about function executions, including function name and passed parameters.
  /// This method is particularly useful for debugging and tracing the flow of data through complex operations.
  ///
  /// Example:
  /// ```dart
  /// Future<ValueResponse<void>> registerWithEmailAndPassword({
  ///   String? firstName,
  ///   String? lastName,
  /// }) async {
  ///   DebugLogger.instance.printFunction(
  ///     'registerWithEmailAndPassword(firstName: $firstName, lastName: $lastName)',
  ///     name: 'AuthService'
  ///   );
  /// }
  /// ```
  void printFunction(Object? message, {required String name}) {
    log(message,
        category: DebugCategory.function, name: name, level: Level.FINEST);
  }

  /// [Level.INFO] Default log method.
  void printInfo(Object? message, {String? name}) {
    log(message, category: DebugCategory.info, level: Level.INFO);
  }
}

/// Configuration for [DebugLogger], including enabled and disabled categories,
/// and highlighting specific logs.
class DebugLoggerConfig {
  Set<String> enabledCategories = {};
  Set<String> disabledCategories = {};
  Set<String> highlights = {};

  DebugLoggerConfig();

  /// Checks if a category is enabled for logging.
  bool isCategoryEnabled(String? category) {
    if (category == null) return false;
    if (enabledCategories.isEmpty) return true;
    return enabledCategories.contains(category);
  }

  /// Checks if a category is disabled for logging.
  bool isCategoryDisabled(String? category) {
    if (category == null) return false;
    return disabledCategories.contains(category);
  }

  /// Enables a specific logging category.
  ///
  /// Once a category is enabled, only log entries that belong to this category will be recorded,
  /// unless other categories are also explicitly enabled. This method provides a focused logging
  /// experience by excluding all logs that do not belong to the enabled categories if any are specified.
  ///
  /// Example:
  /// ```dart
  /// config = DebugLoggerConfig();
  /// config.enableCategory(DebugCategory.function);
  /// config.enableCategory(DebugCategory.function);
  /// ```
  DebugLoggerConfig enableCategory(String category) {
    enabledCategories.add(category);
    disabledCategories.remove(category);

    return this;
  }

  /// Disables a specific logging category.
  ///
  /// Once a category is disabled, log entries that belong to this category will not be recorded.
  DebugLoggerConfig disableCategory(String category) {
    enabledCategories.remove(category);
    disabledCategories.add(category);

    return this;
  }

  /// Determines if a category or name is highlighted within the logger configuration.
  ///
  /// Setting a highlight disables all other logs except those that match the highlighted
  /// [category] or [name]. Enabled categories are also printed.
  bool isHighlighted({String? category, String? name}) {
    if (highlights.isEmpty) return false;

    return highlights.any((highlight) => highlight.contains('-')
        ? (highlight ==
            [category, name].where((item) => item != null).join('-'))
        : (highlight == category || highlight == name));
  }

  /// Sets a highlight for a specific category and name.
  DebugLoggerConfig setHighlight({String? category, String? name}) {
    String highlight = [category, name].where((item) => item != null).join('-');
    if (highlight.isNotEmpty) {
      highlights.add(highlight);
    }

    return this;
  }
}

/// Defines common categories used in [DebugLogger].
class DebugCategory {
  static const String rebuild = 'Rebuild';
  static const String action = 'Action';
  static const String function = 'Function';
  static const String info = 'Info';
  static const String warning = 'Warning';
  static const String error = 'Error';
  static const String network = 'Network';
}
