# Hamro Kosh — Build Roadmap

Tracks the screen-by-screen / feature-by-feature build-out across sessions,
broken into phases with checkable subphases. Update the checkboxes as work
lands; keep entries terse — this is a tracker, not a design doc (design
rationale belongs in code comments, SRS.md, or README.md).

## Phase 1 — Platform & UX fixes

- [x] 1.1 Widen `AppSnackbar` (was constrained by Flutter's default floating margin)
- [x] 1.2 Splash: separate icon-only mark + independently animated "HAMRO KOSH" wordmark
- [x] 1.3 Back-button audit — every pushed screen needs a way back
- [x] 1.4 Super admin auto-seed, idempotent, server-side only (`functions/index.js`)
- [x] 1.5 Transparency broadcast email on contribution/loan events (`functions/index.js`)

## Phase 1b — Bug fixes from live testing

- [x] `AppSnackbar` bubble-icon badge was clipped (SnackBar defaults to `Clip.hardEdge`, cutting off the package's deliberately-overflowing icon) — fixed with `clipBehavior: Clip.none`
- [x] Router never checked `isApproved`/`isActive` — a pending or disabled account fell into the member shell and hit permission-denied everywhere instead of a clear holding screen. Added `AccountPendingScreen` + redirect gate.
- [x] Registration now sends a Firebase email-verification email (OWASP A07)
- [x] Cloud Functions admin actions (`createUserAccount`, super admin seed) now write to `audit_log` (SRS §40 / OWASP A09)

## Phase 2 — Loans feature polish

- [x] 2.0 Fixed lending policy adopted from the reference design (replaces
      the old admin-freeform rate): `LoanCategory` (Personal — 30% fund
      cap, 1%/mo, 1 quarter; Emergency — 80% cap, 0.5%/mo, 1-2 quarters),
      a fund-wide 2-concurrent-loan cap, and the escalating 1.5%/mo late
      penalty. Enforced server-side in `approveLoan` (`functions/index.js`),
      not just the client.
- [x] 2.1 Request Loan screen — category picker, live "N of 2 slots
      available" indicator, fund-share cap shown/validated per category,
      live "What this will cost" timeline preview as the amount is typed
- [x] 2.2 My Loans list — `LoanCard` redesigned with a category icon
      avatar, cleaner amount/status hierarchy, slimmer progress bar
- [x] 2.3 Loan Detail — terms section shows category/rate/penalty rule,
      plus a `LoanCostTimeline` repayment/penalty visualization (on-time
      vs. missed-payment cost, reused in the admin approval sheet too)

## Phase 3 — Fund feature polish

- [x] 3.1 Fund overview / money in-out tabs — new `FundHeroCard` (SRS
      §12/§13/§53/§54): "Available right now" + a single in-hand/lent-out
      segmented bar + "Total fund position", so those three numbers are
      never conflated. Reused on the member Dashboard, Fund screen, and
      Admin Fund screen. `FundSummaryGrid` now shows the four secondary
      figures ("Members have given", "Spent by the group", "Interest
      earned", "Owed back to us") instead of duplicating the hero card.
      Money In/Out tabs got a running "Total in"/"Total out" header.
- [x] 3.2 Transaction ledger + filters — added a `DateFilter` chip (SRS
      §45) alongside the existing type filter, both applied server-side
      (`FundRepository.watchTransactions` now takes a `DateTimeRange`,
      new `ledgerTransactionsProvider` keyed on type+range), plus a
      filtered-vs-empty-ledger-aware empty state.

## Phase 4 — Contributions feature polish

- [x] 4.0 Minimum monthly contribution corrected to NPR 250 (was 200) to
      match the reference design (`FundRules.defaults`).
- [x] 4.1 Contributions list — tiles redesigned with a category icon
      avatar, a "covers N months"/attachment indicator, and a per-tab
      "Verified total / N pending" summary header.
- [x] 4.2 Add contribution flow — payment-proof photo upload via a new
      reusable `ProofPicker` (image_picker + Cloudinary, mirrors
      `AvatarPicker`'s plumbing), a "months covered" stepper for catching
      up on/paying ahead several months in one entry (the reference
      design's multi-month receipt), and minimum-amount validation against
      `FundRules.monthlyContributionAmount × months`. Admin's verification
      card now shows the attached proof photo and months-covered/payment
      method — previously invisible to the person approving it.

Note: the reference design's cash-vs-non-cash proof copy is honored (no
proof *required* for cash), but SRS §33 "view missed monthly
contributions" (computing arrears against a join date) is still open —
real scope on its own, not attempted here.

## Phase 5 — Members & Profile polish

- [x] 5.1 Member directory + member detail — fixed a real bug along the
      way: `totalContributed`/`hasActiveLoan` were read off `users/{uid}`
      fields nothing ever wrote, so Member Detail's financial summary was
      permanently empty/wrong. Removed the dead fields from
      `MemberDirectoryEntry` and compute both live instead:
      `memberVerifiedContributionsTotalProvider`/`memberHasActiveLoanProvider`
      (member detail, one listener) and `outstandingBorrowerIdsProvider`
      (directory list, one shared listener instead of one per row). Also
      loosened `firestore.rules` so any active member can read another
      member's `contributions` (previously self/admin-only) — SRS §2.1/§12
      name member-to-member financial visibility as a core principle, and
      `loans` already had this level of visibility.
- [x] 5.2 Profile — added a "My contributions / Active loan" summary card
      reusing the same providers, so a member sees their own numbers
      without leaving Profile. Settings/Edit profile/Change password were
      already solid; left as-is.

## Phase 6 — Admin suite polish

- [x] 6.1 Admin dashboard — added `FundHeroCard` above the stat grid, same
      as the member Dashboard/Fund screen (Phase 3), for one consistent
      "available/outstanding/total fund position" story everywhere.
- [x] 6.2 Member management + create-account flow — member tiles now show
      the actual profile photo (previously always just the initial) and a
      search bar was added, matching the member directory.
- [x] 6.3 Loan/contribution review queues — already redesigned as part of
      Phase 2 (category-aware approval sheet + cost timeline) and Phase 4
      (proof photo + months-covered shown); nothing further needed here.
- [x] 6.4 Fund/settings/audit — Fund overview got the hero card in Phase 3
      already. **Fixed a real bug in Settings**: `AdminSettingsScreen` still
      had editable "default interest rate / repayment months / late
      penalty / max loan amount" fields wired to `FundRules`, but nothing
      has read `FundRules` for loan terms since Phase 2's fixed-category
      policy landed — an admin changing those numbers did nothing, silently.
      Removed the dead fields from `FundRules` (kept only
      `monthlyContributionAmount`, which is real) and replaced the loan
      section with a read-only "Lending policy" summary sourced directly
      from `LoanCategory`, so it can't drift from what's actually enforced.
      Audit Trail now resolves `performedBy` (a raw uid) to the member's
      name and shows `newValue` — previously invisible despite the model
      already carrying it.

## Phase 7 — Reports & notifications polish

- [x] 7.1 Reports — **fixed a real bug**: the Monthly and Yearly tabs both
      read the single all-time `fund/summary` snapshot, so they showed
      byte-for-byte identical numbers regardless of which tab was open.
      Now genuinely period-scoped, computed from the ledger via
      `ledgerTransactionsProvider` with a start-of-month/start-of-year date
      range. Added a "Fund growth" bar chart (SRS §30) to the Fund tab —
      money in per month for the last 6 months, bucketed from the ledger
      (`monthlyFundGrowthProvider`) — matching the reference design's
      "Collected each month" chart.
- [x] 7.2 Notification center — `markRead` and `unreadNotificationsCountProvider`
      existed but were never called/used from any screen: notifications
      never actually got marked read, and no unread badge was shown
      anywhere. Wired both up: tapping a notification marks it read and
      opens a detail sheet (title/body/timestamp), a "Mark all read" action
      appears when there's something unread (SRS §45), and the Dashboard's
      bell icon now shows a live unread-count `Badge`. Announcement
      composing (admin side) already worked and needed no changes.

Note: publishing an announcement only writes to Firestore — there's no FCM
push or email triggered for it yet (unlike contributions/loans, which do
trigger email via `notifyOnTransaction`). Real push/email delivery for
general announcements is SRS §23/§24 scope, not attempted here.

## Phase 8 — MongoDB Atlas migration (explored, declined — staying on Firebase)

Considered moving the backend to MongoDB Atlas. Dead end, for the record:

- First pick, Atlas App Services (Auth + Functions + Device Sync), turned
  out to have reached full end-of-life on 2025-09-30 — confirmed live
  against the user's own Atlas project (no "App Services" entry in the
  sidebar) and against MongoDB's own docs/announcements. Not creatable at
  all anymore; the functions written for it were deleted.
- The remaining honest options (self-hosted Node/Express, or a revived
  Cloudflare Worker) all require the same one-time server deploy Firebase
  already needs — MongoDB wasn't actually removing a step, just discarding
  seven phases of already-working, already-tested backend code to add a
  database technology that wasn't solving a problem this app had. Real-
  time updates specifically would need MongoDB Change Streams + a
  hand-built WebSocket relay (Change Streams do work on the free M0 tier,
  contrary to some outdated blog claims — but something still has to hold
  that connection open and relay it, which a serverless Worker can't do).
- Decision: stay on Firebase. It already gives exactly what was wanted —
  no server to run or maintain — and is fully built and tested.

No code changes resulted from this detour; `functions/index.js`,
`firestore.rules`, and every repository are unchanged from the end of
Phase 7.

## Phase 9 — Loan repayment recording (SRS §21)

Previously a real gap: `Loan.amountPaid` never moved off 0 because nothing
anywhere recorded a repayment, so outstanding balance, repayment progress,
and "interest earned" were all structurally stuck.

- [x] 9.1 New `LoanRepayment` model/collection (`loan_repayments`) — mirrors
      the contribution model's shape: a member submits a claim ("I paid
      NPR X"), `pending` until an admin verifies it.
- [x] 9.2 `verifyRepayment` Cloud Function — splits a verified payment into
      principal/interest/penalty (penalty first, then interest, then
      principal), using the *same* escalating-penalty formula as
      `LoanCostTimeline`'s client-side preview so they never disagree.
      Updates the loan's running balances, auto-transitions its status
      (`partiallyPaid`/`overdue`/`completed`), records `loanRepayment` +
      `interestPayment` ledger entries, updates the fund total (so
      "Interest earned" in Reports finally populates with real data), and
      broadcasts the transparency email.
- [x] 9.3 Member UI — "Record a repayment" screen (amount, payment
      method, optional proof) reachable from Loan Detail for any
      disbursed loan, plus a repayment-history list on that screen.
- [x] 9.4 Admin UI — new "Repayments" tab on Manage Loans, reviewing
      pending claims with the attached proof photo, same verify/reject
      pattern as contributions.

Loans that receive zero repayments used to never auto-flip to `overdue` —
fixed in Phase 10 (`dailyLoanSweep`) below.

## Phase 10 — Remaining gaps closed out

Everything from the post-Phase-9 gap review, in one pass:

- [x] 10.1 Expense recording (SRS §17) — `recordExpense` Cloud Function
      (category, recipient, payment method, receipt photo) + a "Record
      expense" FAB on Manage Fund. `FundTransaction` gained `category`/
      `recipient` fields; the ledger tile shows them.
- [x] 10.2 Per-member notifications, actually wired — `notifyUser` existed
      nowhere before; now called from `createUserAccount` (welcome),
      `verifyContribution`, `approveLoan`, and `verifyRepayment` (both
      outcomes each). The Notifications tab built in Phase 7 now has a
      real producer.
- [x] 10.3 Push notifications (FCM) — the actual missing piece was token
      persistence: `NotificationService` requested permission and fetched
      a token but never saved it anywhere. Now saves it to
      `users/{uid}.fcmToken` on auth state change/token refresh (rule
      updated to allow it), and `notifyUser` sends a push alongside every
      in-app notification, best-effort (a stale token never blocks the
      caller).
- [x] 10.4 `dailyLoanSweep` scheduled function (SRS §22) — reminders at
      7/3/1 days before due and on the due date (push + in-app + email),
      and the auto-transition to `overdue` that was missing — a loan with
      zero repayments now correctly flips status on its own.
- [x] 10.5 Special contribution campaigns (SRS §15) — `Campaign` model/
      collection, admin create screen, member browse screen with live
      progress bars, and `Contribution.campaignId` linking a contribution
      to one. Reachable from Contributions' app bar and Admin's more menu.
- [x] 10.6 Dispute/issue reporting — member submits a report (Profile →
      "Report an issue"), admin reviews and resolves with an optional
      response, visible back to the reporter. Private between reporter +
      admin, unlike the fully-transparent ledger collections.
- [x] 10.7 Admin-configurable privacy settings (SRS §29) — deliberately
      three toggles, not the SRS's full list: `showContributionAmounts`,
      `showActiveLoanStatus`, `showPhoneNumber` — the only member-to-member
      fields the app actually displays anywhere. Expense details and the
      ledger stay always-visible on purpose (fund governance, not personal
      privacy — see `PrivacySettings`'s doc comment); no toggle was added
      that wouldn't have gated anything real.

## Blocked on external setup (see README.md)

- [ ] Enable Firebase Blaze plan + deploy `functions/` — still the one
      real blocker: account creation, contribution verification, loan
      approval, expense recording, and the daily reminder sweep are all
      unreachable until this is deployed. See README.md → "Deploy the
      Cloud Functions."
- [ ] Place iOS `GoogleService-Info.plist` (needs a Mac)
- [ ] Firebase Console: tighten password policy + enable email enumeration protection (Authentication → Settings)
