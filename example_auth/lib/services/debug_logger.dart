// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

class DebugLogger {
  static DebugLogger get instance => DebugLogger();

  static DebugLoggerConfig config = DebugLoggerConfig();

  DebugLogger({DebugLoggerConfig? config}) {
    if (config != null) DebugLogger.config = config;
  }

  void setConfig(DebugLoggerConfig config) {
    DebugLogger.config = config;
  }

  void printRebuild(Object? obj) {
    if (config.printInProduction == false && (kReleaseMode || kProfileMode))
      return;
    if (config.printRebuilds ?? false) print('Rebuild $obj');
  }

  void printAction(Object? obj) {
    if (config.printInProduction == false && (kReleaseMode || kProfileMode))
      return;
    if (config.printActions ?? false) print(obj);
  }

  void printFunction(Object? obj) {
    if (config.printInProduction == false && (kReleaseMode || kProfileMode))
      return;
    if (config.printFunctions ?? false) print(obj);
  }

  void printInfo(Object? obj) {
    if (config.printInProduction == false && (kReleaseMode || kProfileMode))
      return;
    if (config.printInfo ?? false) print(obj);
  }
}

class DebugLoggerConfig {
  final bool? printRebuilds;
  final bool? printFunctions;
  final bool? printActions;
  final bool? printInfo;
  final bool printInProduction;

  DebugLoggerConfig(
      {this.printRebuilds,
      this.printFunctions,
      this.printActions,
      this.printInfo,
      this.printInProduction = false});
}
