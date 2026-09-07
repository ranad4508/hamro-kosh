import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/email_preferences.dart';
import '../data/email_preferences_repository.dart';

final emailPreferencesRepositoryProvider = Provider<EmailPreferencesRepository>((
  ref,
) {
  return EmailPreferencesRepository(FirebaseFirestore.instance);
});

final emailPreferencesProvider = StreamProvider<EmailPreferences>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(EmailPreferences.defaults);
  return ref.watch(emailPreferencesRepositoryProvider).watch(uid);
});
