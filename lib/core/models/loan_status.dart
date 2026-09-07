import 'package:flutter/material.dart';

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

  String get label => switch (this) {
    LoanStatus.requested => 'Requested',
    LoanStatus.underReview => 'Under review',
    LoanStatus.approved => 'Approved',
    LoanStatus.rejected => 'Rejected',
    LoanStatus.active => 'Active',
    LoanStatus.partiallyPaid => 'Partially paid',
    LoanStatus.overdue => 'Overdue',
    LoanStatus.completed => 'Completed',
    LoanStatus.cancelled => 'Cancelled',
    LoanStatus.defaulted => 'Defaulted',
  };

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

  String get label => switch (this) {
    ContributionStatus.pending => 'Pending',
    ContributionStatus.verified => 'Verified',
    ContributionStatus.rejected => 'Rejected',
  };

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
