import 'package:example_auth/services/auth_service.dart';
import 'package:example_auth/services/debug_logger.dart';
import 'package:example_auth/services/user_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool signingOut = false;

class SignoutHelper {
  static const String name = 'SignoutHelper';

  /// Sign out user from Firebase Auth.
  static Future<void> signOut() async {
    DebugLogger.instance.printFunction('signOut', name: name);

    // FirebaseAuth will throw unauthenticated and call signout on start.
    if (AuthService.instance.firebaseAuthInitialized == false) return;
    // User is already signed out or being signed out.
    if (signingOut) return;
    signingOut = true;

    /// Clear user data.
    await UserManager.instance.resetUserModel();
    await UserManager.instance.dispose();

    // Signout Auth.
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint(e.toString());
    }

    signingOut = false;
  }
}
