import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../core/models/contribution_type.dart';
import '../../../core/models/loan_status.dart';
import '../../../core/utils/bs_date_formatter.dart';
import '../../../core/widgets/month_grid_heatmap.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/contribution.dart';
import '../data/contributions_repository.dart';

final contributionsRepositoryProvider = Provider<ContributionsRepository>((
  ref,
) {
  return ContributionsRepository(FirebaseFirestore.instance);
});

final myContributionsProvider = StreamProvider<List<Contribution>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(contributionsRepositoryProvider).watchMyContributions(uid);
});

/// Admin-only, optionally filtered by [ContributionStatus].
final allContributionsProvider =
    StreamProvider.family<List<Contribution>, ContributionStatus?>((
      ref,
      status,
    ) {
      return ref
          .watch(contributionsRepositoryProvider)
          .watchAllContributions(status: status);
    });

/// A specific member's verified-contributions total (SRS §7/§32:
/// member-to-member financial visibility) — computed from their own
/// `contributions` subcollection rather than a denormalized field, since
/// nothing writes one onto the user doc.
final memberVerifiedContributionsTotalProvider =
    StreamProvider.family<double, String>((ref, uid) {
      return ref
          .watch(contributionsRepositoryProvider)
          .watchMyContributions(uid)
          .map(
            (items) => items
                .where((c) => c.status == ContributionStatus.verified)
                .fold<double>(0, (total, c) => total + c.amount),
          );
    });

/// Which BS months a member's verified monthly contributions have covered,
/// derived from each contribution's `date` (start month) + `monthsCovered`
/// (a contiguous run) rather than a stored per-month ledger — this app
/// doesn't track individual covered months as separate documents, so a
/// catch-up/advance payment is reconstructed the same way
/// `Contribution.coveredMonthsLabel` already does for a single entry.
typedef MemberCoverage = ({
  /// (BS year, BS month) pairs covered by at least one verified payment.
  Set<(int, int)> coveredMonths,

  /// The latest covered month's name (e.g. "Poush"), or null if the member
  /// has no verified monthly contribution yet — Home's "You are covered
  /// to..." card (`design_spec.md` §1a).
  String? coveredToLabel,

  /// Distinct covered months ÷ months since joining, clamped to [0, 1] —
  /// the "your part in it" donut (`design_spec.md` turn 1c, reused here per
  /// product decision rather than as a full alternate home screen).
  double sharePaid,

  /// One cell per month of the *current* BS year (Baisakh first) for
  /// [MonthGridHeatmap].
  List<({String label, MonthCellState state})> currentYearCells,
});

final memberCoverageProvider =
    StreamProvider.family<
      MemberCoverage,
      ({String uid, DateTime? memberSince})
    >((ref, args) {
      return ref
          .watch(contributionsRepositoryProvider)
          .watchMyContributions(args.uid)
          .map((items) {
            final covered = <(int, int)>{};
            for (final c in items.where(
              (c) =>
                  c.status == ContributionStatus.verified &&
                  c.category == ContributionCategory.monthly,
            )) {
              final start = c.date.toNepaliDateTime();
              var year = start.year;
              var month = start.month;
              for (var i = 0; i < c.monthsCovered; i++) {
                covered.add((year, month));
                month++;
                if (month > 12) {
                  month = 1;
                  year++;
                }
              }
            }

            final now = NepaliDateTime.now();
            String? coveredToLabel;
            if (covered.isNotEmpty) {
              final latest = covered.reduce(
                (a, b) => (a.$1 > b.$1 || (a.$1 == b.$1 && a.$2 > b.$2))
                    ? a
                    : b,
              );
              coveredToLabel = BsDateFormatter.monthNames[latest.$2 - 1];
            }

            var sharePaid = 0.0;
            final memberSince = args.memberSince;
            if (memberSince != null) {
              final since = memberSince.toNepaliDateTime();
              final totalMonths =
                  (now.year - since.year) * 12 + (now.month - since.month) + 1;
              if (totalMonths > 0) {
                sharePaid = (covered.length / totalMonths).clamp(0, 1);
              }
            }

            final cells = List.generate(12, (i) {
              final monthNum = i + 1;
              final state = covered.contains((now.year, monthNum))
                  ? MonthCellState.covered
                  : monthNum <= now.month
                  ? MonthCellState.gap
                  : MonthCellState.future;
              return (
                label: BsDateFormatter.monthAbbreviations[i],
                state: state,
              );
            });

            return (
              coveredMonths: covered,
              coveredToLabel: coveredToLabel,
              sharePaid: sharePaid,
              currentYearCells: cells,
            );
          });
    });
