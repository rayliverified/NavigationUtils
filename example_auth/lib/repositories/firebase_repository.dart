import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/model_user.dart';
import '../utils/value_response.dart';
import 'firebase_repository_base.dart';

class FirebaseRepository extends FirebaseRepositoryBase {
  @override
  void dumpToConsole(Object error, StackTrace stackTrace, [String? library]) =>
      super.dumpToConsole(error, stackTrace, 'FirebaseRepository');

  Future<ValueResponse<T>> returnResultOrError<T>(
      AsyncValueGetter<ValueResponse<T>> func) async {
    try {
      return await func();
    } on FirebaseException catch (error, stacktrace) {
      dumpToConsole(error, stacktrace);
      // ErrorHelper.instance.reportErrorMessage(error.code);
      return ValueResponse.exception(ExceptionWrapper(
          error.message ?? 'An error has occurred.',
          stackTrace: stacktrace,
          code: error.code));
    } catch (error, stacktrace) {
      dumpToConsole(error, stacktrace);
      // ErrorHelper.instance.reportErrorMessage(error.toString());
      return ValueResponse.exception(
        ExceptionWrapper('Operation failed: $error', stackTrace: stacktrace),
      );
    }
  }

  @override
  Future<ValueResponse<void>> setDocument({
    required String collection,
    required String document,
    Map<String, dynamic> data = const {},
  }) {
    return returnResultOrError(() async {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(document)
          .set(data);
      return ValueResponse.success();
    });
  }

  @override
  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Future<ValueResponse<UserModel>> fetchUserModel(String uid) {
    return returnResultOrError(() async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.doc('users/$uid').get();
      if (!snapshot.exists) {
        return ValueResponse.error('User does not exist!');
      }
      if (snapshot.data() == null) {
        return ValueResponse.error('User data is empty!');
      }
      return ValueResponse.success(UserModel.fromJson(snapshot.data()!));
    });
  }

  @override
  Stream<UserModel> streamUserModel(String uid) {
    // TODO: Throw error if null.
    return FirebaseFirestore.instance
        .doc('/users/$uid')
        .snapshots()
        .map((snapshot) => UserModel.fromJson(snapshot.data()!));
  }

  @override
  Future<ValueResponse<void>> setFirestoreUserModel(String id, UserModel user) {
    return returnResultOrError(() async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .set(user.toJson());
      return ValueResponse.success();
    });
  }

  @override
  Future<ValueResponse<void>> updateFirestoreUserModel(
      String id, UserModel user) {
    return returnResultOrError(() async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update(user.toJson());
      return ValueResponse.success();
    });
  }

  @override
  Stream<User?> authStateChanges() =>
      FirebaseAuth.instance.authStateChanges().asBroadcastStream();

  @override
  Future<ValueResponse<UserModel>> createUserWithEmailAndPassword(
      {required String email, required String password}) {
    return returnResultOrError(() async {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final UserModel model = UserModel(
        email: userCredential.user?.email ?? email,
        id: userCredential.user?.uid ?? '',
        photoUrl: userCredential.user?.photoURL ?? '',
        name: userCredential.user?.displayName ?? '',
      );
      return ValueResponse.success(model);
    });
  }

  @override
  Future<ValueResponse<void>> sendPasswordResetEmail({required String email}) {
    return returnResultOrError(() async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return ValueResponse.success();
    });
  }

  @override
  Future<ValueResponse<UserModel>> signInWithGoogleNative(
      {required AuthCredential credential}) {
    return returnResultOrError(() async {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      // TODO: check for nulls?
      final UserModel model = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user?.email ?? '',
        name: userCredential.user?.displayName ?? '',
        photoUrl: userCredential.user?.photoURL ?? '',
      );
      return ValueResponse.success(model);
    });
  }

  @override
  Future<ValueResponse<UserModel>> signInWithGoogleWeb() {
    return returnResultOrError(() async {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      // TODO: check for nulls?
      final UserModel model = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user?.email ?? '',
        name: userCredential.user?.displayName ?? '',
        photoUrl: userCredential.user?.photoURL ?? '',
      );
      return ValueResponse.success(model);
    });
  }

  @override
  Future<ValueResponse<String>> signInWithEmailAndPassword(
      {required String email, required String password}) {
    return returnResultOrError(() async {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (credential.user == null) {
        return ValueResponse.error('User not found');
      }
      return ValueResponse.success(credential.user!.uid);
    });
  }

  @override
  Future<ValueResponse<void>> signOut() {
    return returnResultOrError(() async {
      await FirebaseAuth.instance.signOut();
      return ValueResponse.success();
    });
  }
}
