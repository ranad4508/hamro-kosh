import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationCategory { financial, reminder, loan, announcement, system }

extension NotificationCategoryIcon on NotificationCategory {
  IconData get icon => switch (this) {
    NotificationCategory.financial => Icons.payments_outlined,
    NotificationCategory.reminder => Icons.alarm,
    NotificationCategory.loan => Icons.request_quote_outlined,
    NotificationCategory.announcement => Icons.campaign_outlined,
    NotificationCategory.system => Icons.info_outline,
  };
}

/// A single in-app notification-center entry (SRS §45).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;

  factory NotificationItem.fromFirestore(String id, Map<String, dynamic> data) {
    return NotificationItem(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => NotificationCategory.system,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
