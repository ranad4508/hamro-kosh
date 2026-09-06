import 'package:cloud_firestore/cloud_firestore.dart';

/// A community-wide announcement (SRS §33), published by an admin and
/// broadcast via in-app notification, push, and/or email.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;

  factory Announcement.fromFirestore(String id, Map<String, dynamic> data) {
    return Announcement(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
