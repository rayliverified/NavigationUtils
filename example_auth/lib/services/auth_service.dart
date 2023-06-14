import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:simple_gravatar/simple_gravatar.dart';
import 'package:universal_io/io.dart';

import '../models/model_user.dart';
import '../repositories/firebase_repository_base.dart';
import '../utils/auth_exceptions.dart';
import '../utils/value_response.dart';
import 'debug_logger.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => AuthResult._(success: true);

  factory AuthResult.failure([String errorMessage = '']) =>
      AuthResult._(success: false, errorMessage: errorMessage);
}

abstract class AuthServiceBase implements Disposable {
  ValueNotifier<UserModel> userModel = ValueNotifier(UserModel.initial());
  ValueNotifier<User?> user = ValueNotifier(null);
  late Stream<User?> firebaseAuthUserStream;
  late StreamSubscription firebaseAuthListener;

  bool get isAuthenticated => user.value != null;

  @override
  void onDispose() {
    firebaseAuthListener.cancel();
    userModel.dispose();
  }

  void initialize() {}

  /// An awaitable function that AuthService is initialized
  /// in the proper order on app startup.
  ///
  /// Internally, this function calls [fetchAndSetUserModel]
  /// and returns the [AuthResult].
  ///
  /// FirebaseAuth's synchronous getter for auth state
  /// is not dependable on app initialization and will return
  /// unauthorized on certain app starts such as hot reload.
  /// Auth dependent functions should subscribe to
  /// [firebaseAuthListener].
  Future<AuthResult> initAuthState() async => throw ('Unimplemented error.');

  // BEGIN: Firebase Auth Methods.
  Future<ValueResponse<void>> signInWithEmailAndPassword(
          String email, String password) async =>
      throw ('Unimplemented error.');

  Future<ValueResponse<void>> registerWithEmailAndPassword(
          String name, String email, String password) =>
      throw ('Unimplemented error.');

  Future<void> sendPasswordResetEmail(String email) async {}

  Future<void> signOut() async {}

  Future<AuthResult?> googleSignIn() async {
    return null;
  }

  Future<void> resetPassword(String email) async {}

  // END: Firebase Auth Methods.

  // BEGIN: UserModel.

  Future<UserModel?> initUserModel(UserModel user) async =>
      throw ('Unimplemented error.');

  Future<void> updateUsername(String newUsername) async {}

  Future<void> updateFirestoreUserModel(String id, UserModel user) async {}

  Future<void> setFirestoreUserModel(String id, UserModel user) async {}

  /// fetch user profile from firebase and save in in [userModel]
  Future<void> fetchAndSetUserModel(String id) async {}

  void resetUserModel() {}
// END: User Model.
}

class AuthService extends AuthServiceBase {
  static AuthService? _instance;

  static AuthService get instance {
    if (_instance == null) {
      throw Exception('AuthService has not been initialized yet! Please call '
          'AuthService.initialize() first!');
    }
    return _instance!;
  }

  factory AuthService() {
    DebugLogger.instance.printFunction('AuthService Initialized');
    // An instance persists the AuthService.
    _instance ??= AuthService._();
    return _instance!;
  }

