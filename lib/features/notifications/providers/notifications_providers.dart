import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/announcement.dart';
import '../data/notification_item.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(FirebaseFirestore.instance);
});

final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watchNotifications(uid);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsProvider)
      .value
      ?.where((n) => !n.isRead)
      .length ??
      0;
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchAnnouncements();
});
