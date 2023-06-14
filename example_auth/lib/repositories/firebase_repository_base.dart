import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:example_auth/repositories/firebase_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

import '../../utils/value_response.dart';
import '../firebase_options.dart';
import '../models/model_user.dart';

/// Platform independent abstraction for Firebase SDK.
abstract class FirebaseRepositoryBase {
  static FirebaseRepositoryBase? _instance;

  /// Enable Firebase SDK implementation based on platform
  static FirebaseRepositoryBase get instance {
    if (_instance == null) {
      throw Exception('Firebase has not been initialized yet! Please call '
          'FirebaseRepositoryBase.initialize() first!');
    }
    return _instance!;
  }

  /// Use this method to initialize firebase functionality for any platform.
  static Future<ValueResponse<void>> initialize({
    String? projectId,
    String? apiKey,
    String? databaseId,
  }) async {
      // TODO [ERROR_HANDLING]: handle error. Catch errors for
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      _instance = FirebaseRepository();
    return ValueResponse.success();
  }

  @visibleForTesting
  static void useMock(FirebaseRepositoryBase repository) {
    _instance = repository;
  }

  /// Dumps error and the stacktrace to console using `FlutterError`. This can
  /// be used by the implementations of this class to dump for logging and
  /// debugging.
  void dumpToConsole(Object error, StackTrace stackTrace,
      [String library = 'FirebaseRepositoryBase']) {
    FlutterError.reportError(FlutterErrorDetails(
        stack: stackTrace, exception: error, library: library));
  }

  Future<ValueResponse<void>> setDocument({
    required String collection,
    required String document,
    Map<String, dynamic> data = const {},
  }) =>
      throw UnimplementedError('Use implementation');

  String? getUserId() => throw UnimplementedError('Use implementation');

  Future<ValueResponse<UserModel>> fetchUserModel(String uid) =>
      throw UnimplementedError('Use implementation');

  Stream<UserModel> streamUserModel(String uid) =>
      throw UnimplementedError('Use implementation');

  /// Updates the existing Firestore users collection, creates a new document if
  /// it does not already exist.
  Future<ValueResponse<void>> setFirestoreUserModel(
          String id, UserModel user) =>
      throw UnimplementedError('Use implementation');

  /// Updates the Firestore users collection.
  /// Calling update does nothing if the document does not exist.
  Future<ValueResponse<void>> updateFirestoreUserModel(
          String id, UserModel user) =>
      throw UnimplementedError('Use implementation');

  Stream<User?> authStateChanges() =>
      throw UnimplementedError('Use implementation');

  Future<ValueResponse<UserModel>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError('Use implementation');

  Future<ValueResponse<void>> sendPasswordResetEmail({required String email}) =>
      throw UnimplementedError('Use implementation');

  Future<ValueResponse<UserModel>> signInWithGoogleNative(
          {required AuthCredential credential}) =>
      throw UnimplementedError('Use implementation');

  Future<ValueResponse<UserModel>> signInWithGoogleWeb() =>
      throw UnimplementedError();

  Future<ValueResponse<String>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError('Use implementation');

  Future<ValueResponse<void>> signOut() =>
      throw UnimplementedError('Use implementation');
}

/// Allows to quickly convert any firebase exception to [ExceptionWrapper].
extension FirebaseExceptionExtension on FirebaseException {
  ExceptionWrapper toException([StackTrace? trace]) =>
      ExceptionWrapper(message ?? 'An error has occurred.',
          stackTrace: trace ?? stackTrace, code: code);
}
