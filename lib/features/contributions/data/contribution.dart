import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/contribution_type.dart';
import '../../../core/models/loan_status.dart';

/// A member's contribution record (SRS §7-§9).
class Contribution {
  const Contribution({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.status,
    this.occasionName,
    this.paymentMethod,
    this.reference,
    this.memberUid,
    this.memberName,
  });

  final String id;
  final ContributionCategory category;
  final double amount;
  final DateTime date;
  final ContributionStatus status;
  final String? occasionName;
  final String? paymentMethod;
  final String? reference;

  /// Populated for admin-facing (collection-group) reads so a pending
  /// contribution can be traced back to its owning member.
  final String? memberUid;
  final String? memberName;

  factory Contribution.fromFirestore(String id, Map<String, dynamic> data) {
    return Contribution(
      id: id,
      category: ContributionCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => ContributionCategory.monthly,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ContributionStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ContributionStatus.pending,
      ),
      occasionName: data['occasionName'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      reference: data['reference'] as String?,
      memberUid: data['memberUid'] as String?,
      memberName: data['memberName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'category': category.name,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'status': status.name,
        'occasionName': occasionName,
        'paymentMethod': paymentMethod,
        'reference': reference,
        'memberUid': memberUid,
        'memberName': memberName,
      };
}
