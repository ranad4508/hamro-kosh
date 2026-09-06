import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_role.dart';
import 'app_user.dart';

/// Wraps Firebase Auth + the `users/{uid}` Firestore profile so the rest of
/// the app depends on this interface rather than the Firebase SDKs
/// directly (SOC: only this layer knows about `firebase_auth`/`cloud_firestore`).
class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.id, doc.data()!);
    });
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final profile = AppUser(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      role: UserRole.member,
      memberSince: DateTime.now(),
      // New registrations wait for admin approval per SRS §3.4/§35.
      isApproved: false,
      isActive: true,
    );

    await _firestore.collection('users').doc(uid).set(profile.toFirestore());
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? phone,
    String? photoUrl,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'phone': ?phone,
      'photoUrl': ?photoUrl,
    });
  }

  /// Re-authenticates with the current password before changing it, since
  /// Firebase Auth requires a "recent" sign-in for sensitive account
  /// changes — surfacing a clear "current password is wrong" error instead
  /// of Firebase's generic `requires-recent-login` failure.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    await _firestore.collection('users').doc(user.uid).update({
      'mustChangePassword': false,
    });
  }

  Future<void> signOut() => _auth.signOut();
}