  factory AuthService.initialize() {
    DebugLogger.instance.printFunction('AuthService Initialized');
    // An instance persists the AuthService.
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._() {
    firebaseAuthUserStream =
        FirebaseRepositoryBase.instance.authStateChanges().asBroadcastStream();
    firebaseAuthListener =
        FirebaseRepositoryBase.instance.authStateChanges().listen((user) {
      DebugLogger.instance.printFunction('authStateChanges: $user');
      this.user.value = user;
      if (user != null) {
        fetchAndSetUserModel(user.uid);
        if (userModel.value.id.isEmpty) {
          onUserAuthenticated(user.uid);
        }
      } else {
        resetUserModel();
        onUserUnauthenticated();
      }
    });
  }

  void onUserAuthenticated(String uid) {
    DebugLogger.instance.printFunction('onUserAuthenticated $uid');
  }

  void onUserUnauthenticated() {
    DebugLogger.instance.printFunction('onUserUnauthenticated');
  }

  @override
  void onDispose() {
    super.onDispose();
    _instance = AuthService._();
  }

  @override
  Future<AuthResult> initAuthState() async {
    DebugLogger.instance.printFunction('initAuthState');
    DebugLogger.instance.printInfo(
        'Current User: ${FirebaseRepositoryBase.instance.getUserId()}');
    String? uid = FirebaseRepositoryBase.instance.getUserId();
    if (uid != null) {
      await fetchAndSetUserModel(uid);
      return AuthResult.success();
    }
    return AuthResult.failure();
  }

  // BEGIN: Firebase Auth Methods.
  /// Method to handle user sign in using email and password
  @override
  Future<ValueResponse<void>> signInWithEmailAndPassword(
      String email, String password) async {
    DebugLogger.instance.printFunction('signInWithEmailAndPassword');
    final ValueResponse<String> response = await FirebaseRepositoryBase.instance
        .signInWithEmailAndPassword(email: email, password: password);

    if (response.isError) return ValueResponse.exception(response.error);

    final String uid = response.data;
    final ValueResponse<UserModel> result =
        await FirebaseRepositoryBase.instance.fetchUserModel(uid);
    if (result.isError) {
      // Initialize user model safety check for edge cases where
      // user model is not initialized on account registration.
      final UserModel firebaseUser = UserModel(
        email: email,
        id: uid,
      );
      UserModel? userModelHolder = await initUserModel(firebaseUser);
      if (userModelHolder == null) {
        return ValueResponse.error('Error: unable to create user.');
      }
      userModel.value = userModelHolder;
    } else {
      userModel.value = result.data;
    }

    return ValueResponse.success();
  }

  /// User registration using email and password
  @override
  Future<ValueResponse<void>> registerWithEmailAndPassword(
      String name, String email, String password) async {
    DebugLogger.instance.printFunction(
        'registerWithEmailAndPassword: $name, $email, $password');
    try {
      final ValueResponse<UserModel> response = await FirebaseRepositoryBase
          .instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (response.isError) {
        return response;
      }
      final UserModel firebaseUser = response.data;
      debugPrint('Firebase User: $firebaseUser');
      UserModel? userModelHolder = await initUserModel(firebaseUser);
      if (userModelHolder == null) {
        return ValueResponse.error('Error: unable to create user.');
      }
      userModel.value = userModelHolder;
      return ValueResponse.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.toString()}');
      return ValueResponse.exception(e.toException());
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.toString()}');
      return ValueResponse.exception(
          ExceptionWrapper(e.message ?? e.toString()));
    }
  }

  /// Password reset email
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    DebugLogger.instance.printFunction('sendPasswordResetEmail: $email');
    final ValueResponse<void> response = await FirebaseRepositoryBase.instance
        .sendPasswordResetEmail(email: email);
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
    }
  }

  /// Sign out user from Firebase Auth.
  @override
  Future<void> signOut() async {
    DebugLogger.instance.printFunction('signOut');

    // Get userID.
    String? userID = FirebaseRepositoryBase.instance.getUserId();
    if (userID != null) {
      // Mark user offline.
      // PresenceRepositoryBase.instance.markUserOffline(userID);
    }
    // UserModel should be reset by listener.
    final ValueResponse<void> response =
        await FirebaseRepositoryBase.instance.signOut();
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
    }

    /// Clear user data.
    resetUserModel();
  }

  /// Sign in with Google.
  @override
  Future<AuthResult> googleSignIn() async {
    DebugLogger.instance.printFunction('googleSignIn');

    try {
      UserModel? user;
      // Firebase Auth now manages auth internally with `signInWithPopup`.
      // Web auth no longer requires the `google_signin` plugin.
      if (kIsWeb) {
        final ValueResponse<UserModel> response =
            await FirebaseRepositoryBase.instance.signInWithGoogleWeb();
        if (response.isError) {
          return AuthResult.failure(response.error.message);
        }
        user = response.data;
      } else {
        if (Platform.isWindows) {
          // Default is a MissingPluginException error.
          return AuthResult.failure(
              'Sign in with Google is not yet supported on Windows');
        }
        GoogleSignInAccount? googleSignInAccount =
            await GoogleSignIn().signIn();
        if (googleSignInAccount == null) {
          return AuthResult.failure('Sign in canceled.');
        }
        GoogleSignInAuthentication googleAuth =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final ValueResponse<UserModel> response = await FirebaseRepositoryBase
            .instance
            .signInWithGoogleNative(credential: credential);

        if (response.isError) {
          return AuthResult.failure(response.error.message);
        }
        user = response.data;
      }
      // When auth returns a null user, an AuthException is thrown.
      // This failure return is just for a null check.
      if (user.id.isEmpty) return AuthResult.failure('Unable to sign in.');
      // Google auth does not differentiate between
      // login and signup. Check to see if user is already created.
      final ValueResponse<UserModel> response =
          await FirebaseRepositoryBase.instance.fetchUserModel(user.id);
      final UserModel model;
      if (response.isError) {
        // User is not created
        UserModel? userModel = await initUserModel(user);
        if (userModel == null) {
          return AuthResult.failure('Error: unable to create user.');
        }
        model = userModel;
      } else {
        model = response.data;
      }
      userModel.value = model;
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.toString()}');
      return AuthResult.failure(e.toString());
    } on Exception catch (e) {
      debugPrint('Exception: ${e.toString()}');
      return AuthResult.failure(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    DebugLogger.instance.printFunction('resetPassword: $email');

    final ValueResponse<void> response = await FirebaseRepositoryBase.instance
        .sendPasswordResetEmail(email: email);
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
    }
  }

  // END: Firebase Auth Methods.

  // BEGIN: Server Methods.

  /// Update username in Firebase. Re-fetch the UserModel again.
  @override
  Future<void> updateUsername(String newUsername) async {
    DebugLogger.instance.printFunction('updateUsername: $newUsername');

    if (userModel.value.id.isEmpty) return;

    final ValueResponse<void> response = await FirebaseRepositoryBase.instance
        .updateFirestoreUserModel(
            userModel.value.id, userModel.value.copyWith(name: newUsername));
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
      return;
    }
    await fetchAndSetUserModel(userModel.value.id);
  }

  // END: Server Methods.

  /// Fetches the [UserModel] with the user's [uid] from Firestore by calling
  /// [fetchUserModel], then updates the [userModel] field.
  @override
  Future<void> fetchAndSetUserModel(String uid) async {
    DebugLogger.instance.printFunction('fetchAndSetUserModel: $uid');

    final ValueResponse<UserModel> response =
        await FirebaseRepositoryBase.instance.fetchUserModel(uid);
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
      return;
    }
    userModel.value = response.data;
  }

  /// Creates a [UserModel] from Firebase User and
  /// saves to server.
  @override
  Future<UserModel?> initUserModel(UserModel user) async {
    DebugLogger.instance.printFunction('initUserModel: $user');

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
    final ValueResponse<void> response =
        await setFirestoreUserModel(user.id, newUser);
    if (response.isError) {
      return null;
    }
    return newUser;
  }

  @override
  Future<ValueResponse<void>> setFirestoreUserModel(
      String id, UserModel user) async {
    DebugLogger.instance.printFunction('setFirestoreUserModel: $id, $user');

    return await FirebaseRepositoryBase.instance
        .setDocument(collection: 'users', document: id, data: user.toJson());
  }

  @override
  void resetUserModel() {
    DebugLogger.instance.printFunction('resetUserModel');

    userModel.value = UserModel.empty();
    user.value = null;
  }

