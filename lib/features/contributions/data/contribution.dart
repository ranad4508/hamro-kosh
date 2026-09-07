import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/contribution_type.dart';
import '../../../core/models/loan_status.dart';
import '../../../core/utils/date_formatter.dart';

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
    this.monthsCovered = 1,
    this.proofUrl,
    this.campaignId,
    this.receivingAdminId,
    this.receivingAdminName,
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

  /// How many months this single payment covers — a member catching up on
  /// several months (or paying ahead) records it as one entry rather than
  /// one per month (matches the reference design's multi-month receipt).
  /// Always 1 for a special contribution.
  final int monthsCovered;

  /// Cloudinary URL for an attached payment-proof photo. Optional — cash
  /// handed directly to an admin doesn't need one (still pending until
  /// that admin verifies it either way).
  final String? proofUrl;

  /// SRS §15 — set when this contribution was made toward a named admin
  /// campaign (e.g. "Dashain Contribution 2083") rather than an ad-hoc
  /// special contribution.
  final String? campaignId;

  /// Set only when [paymentMethod] is "Cash to admin" — the admin's own
  /// identity is the proof (`design_spec.md` §5b), so no [proofUrl] or
  /// [reference] is required in that case; that admin later confirms
  /// they received and banked the cash.
  final String? receivingAdminId;
  final String? receivingAdminName;

  /// e.g. "Covers Jan – May 2026" for a 5-month catch-up payment, or just
  /// the month itself when `monthsCovered == 1`.
  String get coveredMonthsLabel {
    if (monthsCovered <= 1) return DateFormatter.monthYear(date);
    final lastMonth = DateTime(date.year, date.month + monthsCovered - 1);
    return 'Covers ${DateFormatter.monthYear(date)} – ${DateFormatter.monthYear(lastMonth)}';
  }

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
      monthsCovered: (data['monthsCovered'] as num?)?.toInt() ?? 1,
      proofUrl: data['proofUrl'] as String?,
      campaignId: data['campaignId'] as String?,
      receivingAdminId: data['receivingAdminId'] as String?,
      receivingAdminName: data['receivingAdminName'] as String?,
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
    'monthsCovered': monthsCovered,
    'proofUrl': proofUrl,
    'campaignId': campaignId,
    'receivingAdminId': receivingAdminId,
    'receivingAdminName': receivingAdminName,
  };
}
