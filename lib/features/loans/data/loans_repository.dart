import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/loan_category.dart';
import '../../../core/models/loan_status.dart';
import 'loan.dart';
import 'loan_repayment.dart';

/// Statuses that count against the fund-wide `maxConcurrentLoans` cap —
/// disbursed and not yet fully resolved (mirrors `Loan.countsTowardConcurrentCap`).
const _outstandingLoanStatuses = [
  'approved',
  'active',
  'partiallyPaid',
  'overdue',
];

class LoansRepository {
  LoansRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _loans =>
      _firestore.collection('loans');

  CollectionReference<Map<String, dynamic>> get _repayments =>
      _firestore.collection('loan_repayments');

  Stream<List<Loan>> watchMyLoans(String uid) {
    return _loans
        .where('memberId', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Loan.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<Loan?> watchLoan(String loanId) {
    return _loans
        .doc(loanId)
        .snapshots()
        .map(
          (doc) => doc.exists ? Loan.fromFirestore(doc.id, doc.data()!) : null,
        );
  }

  /// Admin-only: every loan across all members (SRS §37), optionally
  /// filtered by status for the requests/active/overdue/completed tabs.
  Stream<List<Loan>> watchAllLoans({LoanStatus? status}) {
    Query<Map<String, dynamic>> query = _loans.orderBy(
      'requestedAt',
      descending: true,
    );
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Loan.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  // Approving/rejecting a loan is intentionally NOT a method here: it goes
  // through the `approveLoan` Cloud Function
  // (`CloudFunctionsService.approveLoan`/`rejectLoan`) instead of a direct
  // Firestore write, since approval also has to record a ledger entry and
  // update the fund total — see functions/index.js.

  /// Creates a loan request in `requested` status under a fixed category
  /// (SRS §17-§19 — no admin-chosen rate; the category fixes the interest
  /// rate, fund-share cap, and repayment window at approval time).
  Future<void> requestLoan({
    required String uid,
    required String memberName,
    required double amount,
    required String purpose,
    required LoanCategory category,
  }) {
    return _loans.add({
      'memberId': uid,
      'borrowerName': memberName,
      'amount': amount,
      'purpose': purpose,
      'category': category.name,
      'status': 'requested',
      'requestedAt': Timestamp.now(),
      'amountPaid': 0,
    });
  }

  /// The number of loans currently outstanding fund-wide (approved and not
  /// yet fully resolved) — drives the "N of `maxConcurrentLoans` slots
  /// available" indicator on the request screen.
  Stream<int> watchOutstandingLoanCount() {
    return _loans
        .where('status', whereIn: _outstandingLoanStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Member ids with a currently-outstanding loan — one query for the whole
  /// community directory (SRS §31: "who has an outstanding loan" shown per
  /// row) rather than a separate listener per member row.
  Stream<Set<String>> watchOutstandingBorrowerIds() {
    return _loans
        .where('status', whereIn: _outstandingLoanStatuses)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['memberId'] as String)
              .toSet(),
        );
  }

  /// SRS §21 — submits a repayment claim in `pending` status. Mirrors
  /// `ContributionsRepository.submit`: verifying it (splitting into
  /// principal/interest/penalty, updating the loan and fund totals) is
  /// intentionally NOT a method here — it goes through the
  /// `verifyRepayment` Cloud Function instead, same reasoning as
  /// verifying a contribution.
  Future<void> submitRepayment({
    required String loanId,
    required String uid,
    required String borrowerName,
    required double amount,
    required String paymentMethod,
    String? proofUrl,
  }) {
    return _repayments.add({
      'loanId': loanId,
      'memberUid': uid,
      'borrowerName': borrowerName,
      'amount': amount,
      'date': Timestamp.now(),
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'proofUrl': proofUrl,
    });
  }

  /// A single loan's repayment history (SRS §21 "view repayment history"),
  /// most recent first.
  Stream<List<LoanRepayment>> watchRepaymentsForLoan(String loanId) {
    return _repayments
        .where('loanId', isEqualTo: loanId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LoanRepayment.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Admin-only: every repayment awaiting verification, across all loans.
  Stream<List<LoanRepayment>> watchPendingRepayments() {
    return _repayments
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LoanRepayment.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}