// END: User Model.

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
}

/* Not currently used functions for managing
google, apple and anonymous signin
https://github.com/fireship-io/flutter-firebase-quizapp-course
final GoogleSignIn _googleSignIn = GoogleSignIn();
// Determine if Apple Signin is available on device
  Future<bool> get appleSignInAvailable => AppleSignIn.isAvailable();
  /// Sign in with Apple
  Future<FirebaseUser> appleSignIn() async {
    try {
      final AuthorizationResult appleResult =
          await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);
      if (appleResult.error != null) {
        // handle errors from Apple
      }
      final AuthCredential credential =
          OAuthProvider(providerId: 'apple.com').getCredential(
        accessToken:
            String.fromCharCodes(appleResult.credential.authorizationCode),
        idToken: String.fromCharCodes(appleResult.credential.identityToken),
      );
      AuthResult firebaseResult = await _auth.signInWithCredential(credential);
      FirebaseUser user = firebaseResult.user;
      // Update user data
      updateUserData(user);
      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }
  /// Anonymous Firebase login
  Future<FirebaseUser> anonLogin() async {
    AuthResult result = await _auth.signInAnonymously();
    FirebaseUser user = result.user;
    updateUserData(user);
    return user;
  }
    /// Updates the User's data in Firestore on each new login
  Future<void> updateUserData(FirebaseUser user) {
    DocumentReference reportRef = _db.collection('reports').document(user.uid);
    return reportRef.setData({'uid': user.uid, 'lastActivity': DateTime.now()},
        merge: true);
  }

 */
