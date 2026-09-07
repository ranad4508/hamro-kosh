import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/loan_category.dart';
import '../../../core/models/loan_status.dart';

/// SRS §15-§25 — a member's loan request/agreement/active loan record.
class Loan {
  const Loan({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.status,
    required this.requestedAt,
    required this.category,
    this.interestRatePercent,
    this.repaymentMonths,
    this.totalPayable,
    this.amountPaid = 0,
    this.principalPaid = 0,
    this.interestPaid = 0,
    this.penaltyPaid = 0,
    this.disbursedAt,
    this.nextDueDate,
    this.borrowerName,
    this.memberId,
  });

  final String id;
  final double amount;
  final String purpose;
  final LoanStatus status;
  final DateTime requestedAt;
  final LoanCategory category;

  /// The borrower's uid — used to look up their member profile (join date,
  /// prior loans) for the admin review screen.
  final String? memberId;
  final double? interestRatePercent;
  final int? repaymentMonths;

  /// Principal + interest owed, **plus any penalty accrued so far** — this
  /// grows over the loan's life if it goes overdue (SRS §21), so
  /// `outstanding` below always stays accurate without the UI needing to
  /// separately track penalty.
  final double? totalPayable;

  /// Cumulative amount repaid — `principalPaid + interestPaid + penaltyPaid`.
  final double amountPaid;
  final double principalPaid;
  final double interestPaid;
  final double penaltyPaid;

  /// When the loan was actually disbursed (set at approval) — needed to
  /// compute how overdue it is for repayment/penalty calculations.
  final DateTime? disbursedAt;
  final DateTime? nextDueDate;
  final String? borrowerName;

  /// Whether this loan counts against the fund-wide `maxConcurrentLoans`
  /// cap — disbursed and not yet fully resolved.
  bool get countsTowardConcurrentCap => switch (status) {
    LoanStatus.approved ||
    LoanStatus.active ||
    LoanStatus.partiallyPaid ||
    LoanStatus.overdue => true,
    _ => false,
  };

  double get outstanding => (totalPayable ?? amount) - amountPaid;

  factory Loan.fromFirestore(String id, Map<String, dynamic> data) {
    return Loan(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      purpose: data['purpose'] as String? ?? '',
      status: LoanStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => LoanStatus.requested,
      ),
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: LoanCategory.fromName(data['category'] as String?),
      interestRatePercent: (data['interestRatePercent'] as num?)?.toDouble(),
      repaymentMonths: data['repaymentMonths'] as int?,
      totalPayable: (data['totalPayable'] as num?)?.toDouble(),
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
      principalPaid: (data['principalPaid'] as num?)?.toDouble() ?? 0,
      interestPaid: (data['interestPaid'] as num?)?.toDouble() ?? 0,
      penaltyPaid: (data['penaltyPaid'] as num?)?.toDouble() ?? 0,
      disbursedAt: (data['disbursedAt'] as Timestamp?)?.toDate(),
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
      borrowerName: data['borrowerName'] as String?,
      memberId: data['memberId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'amount': amount,
    'purpose': purpose,
    'status': status.name,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'category': category.name,
    'interestRatePercent': interestRatePercent,
    'repaymentMonths': repaymentMonths,
    'totalPayable': totalPayable,
    'amountPaid': amountPaid,
    'principalPaid': principalPaid,
    'interestPaid': interestPaid,
    'penaltyPaid': penaltyPaid,
    'disbursedAt': disbursedAt == null
        ? null
        : Timestamp.fromDate(disbursedAt!),
    'nextDueDate': nextDueDate == null
        ? null
        : Timestamp.fromDate(nextDueDate!),
    'borrowerName': borrowerName,
  };
}
