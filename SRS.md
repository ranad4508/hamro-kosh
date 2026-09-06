# Software Requirements Specification — Hamro Kosh

Community Fund & Lending Management System

## 1. System Overview

The Community Fund & Lending Management System is a mobile application for
managing a shared community fund where a group of members regularly
contribute money and the collected fund can be used for approved purposes,
community occasions, emergency support, or member loans.

The system focuses on:

- Regular member contributions
- Special occasion contributions
- Complete financial transparency
- Member-to-member financial visibility
- Fund usage tracking
- Member borrowing and lending
- Interest and repayment management
- Notifications and reminders
- Email-based financial communication
- Administrative control
- Complete transaction history and auditability

The application has two primary interfaces — a **Member Application** and
an **Admin Management System** — implemented as a single role-gated Flutter
app rather than two separate builds (see §57).

## 2. User Roles

### 2.1 Member

Members can: create and manage their profile; view other members; add/
contribute money; view their contribution history; view other members'
contributions; view total fund balance; view fund income and expenses; view
fund usage; request a loan; view their active loans; view repayment
schedules; make loan repayments; view interest charged; receive
notifications and reminders; receive financial emails; view community
financial reports; view important terms and conditions.

### 2.2 Admin

Admins can: manage members; approve/reject members; manage member status;
manage contributions; manage fund transactions; manage loans; approve/
reject loan requests; configure interest rules; configure repayment rules;
manage special contributions; manage fund expenses; manage fund income;
manage financial categories; manage notifications; manage email
communication; generate reports; view complete audit history; control
system settings.

## 3. Authentication & Account Features

**3.1 Registration** — name, email, phone number, password, profile photo,
optional personal information.

**3.2 Login** — email/password; supported authentication providers.

**3.3 Account Recovery** — reset password; recover account; change
password; update email; update phone number.

**3.4 Account Verification** — email verification; phone verification;
admin approval.

## 4. Member Profile

Each member has a public profile within the community: profile picture,
full name, member-since date, email/phone visibility settings, total
contributed amount, number of contributions, active loan status, community
participation information. Sensitive information is only visible according
to configured privacy rules (§47).

## 5. Dashboard

The member dashboard provides a clear financial overview: current total
fund balance; total collected; total used; total lent; total outstanding
loans; total interest earned; total expenses; monthly contribution; the
user's total contribution; recent transactions; upcoming payment; pending
loan request; important announcements. The dashboard prioritizes financial
transparency.

## 6. Fund Overview

Members can view the overall financial status of the community fund:
current available balance, total contributions, total special
contributions, total loaned amount, total outstanding loan amount, total
interest earned, total expenses, total other income.

**Fund Formula**

```
Available Fund = Total Income − Total Expenses − Outstanding/Lent Amount
```

The system distinguishes cash currently available, money currently lent,
money expected from repayments, and money already spent.

## 7. Regular Contributions

Members contribute the predefined monthly amount (e.g. NPR 200/300/month,
or a custom amount if permitted). Features: view required monthly
contribution; add contribution; select payment method; upload payment
proof if required; view contribution status; view contribution history;
view monthly payment status; view missed contributions; receive
contribution confirmation.

## 8. Special Contributions

Additional contributions for special occasions (birthday, marriage,
Dashain, Tihar, emergency, community event, New Year, other custom
events). Each campaign has: name, description, target amount, required
contribution, start/end date, eligible members, contribution status, total
collected, participating members. Members can view who contributed and the
total collected amount according to transparency settings.

## 9. Contribution History

Every member has access to their complete contribution history: date,
amount, contribution type, month, occasion, payment method, transaction
status, reference number, verification status. Filterable by date, month,
year, contribution type, and status.

## 10. Community Contribution Transparency

Depending on privacy configuration, members can see other members'
profile, contribution amount, date, type, monthly contribution status, and
special contribution participation — a transparent contribution
leaderboard/history without exposing unnecessarily sensitive information.

## 11. Fund Transactions

