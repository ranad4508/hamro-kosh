import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService(FirebaseFunctions.instance);
});

/// Thrown for any Cloud Functions call failure, carrying the function's own
/// error message so callers can show something more useful than a raw
/// platform exception.
class CloudFunctionsApiException implements Exception {
  CloudFunctionsApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Client for the privileged Cloud Functions callables — the few operations
/// that can't safely happen directly from this app: creating a Firebase Auth
/// user for someone else, and the ledger-entry-plus-audit-log side effects of
/// verifying a contribution or approving a loan. Everything else (reads,
/// self-registration, submitting a contribution/loan request) still goes
/// straight to Firestore/Auth, governed by `firestore.rules`.
class CloudFunctionsService {
  CloudFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw CloudFunctionsApiException(
        e.message ?? 'Request failed (${e.code}).',
      );
    }
  }

  /// SRS §3.1 — self-registration: no invite code, no approval step. Runs
  /// the Auth-user creation and Firestore profile write as one guarded
  /// server-side sequence (see `registerMember` in functions/index.js)
  /// rather than the old client-side `createUserWithEmailAndPassword` +
  /// separate Firestore write + forced sign-out dance, which could leave an
  /// orphaned Auth user if the second write failed.
  Future<String> registerMember({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _call('registerMember', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return data['uid'] as String;
  }

  /// SRS §35 / SRS.md §58 RBAC — provisions a member or admin account and
  /// emails the new user their temporary password.
  Future<String> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    final data = await _call('createUserAccount', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
    });
    return data['uid'] as String;
  }

  /// SRS §7-§9, §38 — verifying a contribution also records the ledger
  /// entry and updates the fund total; see `functions/index.js`.
  Future<void> verifyContribution({
    required String memberUid,
    required String contributionId,
    required bool approve,
  }) {
    return _call('verifyContribution', {
      'memberUid': memberUid,
      'contributionId': contributionId,
      'status': approve ? 'verified' : 'rejected',
    });
  }

  /// SRS §17-§19 — approving a loan disburses it: records the ledger entry
  /// and updates the fund total. The interest rate is never sent from the
  /// client — it's fixed by the loan's own category and computed
  /// server-side; `repaymentMonths` only matters for an emergency loan,
  /// where the admin picks 1 or 2 quarters (a personal loan always repays
  /// within 1 quarter regardless of what's passed here). See
  /// `functions/index.js`.
  Future<void> approveLoan({required String loanId, int? repaymentMonths}) {
    return _call('approveLoan', {
      'loanId': loanId,
      'action': 'approve',
      if (repaymentMonths != null) 'repaymentMonths': repaymentMonths,
    });
  }

  Future<void> rejectLoan(String loanId) {
    return _call('approveLoan', {'loanId': loanId, 'action': 'reject'});
  }

  /// SRS §21 — verifying a repayment splits it into principal/interest/
  /// penalty, updates the loan's running balances and status, and records
  /// the ledger entries (a `loanRepayment` + `interestPayment` pair). All
  /// of that math happens server-side — never trust a client-computed
  /// split for money that's actually moving.
  Future<void> verifyRepayment({
    required String repaymentId,
    required bool approve,
  }) {
    return _call('verifyRepayment', {
      'repaymentId': repaymentId,
      'status': approve ? 'verified' : 'rejected',
    });
  }

  /// SRS §17 — records a community expense: the ledger entry and the fund
  /// total have to move together, so this goes through a function rather
  /// than a direct client write, same as every other money-moving action.
  Future<void> recordExpense({
    required double amount,
    required String category,
    required String description,
    String? recipient,
    String? paymentMethod,
    String? proofUrl,
  }) {
    return _call('recordExpense', {
      'amount': amount,
      'category': category,
      'description': description,
      'recipient': recipient,
      'paymentMethod': paymentMethod,
      'proofUrl': proofUrl,
    });
  }

  /// `design_spec.md` §5e — records a contribution with no member-submitted
  /// proof (cash handed directly to an admin, or an older cash-book entry).
  /// Writes straight in as verified; the required [note] is what stands in
  /// for a screenshot in the audit trail.
  Future<String> recordContributionManually({
    required String memberUid,
    required double amount,
    required int monthsCovered,
    required DateTime date,
    required String note,
    required String category,
  }) async {
    final data = await _call('recordContributionManually', {
      'memberUid': memberUid,
      'amount': amount,
      'monthsCovered': monthsCovered,
      'date': date.toIso8601String(),
      'note': note,
      'category': category,
    });
    return data['id'] as String;
  }

  /// SRS §44 — corrects a mistaken transaction amount without editing or
  /// deleting the original: appends a linked `adjustment` entry instead.
  /// `amount` is signed — positive credits the fund balance back, negative
  /// debits it further — and the fund total moves by exactly that delta.
  Future<void> correctTransaction({
    required String originalTransactionId,
    required double amount,
    required String reason,
  }) {
    return _call('correctTransaction', {
      'originalTransactionId': originalTransactionId,
      'amount': amount,
      'reason': reason,
    });
  }
}
