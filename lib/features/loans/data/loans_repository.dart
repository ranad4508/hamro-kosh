import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/loan_status.dart';
import 'loan.dart';

class LoansRepository {
  LoansRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _loans =>
      _firestore.collection('loans');

  Stream<List<Loan>> watchMyLoans(String uid) {
    return _loans
        .where('memberId', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Loan.fromFirestore(doc.id, doc.data())).toList());
  }

  Stream<Loan?> watchLoan(String loanId) {
    return _loans.doc(loanId).snapshots().map(
          (doc) => doc.exists ? Loan.fromFirestore(doc.id, doc.data()!) : null,
        );
  }

  /// Admin-only: every loan across all members (SRS §37), optionally
  /// filtered by status for the requests/active/overdue/completed tabs.
  Stream<List<Loan>> watchAllLoans({LoanStatus? status}) {
    Query<Map<String, dynamic>> query =
        _loans.orderBy('requestedAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Loan.fromFirestore(doc.id, doc.data())).toList());
  }

  /// SRS §17 — admin approval sets interest/repayment terms; rejection just
  /// updates status. Disbursement/ledger-entry creation is left as a TODO
  /// for the Cloud Function that should own that transactional write.
  Future<void> approve({
    required String loanId,
    required double interestRatePercent,
    required int repaymentMonths,
    required double totalPayable,
  }) {
    return _loans.doc(loanId).update({
      'status': LoanStatus.approved.name,
      'interestRatePercent': interestRatePercent,
      'repaymentMonths': repaymentMonths,
      'totalPayable': totalPayable,
    });
  }

  Future<void> reject(String loanId) {
    return _loans.doc(loanId).update({'status': LoanStatus.rejected.name});
  }

  /// Creates a loan request in `requested` status; admin approval (SRS §17)
  /// is a write performed from the admin feature, not here.
  Future<void> requestLoan({
    required String uid,
    required String memberName,
    required double amount,
    required String purpose,
    required int preferredMonths,
  }) {
    return _loans.add({
      'memberId': uid,
      'borrowerName': memberName,
      'amount': amount,
      'purpose': purpose,
      'repaymentMonths': preferredMonths,
      'status': 'requested',
      'requestedAt': Timestamp.now(),
      'amountPaid': 0,
    });
  }
}