All financial movements are recorded as transactions. Types: monthly
contribution, special contribution, loan disbursement, loan repayment,
interest payment, fund expense, refund, adjustment, other income, other
expenditure. Each transaction has: ID, date, amount, type, description,
person/member involved, status, reference, supporting document/proof where
applicable.

## 12. Transaction Transparency

Members can view money received, spent, lent, repaid, interest received,
and other income/expenses. Transactions never simply disappear — a
correction preserves the original record and shows the adjustment history.

## 13. Fund Usage

Usage categories: member loan, birthday expenses, Dashain expenses,
emergency assistance, community event, administrative expenses, gifts,
welfare activities, other approved expenses. Each usage record: amount,
date, category, description, recipient, supporting document, approved by,
status.

## 14. Expense Management

Admins record fund expenses: amount, category, date, description,
recipient, payment method, receipt/proof, approval status. Members view
approved expenses through the transparency section.

## 15. Loan / Borrowing System

Members request money from the community fund. A loan request contains:
requested amount, purpose, requested date, preferred repayment duration,
additional explanation, supporting documents if required.

## 16. Loan Eligibility

Configurable rules: minimum membership duration, minimum contribution
history, maximum loan amount, existing loan status, outstanding repayment,
contribution percentage, admin-defined eligibility rules.

## 17. Loan Approval

Admins can view requests, review member/loan/contribution history, approve
or reject, request additional information, modify the approved amount, set
repayment duration/frequency/interest rate, and add special conditions.

## 18. Interest Rules

Configurable: interest rate; monthly/annual/fixed/reducing-balance/flat
interest; grace period; late payment interest; penalty; minimum repayment;
maximum repayment period. The applicable rule is shown to the borrower
before acceptance.

## 19. Loan Terms & Conditions

Each loan clearly states: amount, interest rate, calculation method, total
payable, repayment duration/frequency, due dates, late payment rules,
penalties, grace period, early repayment rules, default conditions, other
special conditions. The borrower confirms acceptance before finalization.

## 20. Loan Agreement

A digital loan agreement contains: borrower information, amount, interest,
repayment schedule, terms and conditions, approval date, due dates,
agreement status. Members can view agreements at any time.

## 21. Loan Disbursement

After approval: loan amount is recorded; fund balance updates; loan
becomes active; repayment schedule is created; borrower receives
notification and email confirmation; the transaction appears in the public
financial ledger.

## 22. Loan Repayment

Members record/make repayments: amount, date, payment method, loan
reference, principal amount, interest amount, penalty if applicable,
remaining balance. The system automatically updates remaining principal,
remaining interest, total outstanding amount, loan status, and community
fund balance.

## 23. Repayment Schedule

Borrowers can view: total loan, total interest, total payable, paid
amount, remaining amount, next payment/due date, payment history, late
payments, penalties.

## 24. Loan Status

`Requested → Under review → Approved / Rejected → Active → Partially paid
→ Completed`, with `Overdue`, `Cancelled`, and `Defaulted` as exception
states.

## 25. Loan Transparency

Depending on configured privacy rules, members can see borrower/member,
loan amount, approval date, outstanding amount, interest generated,
repayment status, and loan status — so members understand where the
community fund is currently deployed.

## 26. Financial Reports

**Monthly** — total collected, expenses, loans, repayments, interest
earned, closing balance. **Yearly** — total contributions, expenses,
lending, repayment, interest, income, closing balance. **Fund** —
available cash, outstanding loans, total assets, total expenses, total
income.

## 27. Financial Dashboard / Charts

Monthly contributions, monthly expenses, loan distribution, repayment
progress, fund growth, income vs. expenditure, outstanding loans, interest
earned.

## 28. Email Notifications

**Contribution email** — amount, date, type, transaction ID, updated
total. **Fund usage email** — amount used, purpose, category, date,
updated balance. **Loan email** — requested/approved/rejected/disbursed/
repaid/overdue. **Monthly report email** — fund summary.

## 29. Push Notifications

