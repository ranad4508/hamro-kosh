import 'package:cloud_firestore/cloud_firestore.dart';

import 'email_preferences.dart';

/// Reads/writes the `emailPreferences` map on `users/{uid}` (SRS §46).
/// Kept separate from [AppUser]/AuthRepository since this is a narrow,
/// self-only settings slice, the same pattern as PrivacyRepository for the
/// admin-configured `settings/privacy` doc.
class EmailPreferencesRepository {
  EmailPreferencesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<EmailPreferences> watch(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => EmailPreferences.fromFirestore(
        doc.data()?['emailPreferences'] as Map<String, dynamic>?,
      ),
    );
  }

  Future<void> update(String uid, EmailPreferences preferences) {
    return _firestore.collection('users').doc(uid).set({
      'emailPreferences': preferences.toFirestore(),
    }, SetOptions(merge: true));
  }
}
