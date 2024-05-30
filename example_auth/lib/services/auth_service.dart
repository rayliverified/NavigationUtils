import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:simple_gravatar/simple_gravatar.dart';
import 'package:universal_io/io.dart';

import '../models/model_user.dart';
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

class AuthService implements Disposable {
  static AuthService? _instance;

  static AuthService get instance {
    if (_instance == null) {
      DebugLogger.instance.printFunction('AuthService Initialized');
      // An instance persists the AuthService.
      _instance ??= AuthService._();
      return _instance!;
    }
    return _instance!;
  }

  AuthService initialize() {
    return this;
  }

  ValueNotifier<UserModel> userModel = ValueNotifier(UserModel.initial());
  ValueNotifier<User?> user = ValueNotifier(null);
  late Stream<User?> firebaseAuthUserStream;
  late StreamSubscription firebaseAuthListener;

  bool get isAuthenticated => user.value != null;

  Function(String uid)? onUserAuthenticatedCallback;
  Function? onUserUnauthenticatedCallback;

  AuthService._() {
    firebaseAuthUserStream =
        FirebaseAuth.instance.authStateChanges().asBroadcastStream();
    firebaseAuthListener = FirebaseAuth.instance
        .authStateChanges()
        .asBroadcastStream()
        .listen((user) {
      DebugLogger.instance.printFunction('authStateChanges: $user');
      this.user.value = user;
      if (user != null) {
        fetchAndSetUserModel(user.uid);
        if (userModel.value.id.isEmpty) {
          DebugLogger.instance.printFunction('onUserAuthenticated ${user.uid}');
          onUserAuthenticatedCallback?.call(user.uid);
        }
      } else {
        DebugLogger.instance.printFunction('onUserUnauthenticated');
        resetUserModel();

        onUserUnauthenticatedCallback?.call();
      }
    });
  }

  @override
  void onDispose() {
    firebaseAuthListener.cancel();
    userModel.dispose();
    _instance = AuthService._();
  }

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
  Future<AuthResult> initAuthState() async {
    DebugLogger.instance.printFunction('initAuthState');
    DebugLogger.instance
        .printInfo('Current User: ${FirebaseAuth.instance.currentUser?.uid}');
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await fetchAndSetUserModel(uid);
      return AuthResult.success();
    }
    return AuthResult.failure();
  }

  // BEGIN: Firebase Auth Methods.
  /// Method to handle user sign in using email and password
  Future<ValueResponse<void>> signInWithEmailAndPassword(
      String email, String password) async {
    DebugLogger.instance.printFunction('signInWithEmailAndPassword');
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user == null) {
        return ValueResponse.error('User not found');
      }

      final String uid = credential.user!.uid;
      final ValueResponse<UserModel> result = await fetchUserModel(uid);
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
    } on FirebaseAuthException catch (e) {
      return ValueResponse.exception(e.toException());
    }

    return ValueResponse.success();
  }

  /// User registration using email and password
  Future<ValueResponse<void>> registerWithEmailAndPassword(
      String name, String email, String password) async {
    DebugLogger.instance.printFunction(
        'registerWithEmailAndPassword: $name, $email, $password');
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final UserModel firebaseUser = UserModel(
        email: userCredential.user?.email ?? email,
        id: userCredential.user?.uid ?? '',
        photoUrl: userCredential.user?.photoURL ?? '',
        name: userCredential.user?.displayName ?? '',
      );
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
  Future<ValueResponse<void>> sendPasswordResetEmail(String email) async {
    DebugLogger.instance.printFunction('sendPasswordResetEmail: $email');
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      return ValueResponse.exception(e.toException());
    }

    return ValueResponse.success();
  }

  /// Sign out user from Firebase Auth.
  Future<void> signOut() async {
    DebugLogger.instance.printFunction('signOut');
    await FirebaseAuth.instance.signOut();

    /// Clear user data.
    resetUserModel();
  }

  /// Sign in with Google.
  Future<AuthResult> googleSignIn() async {
    DebugLogger.instance.printFunction('googleSignIn');

    try {
      UserModel? user;
      // Firebase Auth now manages auth internally with `signInWithPopup`.
      // Web auth no longer requires the `google_signin` plugin.
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);

        user = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user?.email ?? '',
          name: userCredential.user?.displayName ?? '',
          photoUrl: userCredential.user?.photoURL ?? '',
        );
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
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        user = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user?.email ?? '',
          name: userCredential.user?.displayName ?? '',
          photoUrl: userCredential.user?.photoURL ?? '',
        );
      }
      // When auth returns a null user, an AuthException is thrown.
      // This failure return is just for a null check.
      if (user.id.isEmpty) return AuthResult.failure('Unable to sign in.');
      // Google auth does not differentiate between
      // login and signup. Check to see if user is already created.
      final ValueResponse<UserModel> response = await fetchUserModel(user.id);
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
  // END: Firebase Auth Methods.

  // BEGIN: Server Methods.

  /// Update username in Firebase. Re-fetch the UserModel again.
  Future<void> updateUsername(String newUsername) async {
    DebugLogger.instance.printFunction('updateUsername: $newUsername');

    if (userModel.value.id.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userModel.value.id)
        .update(userModel.value.copyWith(name: newUsername).toJson());
    await fetchAndSetUserModel(userModel.value.id);
  }

  // END: Server Methods.

  /// Fetches the [UserModel] with the user's [uid] from Firestore by calling
  /// [fetchUserModel], then updates the [userModel] field.
  Future<void> fetchAndSetUserModel(String uid) async {
    DebugLogger.instance.printFunction('fetchAndSetUserModel: $uid');

    final ValueResponse<UserModel> response = await fetchUserModel(uid);
    if (response.isError) {
      // TODO [ERROR_HANDLING]: handle error.
      return;
    }
    userModel.value = response.data;
  }

  /// Creates a [UserModel] from Firebase User and
  /// saves to server.
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

  Future<ValueResponse<UserModel>> fetchUserModel(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.doc('users/$uid').get();
    if (!snapshot.exists) {
      return ValueResponse.error('User does not exist!');
    }
    if (snapshot.data() == null) {
      return ValueResponse.error('User data is empty!');
    }
    return ValueResponse.success(UserModel.fromJson(snapshot.data()!));
  }

  Future<ValueResponse<void>> setFirestoreUserModel(
      String id, UserModel user) async {
    DebugLogger.instance.printFunction('setFirestoreUserModel: $id, $user');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .set(user.toJson());
    return ValueResponse.success();
  }

  void resetUserModel() {
    DebugLogger.instance.printFunction('resetUserModel');

    userModel.value = UserModel.empty();
    user.value = null;
  }
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