Monthly contribution reminder; missed contribution; special contribution;
birthday/Dashain contribution; loan approval/rejection; repayment
reminder; upcoming/overdue due date; fund transaction; important
announcement; system updates.

## 30. Reminder System

Admin-configurable automated reminders: monthly contribution, contribution
deadline, loan repayment, due date, overdue, special occasion. Reminder
frequency is configurable.

## 31. Community Members

Members browse the community member list (photo, name, member-since,
contribution participation, community activity), with search/filter.

## 32. Member Financial Profile

Optionally displays total contributions, monthly contribution status,
special contributions, active loans, loan repayment status, community
participation — visibility controlled by admin/privacy settings.

## 33. Announcements

Admins publish announcements (monthly contribution notice, new fund rules,
special event, emergency collection, loan policy changes, community
meeting, important financial updates) via in-app notification, push
notification, and/or email.

## 34. Admin Dashboard

Total members; active members; total fund; available balance; total
contributions; total expenses; total loans; outstanding loans; total
interest; pending loan requests; pending transactions; overdue loans;
recent activities.

## 35. Member Management

Add/approve/edit/disable/activate/remove members; view member/
contribution/loan/transaction history. A member's historical financial
records remain preserved even if their account becomes inactive.

## 36. Transaction Management

Add/edit/approve/reject/cancel transactions; add proof; view/search/filter/
export transactions. Financial records maintain an audit history.

## 37. Loan Management

View all loans; review requests; approve/reject; configure terms; record
disbursement/repayment; adjust repayment; mark overdue/completed; view
loan/borrower history.

## 38. Contribution Management

Configure monthly contribution amount; record/verify contributions;
approve/reject payment proof; add manual contributions; correct records;
view missing contributions and member contribution status.

## 39. Fund Rules Management

Configure monthly contribution, special contribution rules, loan limits,
interest rates, repayment duration, late payment rules, penalties,
eligibility requirements, approval requirements, fund usage rules. Changes
to important financial rules are recorded with old value, new value,
changed by, date, and reason.

## 40. Audit Trail

Every important administrative action is recorded (member created/
disabled, contribution added, transaction changed, loan approved/
rejected/modified, expense added, financial rule changed, payment
recorded), with action, user/admin, date/time, related transaction, and
previous/new value where applicable.

## 41. Transparency Ledger

A dedicated Transparency / Financial Ledger section — one of the app's
primary features — showing:

- **Money In**: member contributions, special contributions, loan
  repayments, interest, other income.
- **Money Out**: member loans, community expenses, event expenses,
  emergency support, other approved expenses.
- **Current Position**: total fund, available cash, outstanding loans,
  total interest receivable, total expenses.

## 42. Search & Filtering

Members, transactions, contributions, loans, expenses, and reports are
searchable/filterable by date, member, transaction type, amount, status,
category.

## 43. Export & Reporting

Admins can export member lists, contribution/transaction/loan/repayment/
expense reports, monthly/yearly/complete fund reports, as PDF, CSV, or
Excel.

## 44. Data Corrections

Authorized admins can correct mistakes (incorrect contribution/expense/
repayment/loan amount) without silently overwriting financial history —
the system keeps the original record, the correction, the reason, the
responsible admin, and the date/time.

## 45. Notifications Center

In-app notifications, categorized unread/read/important/financial/
reminder/announcement, markable as read.

## 46. Email Preferences

Members can configure which non-critical emails they receive
(contribution, loan, repayment reminders, monthly reports, community
announcements, special occasion notifications). Critical financial
notifications cannot be disabled where required.

## 47. Privacy Controls

Configurable visibility rules for whether members can see other members'
contributions, loan amounts, outstanding loans, individual expenses, email
addresses, and phone numbers — balancing transparency with personal
privacy.

## 48. Terms & Conditions

Covers membership, contributions, fund usage, borrowing, interest,
repayment, late payments, penalties, loan default, dispute handling, admin
responsibilities, member responsibilities, financial transparency, and
account termination. Users acknowledge applicable terms before
participating in relevant activities.

