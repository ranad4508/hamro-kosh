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

  /// Principal + interest owed as of the last time a Cloud Function wrote
  /// this loan (approval, or the most recent verified repayment). This is
  /// **not** kept fresh in between — nothing recalculates it while a loan
  /// sits overdue with no repayment activity — so `outstanding` below
  /// recomputes the current figure live rather than trusting this field
  /// directly; see `currentTotalPayable`.
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

  /// The true amount currently owed — principal + fixed on-time interest +
  /// any penalty accrued from being overdue, computed live from
  /// `disbursedAt` with `loanInterestOwedAt` (the same formula
  /// `verifyRepayment` uses) rather than read from `totalPayable`, which
  /// only gets refreshed on the next verified repayment. Before approval
  /// (no `disbursedAt`/`interestRatePercent`/`repaymentMonths` yet) this
  /// just falls back to the requested amount.
  double get currentTotalPayable {
    final rate = interestRatePercent;
    final dueMonths = repaymentMonths;
    final disbursed = disbursedAt;
    if (rate == null || dueMonths == null || disbursed == null) {
      return totalPayable ?? amount;
    }
    final elapsedMonths =
        DateTime.now().difference(disbursed).inMilliseconds /
        (1000 * 60 * 60 * 24 * 30);
    final totalInterestDue = amount * (rate / 100) * dueMonths;
    final owedNow = loanInterestOwedAt(
      principal: amount,
      monthlyRatePercent: rate,
      dueMonths: dueMonths,
      elapsedMonths: elapsedMonths,
    );
    final accruedPenalty = (owedNow - totalInterestDue).clamp(
      0,
      double.infinity,
    );
    return amount + totalInterestDue + accruedPenalty;
  }

  double get outstanding =>
      (currentTotalPayable - amountPaid).clamp(0, double.infinity);

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
