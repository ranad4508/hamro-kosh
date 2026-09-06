import 'package:cloud_firestore/cloud_firestore.dart';

/// Enables Firestore's on-device cache so members with patchy connectivity
/// (a real constraint for a community-fund app) can still open the app and
/// read the last-synced fund balance, contributions, and loan status.
void configureFirestoreOfflinePersistence() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
