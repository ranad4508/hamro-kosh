/// Placeholder Terms & Conditions copy structured per SRS §48. Replace with
/// the community's actual reviewed/legal terms before launch — this exists
/// so the acceptance flow (SRS §3.4, §48) and the read-only viewer
/// (Profile → Terms & Conditions) have real, section-by-section content to
/// render rather than lorem ipsum.
class TermsSection {
  const TermsSection(this.title, this.body);
  final String title;
  final String body;
}

const List<TermsSection> termsSections = [
  TermsSection(
    'Membership',
    'Membership is granted at admin discretion after registration review. '
        'Members must keep their contact details accurate and notify an '
        'admin of any change in circumstances affecting participation.',
  ),
  TermsSection(
    'Contributions',
    'Members agree to make the configured monthly contribution on time. '
        'Special/occasion contributions are voluntary unless marked '
        'mandatory for a specific campaign.',
  ),
  TermsSection(
    'Fund usage',
    'The community fund is used only for approved purposes: member loans, '
        'community occasions, emergency support, and administrative costs '
        'explicitly recorded in the transparency ledger.',
  ),
  TermsSection(
    'Borrowing',
    'Loan eligibility, maximum amount, and required documentation are set '
        'by the admin-configured fund rules and may change over time.',
  ),
  TermsSection(
    'Interest',
    'Interest is calculated using the method (flat, reducing balance, '
        'fixed) and rate configured for each loan at approval time, and is '
        'disclosed to the borrower before acceptance.',
  ),
  TermsSection(
    'Repayment',
    'Repayments follow the agreed schedule and frequency. Partial payments '
        'are applied to interest before principal unless otherwise stated.',
  ),
  TermsSection(
    'Late payments & penalties',
    'A grace period and late-payment penalty may apply as configured by '
        'the admin; both are shown on the loan terms before disbursement.',
  ),
  TermsSection(
    'Loan default',
    'A loan marked defaulted may result in restricted future borrowing '
        'eligibility and escalation to the community\'s dispute process.',
  ),
  TermsSection(
    'Dispute handling',
    'Members may raise a dispute for any transaction, contribution, or '
        'loan balance they believe is incorrect; admins investigate and '
        'respond with a resolution or explanation.',
  ),
  TermsSection(
    'Admin responsibilities',
    'Admins are responsible for accurate record-keeping, timely approval '
        'decisions, and maintaining the audit trail for every financial '
        'action they take.',
  ),
  TermsSection(
    'Member responsibilities',
    'Members are responsible for reviewing their own contribution and loan '
        'history and reporting discrepancies promptly.',
  ),
  TermsSection(
    'Financial transparency',
    'Fund totals, transaction history, and loan status are visible to all '
        'members according to the configured privacy settings, in line '
        'with this app\'s transparency-first design.',
  ),
  TermsSection(
    'Account termination',
    'An account may be deactivated by an admin; historical financial '
        'records are preserved regardless of account status.',
  ),
];