## 49. Dispute / Issue Reporting

Members can report incorrect transactions/contributions/loan balances/
repayments, unauthorized transactions, or other financial issues; submit
with description and evidence; track status. Admins review, investigate,
respond, resolve, or reject with explanation.

## 50. Security & Financial Protection Features

Secure authentication; role-based access; admin authorization; transaction
verification; financial audit history; sensitive data protection; login/
session management; account deactivation; suspicious activity tracking. No
member can modify another member's financial records.

## 51. Important Business Rules

1. Every financial movement must have a transaction record.
2. Members should be able to understand where the fund came from and
   where it went.
3. Financial transactions must not be permanently deleted.
4. Corrections must create an audit trail.
5. Loan terms must be visible before approval/acceptance.
6. Loan interest must be calculated according to the configured rule.
7. Repayments must update the outstanding loan balance.
8. The displayed fund balance must reflect recorded transactions.
9. Only authorized admins can approve financial transactions.
10. Members must be able to view their own complete financial history.
11. Community-level financial information should be transparent according
    to configured privacy rules.
12. Members should receive confirmation for important financial
    activities.
13. Important financial events should generate notifications and/or
    emails.
14. Historical financial records must remain traceable.

## 52. Main Mobile App Navigation (Member)

- **Home** — fund summary, personal summary, recent transactions,
  notifications.
- **Fund** — total fund, money in/out, fund usage, financial charts.
- **Contributions** — monthly/special contributions, history, add.
- **Loans** — request, my loans, repayment schedule/history, terms.
- **Members** — community members, profiles.
- **Transactions** — financial ledger, history, filters.
- **Reports** — monthly, yearly, fund.
- **Notifications** — reminders, financial notifications, announcements.
- **Profile** — my profile, financial history, settings, notification
  preferences, Terms & Conditions.

> **Implementation note:** the shipped app surfaces these nine sections
> through a 5-destination bottom navigation bar (Home, Fund, Loans,
> Members, Profile) plus quick actions and menu entries for
> Contributions/Transactions/Reports/Notifications — see §57.

## 53. Main Admin Navigation

- **Dashboard** — financial overview, members, loans, contributions,
  expenses, income, transactions.
- **Members** — management, history, status.
- **Contributions** — monthly, special, pending payments.
- **Loans** — requests, active, overdue, completed, rules.
- **Fund** — balance, income, expenses, usage, financial ledger.
- **Reports** — monthly, yearly, contributions, loans, expenses, complete.
- **Notifications** — push, email, reminders, announcements.
- **Settings** — contribution/loan/interest/repayment rules, privacy,
  Terms & Conditions.
- **Audit** — admin activities, financial changes, transaction history.

## 54. Core Transparency Dashboard

The most important screen in the system must immediately answer: How much
money do we have? How much have members contributed? How much has been
spent? How much has been lent? How much has been repaid? How much interest
has been earned? Who has an outstanding loan? What was the latest
transaction? What is the current available balance? A member should never
need to ask the administrator for these basic financial details.

## 55. Overall Financial Flow

```
Money In                          Money Out
─────────────────────             ─────────────────────
Monthly Contributions   ┐         Member Loan            ┐
Special Contributions   ├─→ Fund  Community Expense      ├─→ Recipient
Loan Repayments         │         Event Expense           │
Interest                │         Emergency/Support       │
Other Income            ┘                                 ┘

Result: All transactions → Financial Ledger → Updated Fund Balance
        → Reports → Member Notifications → Email Notifications
```

## 56. MVP Feature Set

**Member** — registration/login, profile, member list, monthly/special
contribution, contribution history, fund balance, transparent financial
ledger, fund usage, transaction history, loan request/status/terms,
repayment schedule/history, notifications, email notifications, reminders,
reports, Terms & Conditions.

**Admin** — admin dashboard, member/contribution/transaction/fund/expense/
loan management, loan approval, interest/repayment configuration,
financial reports, notifications, email management, audit trail,
transparency controls, system settings.

