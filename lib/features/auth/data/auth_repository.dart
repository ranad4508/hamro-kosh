import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/cloud_functions_service.dart';
import 'app_user.dart';

/// Maps a [FirebaseAuthException] code to a specific, bilingual-ready
/// message — the old screens collapsed every failure into one generic
/// string ("Could not sign in"), which meant a wrong password and a
/// disabled account looked identical to the user. Each entry here is the
/// English half of the message; screens pair it with a Nepali translation
/// via [BilingualText].
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  factory AuthFailure.fromFirebase(FirebaseAuthException e) {
    return AuthFailure(switch (e.code) {
      'user-not-found' || 'invalid-credential' =>
        'No account matches that email and password.',
      'wrong-password' => 'That password is incorrect.',
      'user-disabled' => 'This account has been disabled. Contact an admin.',
      'too-many-requests' =>
        'Too many attempts. Wait a moment and try again.',
      'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      'email-already-in-use' => 'An account already exists with that email.',
      'weak-password' => 'Choose a stronger password (at least 8 characters).',
      'invalid-email' => 'That email address looks invalid.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    });
  }

  @override
  String toString() => message;
}

/// Firebase Auth + the signed-in user's own Firestore profile. Registration
/// itself is intentionally NOT a method here — it goes through
/// `CloudFunctionsService.registerMember` (see `functions/index.js`'s
/// `registerMember`), since it needs to create the Auth user + Firestore
/// profile as one guarded server-side sequence with rollback on failure.
/// This repository only ever touches the *already-authenticated* user.
class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._cloudFunctions);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CloudFunctionsService _cloudFunctions;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? AppUser.fromFirestore(uid, doc.data()!) : null,
    );
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    }
  }

  /// Self-registration — no invite code, no approval step. Delegates to
  /// `registerMember`, which creates the Auth user + Firestore profile
  /// atomically server-side, then signs the new member in immediately
  /// rather than sending them back to the login screen to re-enter the
  /// password they just typed.
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      await _cloudFunctions.registerMember(
        fullName: fullName,
        email: email.trim(),
        phone: phone,
        password: password,
      );
    } on CloudFunctionsApiException catch (e) {
      throw AuthFailure(e.message);
    }
    await signIn(email, password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    }
  }

  Future<void> updateProfile(
    String uid, {
    String? fullName,
    String? phone,
    String? photoUrl,
  }) {
    return _firestore.collection('users').doc(uid).update({
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  /// Re-authenticates with the current password before changing it (Firebase
  /// requires a recent sign-in for sensitive account changes), then clears
  /// `mustChangePassword` so the forced-change screen doesn't show again.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthFailure('You need to be signed in to do this.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await _firestore.collection('users').doc(user.uid).update({
        'mustChangePassword': false,
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
