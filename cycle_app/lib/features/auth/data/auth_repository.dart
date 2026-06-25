import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/auth/apple_auth_helper.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn? _injectedGoogleSignIn;
  GoogleSignIn? _googleSignInInstance;

  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _injectedGoogleSignIn = googleSignIn;

  GoogleSignIn? get _googleSignIn {
    if (_injectedGoogleSignIn != null) return _injectedGoogleSignIn;
    if (kIsWeb) return null;
    return _googleSignInInstance ??= GoogleSignIn();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signInWithGoogle() async {
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw Exception('Google Sign-In is not available on this platform.');
    }
    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in cancelled');
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signInWithApple() async {
    if (kIsWeb) {
      throw Exception('Apple Sign-In is not available on web.');
    }
    final rawNonce = AppleAuthHelper.generateNonce();
    final nonce = AppleAuthHelper.sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    await _auth.signInWithCredential(oauthCredential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn?.signOut();
  }

  /// Google Play requires in-app account deletion when accounts are created.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await user.delete();
  }
}