## 57. Implementation Notes

This section bridges the specification above to the delivered Flutter
codebase (see [README.md](README.md) for the full breakdown):

- **Single role-gated app**, not two separate builds — after sign-in, the
  router (`lib/core/router`) sends `role: member` to the Member shell and
  `role: admin` to the Admin shell. This keeps one App Store/Play Store
  listing and one codebase in sync with itself, at the cost of the admin
  build carrying member-only screens it never routes to (an acceptable
  trade for a community-sized deployment).
- **State management**: Riverpod, chosen for first-class `Stream`/`Future`
  support (every screen here is backed by a live Firestore stream) and
  compile-time provider safety.
- **Navigation**: `go_router` with `StatefulShellRoute.indexedStack` for
  the two bottom-nav shells, and a single `redirect` callback as the
  entire access-control policy for rule 9 in §51.
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging). Firestore's
  offline cache is enabled (`core/services/firestore_offline_config.dart`)
  given patchy connectivity is a realistic constraint for this user base.
- **Architecture**: feature-first folders, each with `data/` (Firestore
  repository + model), `providers/` (Riverpod), and
  `presentation/{screens,widgets}/` — SOC without a redundant domain/entity
  layer duplicating already-immutable data models.
- **Design system**: Material 3, a brand seed color sampled from the
  Hamro Kosh mark, and a `FinanceColors` theme extension so income/expense/
  pending colors are never hardcoded per-screen.

## 58. Additional Recommended Features (Beyond Initial Scope)

Proposed for future passes — not required by the original brief, but
natural extensions of it. The lower-cost ones are already implemented in
the current codebase (marked ✅); the rest are documented here as scoped,
ready-to-build proposals.

- ✅ **Biometric/PIN app lock** (`local_auth`) — locks the whole app behind
  a device biometric/credential check, a natural expectation for a
  financial app. See `lib/core/security`.
- ✅ **English + Nepali localization** (`flutter_localizations`) — directly
  relevant given the product's Nepali branding and userbase. See
  `lib/l10n`.
- ✅ **Three-tier RBAC (member / admin / super admin)** — a super admin
  (never deletable, never client-creatable, hidden from every member/admin
  list) and admins can both provision new accounts directly rather than
  relying only on self-registration, with login credentials emailed to the
  new user and a forced password change on first login. See
  `lib/core/models/user_role.dart`, `firestore.rules`, and
  `functions/index.js`.
- ✅ **Cloudinary-hosted photos + transactional email via Resend** — image
  uploads (profile photos, to start) go through an unsigned Cloudinary
  preset from the client; account-creation email goes through a Cloud
  Function that's the only place holding the Resend API key. Neither
  provider's secret ever ships inside the app. See "A security note on
  Cloudinary/Resend" in README.md.
- **Loan guarantor / co-signer support** — an optional second member who
  co-signs a loan request, common in real community lending circles and a
  meaningful trust signal beyond admin approval alone.
- **E-signature capture for loan agreements** — a simple signature-pad
  widget captured at loan acceptance (§20), stored alongside the agreement
  record for dispute resolution.
- **QR member-reference codes** — a scannable code on a member's profile
  for quick lookup/verification at in-person contribution collection
  events.
- **Fund sustainability insight** — a simple projection ("at the current
  lending rate, the fund could be fully deployed within N months") on the
  admin dashboard, surfacing a risk signal transparency alone doesn't
  provide.
- **SMS backup notifications** — a fallback channel for members without
  reliable data connectivity or email access, for the same critical events
  §46 already mandates over push/email.
- **Calendar sync for due dates** — "Add to calendar" on a loan's next
  repayment due date and on special-contribution deadlines.
- **Home-screen balance widget** — an Android/iOS home-screen widget
  showing the member's next due date and the fund's available balance, for
  at-a-glance transparency without opening the app.
- **Mandatory two-factor authentication for admin accounts** — a higher
  security bar for the highest-privilege role, given admins can approve
  financial transactions per §51 rule 9.
