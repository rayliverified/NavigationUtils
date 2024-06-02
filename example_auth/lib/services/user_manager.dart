import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:simple_gravatar/simple_gravatar.dart';

import '../models/model_user.dart';
import '../utils/value_response.dart';
import 'debug_logger.dart';

class UserManager implements Disposable {
  static UserManager? _instance;

  static UserManager get instance {
    if (_instance == null) {
      DebugLogger.instance.printFunction('UserManager Initialized');
      _instance ??= UserManager._();
      return _instance!;
    }
    return _instance!;
  }

  StreamSubscription<DocumentSnapshot>? userSubscription;
  final ValueNotifier<UserModel> user = ValueNotifier(UserModel.initial());

  UserManager._();

  @override
  FutureOr onDispose() {
    userSubscription?.cancel();
    user.value = UserModel.initial();
  }

  Future<void> startUserStreamSubscription(String uid) async {
    DebugLogger.instance.printFunction('startUserStreamSubscription: $uid');

    userSubscription?.cancel();
    userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .withConverter<UserModel>(
            fromFirestore: (snapshot, options) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (value, options) => value.toJson())
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        user.value = snapshot.data()!;
      } else {
        user.value = UserModel.empty();
      }
    });
  }

  /// Update username in Firebase. Re-fetch the UserModel again.
  Future<void> updateUsername(String newUsername) async {
    DebugLogger.instance.printFunction('updateUsername: $newUsername');

    if (user.value.id.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.value.id)
        .update(user.value.copyWith(name: newUsername).toJson());
    await loadUserModel(user.value.id);
  }

  /// Fetches the [UserModel] with the user's [uid] from Firestore by calling
  /// [fetchUserModel], then updates the [user] field.
  Future<void> loadUserModel(String uid) async {
    DebugLogger.instance.printFunction('loadUserModel: $uid');

    final ValueResponse<UserModel> response = await fetchUserModel(uid);
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
      throw response.error;
    }
    user.value = response.data;
  }

  /// Creates a [UserModel] from Firebase User and
  /// saves to server.
  Future<UserModel?> createUserModel(UserModel user) async {
    DebugLogger.instance.printFunction('createUserModel: $user');

    // Get photo url from Firebase.
    // Otherwise, get a photo from Gravatar.
    String photoUrl;
    if (user.photoUrl.isNotEmpty) {
      photoUrl = user.photoUrl;
    } else {
      photoUrl = Gravatar(user.email).imageUrl(
        size: 200,
        defaultImage: GravatarImage.retro,
        rating: GravatarRating.pg,
        fileExtension: true,
      );
    }

    // Create the new UserModel.
    UserModel newUser = user.copyWith(photoUrl: photoUrl);
    // Update the user in Firestore.
    await setFirestoreUserModel(user.id, newUser);
    return newUser;
  }

  Future<ValueResponse<UserModel>> fetchUserModel(String uid) async {
    final DocumentSnapshot<UserModel> snapshot = await FirebaseFirestore
        .instance
        .doc('users/$uid')
        .withConverter<UserModel>(
            fromFirestore: (snapshot, options) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (value, options) => value.toJson())
        .get();
    if (!snapshot.exists) {
      return ValueResponse.error('User does not exist!');
    }
    if (snapshot.data() == null) {
      return ValueResponse.error('User data is empty!');
    }
    return ValueResponse.success(snapshot.data());
  }

  Future<ValueResponse<void>> setFirestoreUserModel(
      String id, UserModel user) async {
    DebugLogger.instance.printFunction('setFirestoreUserModel: $id, $user');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .withConverter<UserModel>(
            fromFirestore: (snapshot, options) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (value, options) => value.toJson())
        .set(user);
    return ValueResponse.success();
  }

  void resetUserModel() {
    DebugLogger.instance.printFunction('resetUserModel');

    user.value = UserModel.empty();
  }
}

//handles updating the user when updating profile
// Future<bool> updateUser(
//     UserModel user, String oldEmail, String password) async {
//   bool _result = false;
//   await _auth
//       .signInWithEmailAndPassword(email: oldEmail, password: password)
//       .then((_firebaseUser) {
//     _firebaseUser.user.updateEmail(user.email);
//     _updateUserFirestore(user, _firebaseUser.user);
//     _result = true;
//   });
//   return _result;
// }

// Future<bool> isAdmin() async {
//   bool _isAdmin = false;
//   DocumentSnapshot adminRef =
//       await _db.collection('admin').doc(getUser?.uid).get();
//   if (adminRef.exists) {
//     _isAdmin = true;
//   }
//   return _isAdmin;
// }

/// Check if the use has created an account with the [email].
/// User has an account if their email is found in `user_emails/{email}`.
// Future<bool> hasAccount(String email) async {
//   DocumentSnapshot documentSnapshot =
//       await _db.collection('user_emails').doc(email).get();
//   if (documentSnapshot.exists) {
//     return true;
//   }
//   return false;
// }

// void updateUserModel(UserModel user) {
//   if (getUser != null) {
//     _db.doc('users/${getUser.uid}').update(user.toJson());
//   }
// }
