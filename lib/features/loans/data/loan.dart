import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/loan_status.dart';

/// SRS §15-§25 — a member's loan request/agreement/active loan record.
class Loan {
  const Loan({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.status,
    required this.requestedAt,
    this.interestRatePercent,
    this.repaymentMonths,
    this.totalPayable,
    this.amountPaid = 0,
    this.nextDueDate,
    this.borrowerName,
  });

  final String id;
  final double amount;
  final String purpose;
  final LoanStatus status;
  final DateTime requestedAt;
  final double? interestRatePercent;
  final int? repaymentMonths;
  final double? totalPayable;
  final double amountPaid;
  final DateTime? nextDueDate;
  final String? borrowerName;

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
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      interestRatePercent: (data['interestRatePercent'] as num?)?.toDouble(),
      repaymentMonths: data['repaymentMonths'] as int?,
      totalPayable: (data['totalPayable'] as num?)?.toDouble(),
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
      borrowerName: data['borrowerName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'amount': amount,
        'purpose': purpose,
        'status': status.name,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'interestRatePercent': interestRatePercent,
        'repaymentMonths': repaymentMonths,
        'totalPayable': totalPayable,
        'amountPaid': amountPaid,
        'nextDueDate': nextDueDate == null ? null : Timestamp.fromDate(nextDueDate!),
        'borrowerName': borrowerName,
      };
}
