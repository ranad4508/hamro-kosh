import 'package:cloud_firestore/cloud_firestore.dart';

import 'announcement.dart';
import 'notification_item.dart';

class NotificationsRepository {
  NotificationsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<NotificationItem>> watchNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationItem.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Announcement>> watchAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Announcement.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> markRead(String uid, String notificationId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
