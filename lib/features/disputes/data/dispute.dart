import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../../../core/models/loan_status.dart';
import '../../../l10n/generated/app_localizations.dart';

/// SRS "Report transaction issues" / "Dispute handling" — a member-raised
/// issue about a transaction, contribution, or loan, reviewed by an admin.
enum DisputeStatus { open, resolved }

extension DisputeStatusUi on DisputeStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      DisputeStatus.open => l10n.disputeStatusOpen,
      DisputeStatus.resolved => l10n.disputeStatusResolved,
    };
  }

  StatusTone get tone => switch (this) {
    DisputeStatus.open => StatusTone.pending,
    DisputeStatus.resolved => StatusTone.positive,
  };
}

class Dispute {
  const Dispute({
    required this.id,
    required this.memberUid,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.memberName,
    this.adminResponse,
    this.resolvedAt,
  });

  final String id;
  final String memberUid;
  final String? memberName;
  final String subject;
  final String description;
  final DisputeStatus status;
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? resolvedAt;

  factory Dispute.fromFirestore(String id, Map<String, dynamic> data) {
    return Dispute(
      id: id,
      memberUid: data['memberUid'] as String? ?? '',
      memberName: data['memberName'] as String?,
      subject: data['subject'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: DisputeStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DisputeStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponse: data['adminResponse'] as String?,
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'memberUid': memberUid,
    'memberName': memberName,
    'subject': subject,
    'description': description,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'adminResponse': adminResponse,
    'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
  };
}
