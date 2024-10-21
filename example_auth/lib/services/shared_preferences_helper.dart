/// SharedPreferencesHelper V5 (20241007)
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper implements SharedPreferencesWithCache {
  static const String instanceName = 'SharedPreferencesHelper';

  static SharedPreferencesHelper? _instance;

  static SharedPreferencesHelper get instance {
    if (_instance == null) {
      throw Exception(
          'SharedPreferencesHelper has not been initialized. Call `init()` to initialize before using.');
    }
    return _instance!;
  }

  late final SharedPreferencesWithCache sharedPreferences;
  final Map<String, Object?> _sharedPreferencesHolder = {};

  SharedPreferencesHelper._();

  static Future<SharedPreferencesHelper> init() async {
    _instance = SharedPreferencesHelper._();
    _instance!.sharedPreferences = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions());
    return _instance!;
  }

  Future<void> backupInMemory({Set<String> keys = const {}}) async {
    _sharedPreferencesHolder.clear();
    Set<String> keysHolder = keys.isNotEmpty ? keys : sharedPreferences.keys;
    for (String key in keysHolder) {
      Object? value = sharedPreferences.get(key);
      if (value == null) continue;
      _sharedPreferencesHolder[key] = value;
    }
    return;
  }

  Future<void> restoreFromMemory() async {
    List<Future<void>> restoreTasks = [];
    _sharedPreferencesHolder.forEach((key, value) {
      switch (value.runtimeType) {
        case const (String):
          restoreTasks.add(sharedPreferences.setString(key, value as String));
        case const (bool):
          restoreTasks.add(sharedPreferences.setBool(key, value as bool));
        case const (int):
          restoreTasks.add(sharedPreferences.setInt(key, value as int));
        case const (double):
          restoreTasks.add(sharedPreferences.setDouble(key, value as double));
        case const (List):
          restoreTasks
              .add(sharedPreferences.setStringList(key, value as List<String>));
      }
    });
    await Future.wait(restoreTasks);
    _sharedPreferencesHolder.clear();
  }

  Map<String, Object> getAll() {
    final Map<String, Object> sharedPreferencesHolder = {};
    for (String key in sharedPreferences.keys) {
      Object? value = sharedPreferences.get(key);
      if (value == null) continue;
      sharedPreferencesHolder[key] = value;
    }

    return sharedPreferencesHolder;
  }

  @override
  Future<void> clear() {
    return sharedPreferences.clear();
  }

  @override
  bool containsKey(String key) {
    return sharedPreferences.containsKey(key);
  }

  @override
  Object? get(String key) {
    return sharedPreferences.get(key);
  }

  @override
  bool? getBool(String key) {
    return sharedPreferences.getBool(key);
  }

  @override
  double? getDouble(String key) {
    return sharedPreferences.getDouble(key);
  }

  @override
  int? getInt(String key) {
    return sharedPreferences.getInt(key);
  }

  @override
  String? getString(String key) {
    return sharedPreferences.getString(key);
  }

  @override
  List<String>? getStringList(String key) {
    return sharedPreferences.getStringList(key);
  }

  @override
  Future<void> reloadCache() {
    return sharedPreferences.reloadCache();
  }

  @override
  Future<void> remove(String key) {
    return sharedPreferences.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) {
    return sharedPreferences.setBool(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) {
    return sharedPreferences.setDouble(key, value);
  }

  @override
  Future<void> setInt(String key, int value) {
    return sharedPreferences.setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) {
    return sharedPreferences.setString(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    return sharedPreferences.setStringList(key, value);
  }

  @override
  Set<String> get keys => sharedPreferences.keys;
}
