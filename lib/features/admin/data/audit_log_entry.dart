import 'package:cloud_firestore/cloud_firestore.dart';

/// SRS §40 — a single audit-trail entry recording an administrative action.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.previousValue,
    this.newValue,
  });

  final String id;
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String? previousValue;
  final String? newValue;

  factory AuditLogEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return AuditLogEntry(
      id: id,
      action: data['action'] as String? ?? '',
      performedBy: data['performedBy'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousValue: data['previousValue'] as String?,
      newValue: data['newValue'] as String?,
    );
  }
}
