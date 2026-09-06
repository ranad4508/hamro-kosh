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

## Phase 2 — Loans feature polish

- [ ] 2.1 Request Loan screen — redesigned, responsive
- [ ] 2.2 My Loans list — redesigned
- [ ] 2.3 Loan Detail — redesigned, repayment timeline visualization

## Phase 3 — Fund feature polish

- [ ] 3.1 Fund overview / money in-out tabs
- [ ] 3.2 Transaction ledger + filters

## Phase 4 — Contributions feature polish

- [ ] 4.1 Contributions list (monthly/special/history)
- [ ] 4.2 Add contribution flow (incl. payment-proof photo upload)

## Phase 5 — Members & Profile polish

- [ ] 5.1 Member directory + member detail
- [ ] 5.2 Profile, settings, edit profile, change password (functional, needs visual pass)

## Phase 6 — Admin suite polish

- [ ] 6.1 Admin dashboard
- [ ] 6.2 Member management + create-account flow
- [ ] 6.3 Loan/contribution review queues
- [ ] 6.4 Fund/settings/audit

## Phase 7 — Reports & notifications polish

- [ ] 7.1 Reports (charts, monthly/yearly/fund)
- [ ] 7.2 Notification center + announcements

## Blocked on external setup (see README.md)

- [ ] Deploy `functions/` (needs Firebase Blaze plan)
- [ ] Create Cloudinary unsigned upload preset
- [ ] Place iOS `GoogleService-Info.plist` (needs a Mac)
