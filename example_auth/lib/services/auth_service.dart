import 'dart:async';

import 'package:example_auth/services/user_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        UserManager.instance.fetchAndSetUserModel(user.uid);
        DebugLogger.instance.printFunction('onUserAuthenticated ${user.uid}');
        onUserAuthenticatedCallback?.call(user.uid);
      } else {
        DebugLogger.instance.printFunction('onUserUnauthenticated');
        UserManager.instance.resetUserModel();
        onUserUnauthenticatedCallback?.call();
      }
    });
  }

  @override
  void onDispose() {
    firebaseAuthListener.cancel();
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
      // await fetchAndSetUserModel(uid);
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
      await UserManager.instance.startUserStreamSubscription(uid);
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
      UserModel? userModelHolder =
          await UserManager.instance.initUserModel(firebaseUser);
      if (userModelHolder == null) {
        return ValueResponse.error('Error: unable to create user.');
      }
      await UserManager.instance
          .startUserStreamSubscription(userCredential.user?.uid ?? '');
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
    UserManager.instance.resetUserModel();
    UserManager.instance.onDispose();
  }

  /// Sign in with Google.
  Future<AuthResult> googleSignIn() async {
    DebugLogger.instance.printFunction('googleSignIn');

    try {
      UserCredential? userCredential;
      // Firebase Auth now manages auth internally with `signInWithPopup`.
      // Web auth no longer requires the `google_signin` plugin.
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
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
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (userCredential.user == null) {
        return AuthResult.failure('User credential missing.');
      }
      UserModel user = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        name: userCredential.user!.displayName ?? '',
        photoUrl: userCredential.user!.photoURL ?? '',
      );
      // When auth returns a null user, an AuthException is thrown.
      // This failure return is just for a null check.
      if (user.id.isEmpty) return AuthResult.failure('Unable to sign in.');
      // Google auth does not differentiate between
      // login and signup. Check to see if user is already created.
      final ValueResponse<UserModel> response =
          await UserManager.instance.fetchUserModel(user.id);
      if (response.isError) {
        // User is not created
        UserModel? userModel = await UserManager.instance.initUserModel(user);
        if (userModel == null) {
          return AuthResult.failure('Error: unable to create user.');
        }
      }
      await UserManager.instance.startUserStreamSubscription(user.id);
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
