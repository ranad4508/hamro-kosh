import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// SRS §24 — loan lifecycle states.
enum LoanStatus {
  requested,
  underReview,
  approved,
  rejected,
  active,
  partiallyPaid,
  overdue,
  completed,
  cancelled,
  defaulted;

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      LoanStatus.requested => l10n.loanStatusRequested,
      LoanStatus.underReview => l10n.loanStatusUnderReview,
      LoanStatus.approved => l10n.loanStatusApproved,
      LoanStatus.rejected => l10n.loanStatusRejected,
      LoanStatus.active => l10n.loanStatusActive,
      LoanStatus.partiallyPaid => l10n.loanStatusPartiallyPaid,
      LoanStatus.overdue => l10n.loanStatusOverdue,
      LoanStatus.completed => l10n.loanStatusCompleted,
      LoanStatus.cancelled => l10n.loanStatusCancelled,
      LoanStatus.defaulted => l10n.loanStatusDefaulted,
    };
  }

  /// Maps each status to a semantic tone consumed by `StatusBadge`.
  StatusTone get tone => switch (this) {
    LoanStatus.requested || LoanStatus.underReview => StatusTone.pending,
    LoanStatus.approved ||
    LoanStatus.active ||
    LoanStatus.completed => StatusTone.positive,
    LoanStatus.partiallyPaid => StatusTone.info,
    LoanStatus.overdue ||
    LoanStatus.rejected ||
    LoanStatus.defaulted => StatusTone.negative,
    LoanStatus.cancelled => StatusTone.neutral,
  };
}

/// SRS §7/§9 — a member's contribution can be pending verification,
/// verified, or rejected by an admin.
enum ContributionStatus {
  pending,
  verified,
  rejected;

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ContributionStatus.pending => l10n.contributionStatusPending,
      ContributionStatus.verified => l10n.contributionStatusVerified,
      ContributionStatus.rejected => l10n.contributionStatusRejected,
    };
  }

  StatusTone get tone => switch (this) {
    ContributionStatus.pending => StatusTone.pending,
    ContributionStatus.verified => StatusTone.positive,
    ContributionStatus.rejected => StatusTone.negative,
  };
}

/// Neutral color intent for [StatusBadge], resolved against [FinanceColors]
/// and the ambient [ColorScheme] rather than fixed colors.
enum StatusTone { positive, negative, pending, info, neutral }

extension StatusToneIcon on StatusTone {
  IconData get icon => switch (this) {
    StatusTone.positive => Icons.check_circle,
    StatusTone.negative => Icons.error,
    StatusTone.pending => Icons.hourglass_top,
    StatusTone.info => Icons.info,
    StatusTone.neutral => Icons.remove_circle_outline,
  };
}
