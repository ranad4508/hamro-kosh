import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/announcement.dart';
import '../data/notification_item.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
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

/// SRS §45 — "mark all as read" in one write per unread item; Firestore has
/// no server-side bulk update, so this fans out individual `markRead` calls.
final markAllNotificationsReadProvider =
    Provider<Future<void> Function(String uid)>((ref) {
      return (uid) async {
        final unread =
            ref.read(notificationsProvider).value?.where((n) => !n.isRead) ??
            const [];
        final repo = ref.read(notificationsRepositoryProvider);
        await Future.wait(unread.map((n) => repo.markRead(uid, n.id)));
      };
    });

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchAnnouncements();
});
