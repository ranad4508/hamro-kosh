import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/loan_status.dart';

/// SRS §21 — a repayment against a loan. Mirrors the contribution model's
/// submit-then-admin-verify shape (same `ContributionStatus`: pending until
/// an admin confirms it, since this is money a member *claims* to have
/// handed over): principal/interest/penalty components and the loan's
/// running balances are only computed and applied when it's verified — see
/// `verifyRepayment` in functions/index.js.
class LoanRepayment {
  const LoanRepayment({
    required this.id,
    required this.loanId,
    required this.memberUid,
    required this.amount,
    required this.date,
    required this.status,
    this.borrowerName,
    this.paymentMethod,
    this.reference,
    this.proofUrl,
    this.principalComponent,
    this.interestComponent,
    this.penaltyComponent,
  });

  final String id;
  final String loanId;
  final String memberUid;
  final double amount;
  final DateTime date;
  final ContributionStatus status;
  final String? borrowerName;
  final String? paymentMethod;
  final String? reference;
  final String? proofUrl;

  /// Only populated once verified — computed server-side, never trusted
  /// from the client (SRS §36).
  final double? principalComponent;
  final double? interestComponent;
  final double? penaltyComponent;

  factory LoanRepayment.fromFirestore(String id, Map<String, dynamic> data) {
    return LoanRepayment(
      id: id,
      loanId: data['loanId'] as String? ?? '',
      memberUid: data['memberUid'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ContributionStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ContributionStatus.pending,
      ),
      borrowerName: data['borrowerName'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      reference: data['reference'] as String?,
      proofUrl: data['proofUrl'] as String?,
      principalComponent: (data['principalComponent'] as num?)?.toDouble(),
      interestComponent: (data['interestComponent'] as num?)?.toDouble(),
      penaltyComponent: (data['penaltyComponent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'loanId': loanId,
    'memberUid': memberUid,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'status': status.name,
    'borrowerName': borrowerName,
    'paymentMethod': paymentMethod,
    'reference': reference,
    'proofUrl': proofUrl,
  };
}
