/// UserManager V3 (20241006)
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:example_auth/firebase_constants.dart';
import 'package:example_auth/models/model_user.dart';
import 'package:example_auth/services/debug_logger.dart';
import 'package:example_auth/services/shared_preferences_helper.dart';
import 'package:example_auth/utils/value_response.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_gravatar/simple_gravatar.dart';

class UserManager {
  static const String name = 'UserManager';

  static UserManager? _instance;

  static UserManager get instance {
    if (_instance == null) {
      DebugLogger.instance.printFunction('UserManager Initialized', name: name);
      _instance ??= UserManager._();
      return _instance!;
    }
    return _instance!;
  }

  String? id;
  StreamSubscription<DocumentSnapshot>? userSubscription;
  final ValueNotifier<UserModel> user = ValueNotifier(UserModel.empty());
  late DocumentReference<UserModel> userDocRef = FirebaseFirestore.instance
      .collection(FirebaseConstants.users)
      .doc(id)
      .withConverter<UserModel>(
          fromFirestore: (snapshot, options) =>
              UserModel.fromJson(snapshot.data()!),
          toFirestore: (value, options) => value.toJson());

  UserManager._();

  Future<void> dispose() async {
    id = null;
    userSubscription?.cancel();
    user.value = UserModel.empty();
  }

  Future<void> startUserStreamSubscription(String id) async {
    DebugLogger.instance
        .printFunction('startUserStreamSubscription: $id', name: name);

    this.id = id;
    userSubscription?.cancel();
    userDocRef = FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .doc(id)
        .withConverter<UserModel>(
            fromFirestore: (snapshot, options) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (value, options) => value.toJson());
    userSubscription = userDocRef.snapshots().listen((snapshot) {
      DebugLogger.instance.printAction('UserModel Changed', name: name);
      if (snapshot.exists && snapshot.data() != null) {
        user.value = snapshot.data()!;
        SharedPreferencesHelper.instance
            .setString('user', jsonEncode(snapshot.data()!.toJson()));
      } else {
        user.value = UserModel.empty();
      }
    });
  }

  /// Loads the [user] model from local storage.
  Future<UserModel?> loadUserModelLocal() async {
    DebugLogger.instance.printFunction('loadUserModelLocal', name: name);

    String? userModelData = SharedPreferencesHelper.instance.getString('user');
    if (userModelData != null) {
      UserModel userModel = UserModel.fromJson(jsonDecode(userModelData));
      user.value = userModel;
      id = userModel.id;
      return userModel;
    } else {
      user.value = UserModel.empty();
      id = null;
    }
    return null;
  }

  Future<ValueResponse<UserModel>> fetchUserModel(String uid) async {
    final DocumentSnapshot<UserModel> snapshot = await FirebaseFirestore
        .instance
        .collection(FirebaseConstants.users)
        .doc(uid)
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

  /// Creates a [UserModel] from Firebase User and
  /// saves to server.
  Future<UserModel?> createUserModel(UserModel user) async {
    DebugLogger.instance.printFunction('createUserModel: $user', name: name);

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
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .doc(user.id)
        .withConverter<UserModel>(
            fromFirestore: (snapshot, options) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (value, options) => value.toJson())
        .set(newUser);
    await startUserStreamSubscription(user.id);
    return newUser;
  }

  Future<void> resetUserModel() async {
    DebugLogger.instance.printFunction('resetUserModel', name: name);

    user.value = UserModel.empty();
    await SharedPreferencesHelper.instance.remove('user');
  }
}
