/// SharedPreferencesHelper V3 (20241006)
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper implements SharedPreferences {
  static const String instanceName = 'SharedPreferenceHelper';

  static SharedPreferencesHelper? _instance;

  static SharedPreferencesHelper get instance {
    if (_instance == null) {
      throw Exception(
          'SharedPreferenceHelper has not been initialized. Call `init()` to initialize before using.');
    }
    return _instance!;
  }

  late SharedPreferences _sharedPreferences;
  SharedPreferences get sharedPreferences => _sharedPreferences;
  final Map<String, Object?> _sharedPreferencesHolder = {};

  SharedPreferencesHelper._();

  static Future<SharedPreferencesHelper> init() async {
    _instance = SharedPreferencesHelper._();
    _instance!._sharedPreferences = await SharedPreferences.getInstance();
    return _instance!;
  }

  Future<void> backupInMemory({Set<String> keys = const {}}) async {
    _sharedPreferencesHolder.clear();
    Set<String> keysHolder =
        keys.isNotEmpty ? keys : sharedPreferences.getKeys();
    for (String key in keysHolder) {
      Object? value = _sharedPreferences.get(key);
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
          restoreTasks.add(_sharedPreferences.setString(key, value as String));
        case const (bool):
          restoreTasks.add(_sharedPreferences.setBool(key, value as bool));
        case const (int):
          restoreTasks.add(_sharedPreferences.setInt(key, value as int));
        case const (double):
          restoreTasks.add(_sharedPreferences.setDouble(key, value as double));
        case const (List):
          restoreTasks.add(
              _sharedPreferences.setStringList(key, value as List<String>));
      }
    });
    await Future.wait(restoreTasks);
    _sharedPreferencesHolder.clear();
  }

  Map<String, Object> getAll() {
    final Map<String, Object> sharedPreferencesHolder = {};
    for (String key in _sharedPreferences.getKeys()) {
      Object? value = _sharedPreferences.get(key);
      if (value == null) continue;
      sharedPreferencesHolder[key] = value;
    }

    return sharedPreferencesHolder;
  }

  @override
  Future<bool> clear() {
    return _sharedPreferences.clear();
  }

  @override
  Future<bool> commit() {
    // ignore: deprecated_member_use
    return _sharedPreferences.commit();
  }

  @override
  bool containsKey(String key) {
    return _sharedPreferences.containsKey(key);
  }

  @override
  Object? get(String key) {
    return _sharedPreferences.get(key);
  }

  @override
  bool? getBool(String key) {
    return _sharedPreferences.getBool(key);
  }

  @override
  double? getDouble(String key) {
    return _sharedPreferences.getDouble(key);
  }

  @override
  int? getInt(String key) {
    return _sharedPreferences.getInt(key);
  }

  @override
  Set<String> getKeys() {
    return _sharedPreferences.getKeys();
  }

  @override
  String? getString(String key) {
    return _sharedPreferences.getString(key);
  }

  @override
  List<String>? getStringList(String key) {
    return _sharedPreferences.getStringList(key);
  }

  @override
  Future<void> reload() {
    return _sharedPreferences.reload();
  }

  @override
  Future<bool> remove(String key) {
    return _sharedPreferences.remove(key);
  }

  @override
  Future<bool> setBool(String key, bool value) {
    return _sharedPreferences.setBool(key, value);
  }

  @override
  Future<bool> setDouble(String key, double value) {
    return _sharedPreferences.setDouble(key, value);
  }

  @override
  Future<bool> setInt(String key, int value) {
    return _sharedPreferences.setInt(key, value);
  }

  @override
  Future<bool> setString(String key, String value) {
    return _sharedPreferences.setString(key, value);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    return _sharedPreferences.setStringList(key, value);
  }
}
