# Hamro Kosh — Design Specification (from Claude Design canvas transcript)

Source: `hamro_kosh_design.html` (~234KB, 1945 lines), a 6-turn design conversation, each turn presenting 1-3 lettered mobile-mockup options in an Android device frame (412×892, dark theme, "Nocturne" design system).

> **HEADLINE FINDING — NO LOGIN / AUTHENTICATION SCREEN EXISTS IN THIS DESIGN.**
> The only account-entry screen designed is a **join/registration** screen (option `4a`): name + mobile number + committee invite code, submitted for treasurer approval. At the bottom of that screen there is a plain text link — *"Already a member? Sign in"* — but **no sign-in screen, password field, OTP/verification screen, or password-reset flow appears anywhere in the 6 turns.** I searched every turn's copy for "login", "sign in", "password", "OTP", "verify" and found only that one link. This is a real gap: the rebuild will need to either design a sign-in screen from scratch (matching this design language) or decide on a passwordless mechanism (e.g. phone OTP, since the join flow already collects a masked mobile number `+977 98•• ••• •••`). Treat this as an open decision for the team, not something to silently invent.

---

## 0. How to read this document

- Turns are numbered 1–6 in **creation order** (turn 1 was designed first; turn 6 last). In the source file they appear in **reverse** order (turn 6 at the top, turn 1 at the bottom) because it's a transcript, newest-first.
- Each turn presents lettered options, e.g. `1a`, `1b`, `1c`. Where a turn presents **genuine alternatives** (mutually exclusive directions for the same screen), I identify which one was carried forward as canon and which were rejected, using explicit textual evidence (cross-references like `built on <a href="#1a">1a</a>`, or "try next" notes).
- Where a turn's lettered options are **not** alternatives to each other but rather a set of *different, all-adopted* screens (e.g. turn 2's "member app — the rest of the screens"), I say so — there is no rejected option to discard, all lettered screens in that turn are part of the final app.
- All colors, copy, and numbers below are transcribed exactly from the source HTML (inline `style=` attributes and literal text), since no separate stylesheet was inlined in the canvas (styles.css is referenced only by URL, `_ds/nocturne-.../styles.css`, and its content is not present in the canvas file — I've reconstructed the effective token values from the ~600 inline style declarations actually used across all 20 screens, and cross-referenced them against the already-known repo tokens supplied in my task brief).

---

## 1. Design tokens

### 1.1 This is a dark-only design

There is **no light theme** anywhere in the canvas. Every one of the 20 screens renders on `background:#161826` (the `.scr` container) inside an outer canvas backdrop of `#0f111c`. The **one and only exception** is a small embedded mockup-within-a-mockup: the "what the member receives" email preview inside screen `4f` (email templates), which deliberately renders a light "email client" card (`background:#f3f2f2; color:#201e1d`) to simulate what an email looks like in an inbox — this is not a UI light-mode, it's a diegetic email preview and should not inform the app's actual theming.

### 1.2 Color roles (hex, as used)

| Role | Hex / value | Where seen |
|---|---|---|
| App/page background | `#161826` | `.scr` root of every screen |
| Outer canvas backdrop | `#0f111c` | outside the phone frame |
| Surface (card) | `#232532` | `.cd`, `.card`, list containers, tag/member rows |
| Surface — inset/sunken (inputs, highlighted sub-cards, tab bar) | `#1e2030` | `.input`, selected-option chips, payment method cards, ledger "total" row background |
| Surface — footer/tab bar | `#1b1d2a` / `#1a1c29` | sticky bottom action bar, `.tb` tab bar, screenshot placeholder background |
| Divider / hairline track background | `#292b31` | progress-bar tracks, divider under grouped rows |
| Primary text | `#e9e9ed` | default text color |
| Secondary text (mid grey) | `#b2b6ca` | de-emphasized body copy, unselected tab labels' icon strokes |
| Tertiary text (muted grey) | `#9397ab` | captions, `.np` Nepali subtitles, helper text, `.mut` class |
| Quaternary text (faintest grey) | `#75798c` | timestamps, tiny kicker labels, disabled-state text |
| **Accent (primary purple)** | `#9184d9` | primary buttons, active tab icon, focused input underline/ring, key numerals, progress-bar fill |
| Accent — light/highlight variant | `#b5abfc` | links, "+something" deltas, icons inside accent-tinted chips, checkmarks |
| Accent — lightest (text-on-dark-accent-surface) | `#d2cefd` / `#e7e5fe` / `#f5f4ff` | text sitting on accent-colored chip backgrounds (ramp from dim to bright) |
| Accent — dark ramp step 1 | `#423a6a` | inset ring color on accent-emphasized cards ("waiting for approval" card outline) |
| Accent — dark ramp step 2 | `#2b2741` | icon-chip circular backgrounds, avatar (`.av`) background |
| Accent — dark ramp step 3 (mid) | `#5d5294` | bar-chart bars (mid-value), "already covered" month chips |
| Accent — dark ramp step 4 | `#796cbf` | bar-chart bars (higher-value / mid-late), transitional chart bars |
| Warning / overdue / negative (warm terracotta) | `#d2a08a` | overdue amounts, "past fifteen months" penalty text, late-payment table rows, "7 days late" tags |
| Warning surface (dark red-brown bg) | `#332b2b` | icon chip background behind overdue/penalty icons |
| Neutral border / ring (low emphasis) | `rgba(233,233,237,.16)` | default unselected input/card outline |
| Divider line | `rgba(233,233,237,.07)` to `.12` | row separators (`.row` box-shadow inset), section rules |
| Faint divider | `rgba(233,233,237,.09)` | border-top on sticky footer / tab bar |
| **Cross-reference to known repo tokens** (`styles.css`, not literally present in canvas but consistent with it): `--color-bg:#161826`, `--color-surface:#232532`, `--color-text:#e9e9ed`, `--color-accent:#9184d9`, `--color-accent-2:#a7a1db`, `--color-divider:` `#e9e9ed` @ 16% alpha, plus `neutral-100..900` and `accent-100..900` tonal ramps, `--radius-sm:4px / md:8px / lg:14px`, `--space-1..8`. The canvas's inline hex values above map onto that ramp (e.g. `#75798c`≈neutral-500/600, `#9397ab`≈neutral-400, `#b2b6ca`≈neutral-300, `#423a6a`/`#2b2741`/`#5d5294`/`#796cbf`≈accent-800/900/700/600 in a dark-first ramp). |

### 1.3 Typography

- **UI/Latin text:** Inter (`Inter, system-ui, sans-serif`), weights 400 (body), 500 (emphasis/headings/buttons), and occasionally 600 (email-preview mock only).
- **Nepali/Devanagari text:** `"Noto Sans Devanagari"` loaded via Google Fonts (`family=Noto+Sans+Devanagari:wght@400;500;600`), always applied through a dedicated CSS class:
  - **`.np`** — the single most important, most-repeated class in the whole file. Applied to *every* Devanagari string, almost always as a smaller, greyer line directly beneath (or after, separated by `·`) its English counterpart. Typical pattern: `<div>English Label</div><div class="np" style="font-size:12.5px;color:#9397ab">नेपाली अनुवाद</div>`.
  - **`.sub`** — a very similar helper class (`font-family:"Noto Sans Devanagari"...font-size:11px;color:#9397ab;margin-top:2px`) seen in the base stylesheet, functionally overlapping with inline `.np` usage.
- **Type scale actually used** (px, observed across all screens): 8.5, 9, 9.5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15, 16, 17, 18, 19, 22, 24, 26, 27, 29, 31, 32, 33, 34, 36. In practice this collapses to a coherent scale of roughly: **9 / 10 / 11 / 12 / 13 / 14 / 15 / 17 / 19 / 22 / 26–36 (hero numerals)**.
- **Turn 4's explicit type-scale correction (important — treat as canon):** Turn 4's subtitle states outright: *"body copy is 13–15px rather than 11–12px and every button clears 48px, because a fund like this has members in their sixties reading on a cheap phone in daylight."* This means **turns 1–3's screens (designed earlier) still use the smaller 11–12px body text** and were never visually retrofitted — the turn 4 "try next" note literally says *"carry the bigger type from turn 4 back into turns 2 and 3"*, meaning this retrofit was flagged but never executed in the canvas. **For the Flutter rebuild, use turn 4's larger scale (13–15px body, ≥48px tappable height) as the actual target for every screen, including the ones visually shown smaller in turns 1–3.**
- Letter-spacing: kicker/eyebrow labels use `letter-spacing:.11em` with `text-transform:uppercase` at ~9–11px (class `.k` = `font-size:9.5px;letter-spacing:.11em;text-transform:uppercase;color:#9184d9`).
- Numerals: large monetary figures use `letter-spacing:-.02em` for a tighter, denser look at big sizes (29–36px).

### 1.4 Spacing, radius, elevation

- **Radius scale** observed: 3–4px (tiny chips/bars), 6–7px (small chips, mini bar-chart cells), 8–9px (standard cards/buttons/inputs — this is the dominant "md" radius), 10px (emphasized cards, upload dropzones), 12px (hero/highlight cards), 14px (largest hero cards, e.g. home screen balance card, "Loans" hero card). This matches the known `--radius-sm:4px / md:8px / lg:14px` scale with a couple of in-between values (9–10–12px) used for visual hierarchy between plain cards and hero cards.
- **Spacing**: paddings cluster around 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20px; gaps between stacked elements commonly 8–14px; screen-edge padding is `16–20px` horizontal. This is consistent with a ~4px base spacing unit (`--space-1..8` ≈ 4,8,12,16,20,24,28,32) with several "half-step" 2px nudges layered on for optical alignment (very common in this file, e.g. `13px`, `11px`, `9px`).
- **Elevation/borders**: this design does not use drop shadows for elevation — it uses **1–2px inset `box-shadow` rings** instead (`box-shadow: inset 0 0 0 1px rgba(233,233,237,.16)` for a neutral card outline, `inset 0 0 0 2px #9184d9` for a *selected* state, `inset 0 0 0 1px #423a6a` for an accent-tinted highlighted card). Row separators inside a grouped list use `box-shadow: inset 0 -1px 0 rgba(233,233,237,.07)` on every row except the last.
- Bottom sheets/sticky footers get a hard `border-top:1px solid rgba(233,233,237,.09)` plus a background one step darker than the body (`#1b1d2a`).

---

## 2. Component patterns (reusable classes and repeated inline patterns)

### Defined in `<style>` (real CSS classes)
- **`.hd`** — screen header bar: `padding:6px 16px 12px` (or `8px 16px 10-12px`), `display:flex; align-items:center; gap:10px`. Contains, in order: an optional 32×32 back-chevron icon button (SVG `‹`), a flex:1 title block (large title + `.np` Nepali subtitle beneath, OR a small `.np`/kicker line above a big title), and optionally a trailing icon button or step counter ("2 of 3") or status tag.
- **`.tb`** — bottom tab bar: `display:flex; background:#1b1d2a; border-top:1px solid rgba(233,233,237,.09); padding:7px 4px 3px`. Contains 4–5 **`.tbi`** items (`flex:1; flex-direction:column; align-items:center; gap:3px; font-size:9px; color:#9397ab`), each an SVG icon (19×19, stroke `currentColor`, stroke-width 1.7) + label. Active tab gets class **`.tbi.on`** → `color:#9184d9`.
  - **Member tab bar (5 tabs):** Home · Ledger · Give · Loans · Members.
  - **Admin tab bar (5 tabs):** Dashboard · Members · Loans · Fund · More.
- **`.scr`** — the whole-screen flex column container (`height:100%; overflow:hidden; display:flex; flex-direction:column; background:#161826`).
- **`.body`** — the scrollable content region: `flex:1; overflow-y:auto; overflow-x:hidden; scrollbar-width:none; padding:0 16px 8px; display:flex; flex-direction:column; gap:11px` (gap varies 8–14px per screen).
- **`.k`** — kicker/eyebrow label: `font-size:9.5px; letter-spacing:.11em; text-transform:uppercase; color:#9184d9`.
- **`.cd`** — plain card: `border-radius:8px; background:#232532; padding:13px` (padding often overridden to 14px).
- **`.row`** — a list row with a bottom hairline: `display:flex; align-items:center; gap:10px; padding:10px 12px; box-shadow: inset 0 -1px 0 rgba(233,233,237,.07)` (last row in a group drops the shadow via `box-shadow:none`).
- **`.mut`** — muted caption text: `font-size:10.5px; color:#75798c; margin-top:2px`.
- **`.av`** — circular avatar-with-initials: `border-radius:50%; background:#2b2741; color:#d2cefd; display:flex; align-items:center; justify-content:center; font-weight:500`, sized 26–40px depending on context (list row = ~26-34px, header/profile = ~36-40px). Always shows two-letter initials (e.g. "SK", "RA", "BT").
- **`.np`** — Nepali/Devanagari sub-line, see §1.3.
- **`.sub`** — near-duplicate of `.np` for Nepali secondary text, `color:#9397ab; font-size:11px`.
- **`btn` family** (referenced, defined in the external stylesheet, used everywhere): `.btn`, `.btn-primary` (solid accent-purple fill, dark text, used for the one dominant action), `.btn-secondary` (outlined/ghost, used for the secondary of a 2-button pair), `.btn-block` (full width), plus implied `.btn-ghost` / `.btn-icon` per the repo's known component set (not directly exercised with those exact class names in this canvas, but the visual patterns — icon-only header buttons, text-only ghost links like "Copy", "See all", "Clear" — are the same component family).
- **`.tag` family** — pill/chip labels, `padding:5px 11-12px, border-radius: pill`. Variants seen: **`.tag-accent`** (solid purple bg, dark text — used for positive/active/"On"/"Ahead"/"In ledger"/"Current" states), **`.tag-outline`** (outlined ring, no fill — used for "Pending", "Admin", "Review", "Behind"), **`.tag-neutral`** (flat grey — used for inactive choices, amount presets, "Resend", "Off", counts).
- **`.field`** — form field wrapper: a `<label>` (with optional `.np` inline translation) above an **`.input`** box.
- **`.input`** — text/value display box: `min-height:44-52px` (48px is the standard per turn-4's accessibility note), `border-radius` ~8-9px, background `#1e2030`, often with `box-shadow: inset 0 0 0 1px rgba(233,233,237,.16)` (neutral) or `inset 0 0 0 2px #9184d9` (focused/active) or a simple `border-bottom:1px solid #9184d9` (large numeric amount entry fields, e.g. Give/loan-amount screens).
- **`.radio`** — custom radio row: `<label class="radio"><input type="radio">` + **`.dot`** (custom circular indicator, 20×20px) + label content (often itself containing an `.av` + two-line name/role, or a two-line title+description).
- **`.dv-*` classes** (`dv-turn`, `dv-thd`, `dv-tid`, `dv-tname`, `dv-tsub`, `dv-opts`, `dv-opt`, `dv-oid`, `dv-olabel`, `dv-next`) — these are the **canvas/transcript scaffolding only** (turn headers, option ID chips, cross-reference links like `href="#6a"`). They are not part of the app UI and should be ignored for the Flutter rebuild — I mention them here only because they're how the "chosen vs alternate" analysis in §4/§5 was derived.

### Repeated bespoke inline patterns (not named classes, but consistent enough to be de-facto components)

1. **Bilingual label pattern** — English label, then either (a) an inline `<span class="np" style="color:#75798c">· नेपाली</span>` suffix on the same line, or (b) a full second `<div class="np">` line beneath at ~85-90% of the English font size and using one of the muted greys. This appears on **almost every single label, button, and section heading in the app** — it is the single most cross-cutting requirement in the whole design (see §6).
2. **Status/stage pills** — small pill badges for lifecycle states: `Pending` (outline), `In ledger` / `Verified` / `Current` / `Ahead` / `On` (solid accent), `Behind` / `Resend` / `Off` (neutral grey), `Admin` / `Review` / `Treasurer` (outline). Color-coding is consistent: **accent-solid = good/complete/on-track**, **outline = needs attention/waiting**, **neutral grey = informational/inactive/off**, **warm terracotta = danger/overdue/penalty**.
3. **Progress / stepper indicators** — two flavors:
   - **Wizard step counter**: plain text top-right of the header, e.g. "2 of 3", or a 3-segment thin bar (`height:3px` rounded rects) with completed segments in `#5d5294` and the current segment in `#9184d9`.
   - **Process stepper (timeline)**: horizontal row of circles connected by lines — filled circle + checkmark = done, ringed circle with center dot = current, plain ringed circle = pending — used for payment-verification lifecycle ("Paid to the fund → Matched to statement → In the ledger", screen `5c`).
4. **Progress/allocation bars** — a full-width rounded-rect track (`background:#292b31`) with a fill (`background:#9184d9` current-focus item, `#5d5294` past/other items) — used for interest-growth-over-time bars (turn 6), fund in-hand-vs-lent split, loan repayment progress.
5. **Bar charts** — vertical bars in a flex row, heights set via inline `%`, colored on a gradient from dim (`#5d5294`) to bright (`#9184d9`) to indicate "closer to now / more relevant" — used for "collected each month" (admin dashboard) and "repaying monthly" projection (turn 6).
6. **Month-grid heatmap** — a `repeat(4,1fr)` or `repeat(6,1fr)` CSS grid of small rounded rectangles, one per Nepali calendar month (3-letter abbreviations: Bai, Jes, Asa, Shr, Bha, Asw, Kar, Man, Pou, Mag, Fal, Cha), color-coded: solid dim purple = already covered (past), bright purple = covered by *this* payment/selection, dark inset box with "gap"/"—" = uncovered, plain dark = future/not-yet-due. This exact component appears on the **Home** screen, the **Give** screen, and the **My Record** screen — it is the core "which months have you paid" visualization for the fund's open-ended (not fixed-installment) contribution model.
7. **Empty/waiting state notice card** — a rounded card with an info/circle-i icon at left and two lines of text at right (title + explanation, sometimes with a `.np` third line) — used for "this is not counted yet," "the treasurer approves new members," "you are the proof here," etc. Visually: `background:#1e2030` or `#232532`, sometimes with an accent inset ring `box-shadow: inset 0 0 0 1px #423a6a`.
8. **Rate/penalty escalation table** — a CSS-grid table (no `<table>` tag, div-grid instead) with an uppercase 4-column header row (`Time/Elapsed`, `Rate`, `Total`, `Interest`/`You owe`) and striped data rows, the last 1-2 rows colored terracotta (`#d2a08a`) once the penalty compounds past a implicit "danger" threshold. Reused near-verbatim in three places: `6b`, `4c`, and referenced again in `2h`'s summary row.
9. **"What changed" audit-line pattern** — `Actor name · date · "reason in quotes"` as a `.mut`-style caption under any admin-editable value — this is the UI expression of the audit-trail requirement (§39/§44 referenced in turn 3's subtitle).
10. **Struck-through original + nested correction** — for corrected ledger entries: the original line is shown with `text-decoration:line-through` and dimmed opacity, followed by an indented sub-row (small vertical connector line) showing the corrected amount, the reason, who corrected it, and when. Corrections never delete/replace history — see screen `2d`.

---

## 3. Every screen, turn by turn

Legend: **[CANON]** = carried forward / treated as the real design. **[ALTERNATE — REJECTED]** = a competing direction that was NOT chosen. **[ADDITIVE]** = not a competing alternative at all — this turn's lettered options are all different screens that all belong in the final app.

### Turn 6 — "What a loan actually costs — shown, not stated" [ADDITIVE — both screens are sequential steps of one flow, not alternatives]

Both screens live *inside* the loan-request wizard, before the borrower accepts terms, and reference "Rule 16" from turn 4b directly.

**`6a` — "What it will cost" (loan cost calculator, on-time case)** — step "2 of 3" of the loan request.
- Header: back-chevron, title "What it will cost" / np "कति लाग्छ?", step indicator "2 of 3".
- Amount-selection card carried over from the request step: NPR amount entry (large numeral, shown at 50,000), quick-preset chips (10,000 / 25,000 / **50,000 selected** / 75,000), category toggle cards (**Personal — 1% a month, selected**) vs (Emergency — 0.5% a month), and a live eligibility note: *"Within your limit of NPR 93,735 — 30% of what the fund holds today."*
- Section header "Interest as time passes · समयअनुसार ब्याज".
- A vertical list of time-milestones, each with a progress bar (share of the 2-year max) and a "+delta" figure:
  - After 1 month → total 50,500 (+500)
  - After 1 quarter → total 51,500 (+1,500) — **highlighted** as "· due date" since a Personal loan's principal+interest is due at the 3-month mark; includes explanatory line "A personal loan is due here — principal and interest, three months from the day the money reaches you."
  - After 6 months → 53,000 (+3,000)
  - After 1 year → 56,000 (+6,000)
  - After 2 years → 62,000 (+12,000)
  - Explanatory copy: "Interest is 1% of the NPR 50,000 every month — NPR 500 — whether you deposit it monthly or at the end of the quarter." + Nepali equivalent.
- Second card: "If you paid it back monthly instead" — a 9-bar declining bar chart (bars 1–9, heights 100%→12%, colors dimming from `#5d5294` to `#9184d9`) with copy: *"Repaying NPR 5,600 a month clears it in nine months and the interest falls each month as the balance drops. Ask the committee for this if a single quarter is too tight."*
- Sticky footer: "Due in one quarter → NPR 51,500" summary + primary button **"See the late-payment cost"** (→ leads to `6b`).

**`6b` — "If the interest is late" (penalty/default cost calculator)** — step "3 of 3".
- Header: "If the interest is late" / np "ब्याज ढिलो भएमा", "3 of 3".
- Warning-styled info card (terracotta-tinted): *"The penalty grows, it does not sit still — Miss a payment date and 1.5% a month is added on the whole NPR 50,000, counted from the day you got the money. Miss the next one and another 1.5% is added on top."*
- Bar visualization: milestones at 3/6/9/12/15/18 months, each showing cumulative interest owed on the NPR 50,000 principal, with a vertical reference line marking "= the 50,000 you borrowed" at 65.4% width (i.e., interest reaches the size of the principal itself around month ~15-16):
  - 3 mo (on time) → 1,500 · 6 mo → 7,500 · 9 mo → 18,000 · 1 yr → 33,000 · **15 mo → 52,500** (now exceeds principal, colored terracotta) · **18 mo → 76,500** (terracotta).
  - Copy: *"Past fifteen months the interest is larger than the loan. At eighteen you would owe NPR 1,26,500 in total on NPR 50,000 borrowed."*
- "The same thing as your rule table" — a literal rate-escalation table (Time / Rate / Total% / Interest NPR) matching Rule 16's compounding formula: 3mo=12% (3% partial)=1,500; 6mo=12%+18%=15%=7,500; 9mo=12%+36%=36%=18,000; 12mo=12%+54%=66%=33,000; **15mo=12%+72%=84%+21%=52,500** (terracotta); **18mo=12%+90%=102%+51%=76,500** (terracotta).
- "How to avoid all of it" checklist (3 items): deposit NPR 500/month (app reminds 7 days before) · or NPR 1,500/quarter (term 15 allows either) · tell the committee before a missed date ("No penalty has ever been charged to someone who asked first").
- Sticky footer: "Paying on time costs → NPR 1,500" + primary button **"I understand — continue"**.

### Turn 5 — "Adding money — proof, approval, then public" [ADDITIVE — 5 distinct screens/states, not competing alternatives]

Establishes the core business rule: **all money goes into the fund's own eSewa (`9841••••21`) / Nabil Bank (`0201017500924`) account under the name "Hamro Kosh" — never any individual member's account** — and **two admins are required to move money out**.

**`5a` — "Confirm your payment" (digital transfer state)** — step "2 of 2" of Give flow.
- Header: "Confirm your payment" / np "भुक्तानी पुष्टि".
- Summary strip: "You are adding NPR 2,500" / "5 months · Asar–Mangsir".
- Fund account card: name "Hamro Kosh" + "Copy" action, `eSewa 9841••••21`, `Nabil Bank · 0201017500924`, note: *"The account belongs to the fund, not to any member. Two admins are needed to move money out of it."*
- Method tabs: **eSewa (selected)** / Bank / Cash to admin.
- Fields (both marked "· needed" for digital methods): Date paid (date picker, Nepali calendar e.g. "2 Bhadra 2083"), **eSewa transaction number** (e.g. "0BX7QK41"), **Screenshot of the payment** (file preview card with Replace/Remove, plus Gallery/Camera pickers).
- Notice card: "This is not counted yet — The money is already in the fund's account. It counts towards your months once an admin has matched it to the statement — until then it shows as waiting, to you and to everyone." + np line.
- Footer button: **"Submit for approval"**.

**`5b` — "Confirm your payment" (cash-to-admin state)** — same screen as 5a, different method selected; this is the state when **"Cash to admin"** tab is active.
- Summary strip differs: "You are adding NPR 750" / "1 quarter · Aswin–Mangsir".
- No screenshot/reference fields. Instead: notice "No screenshot needed — You handed the notes to an admin... They deposit the cash... and confirm it here. Just tell us which admin."
- **"Which admin did you hand it to?"** — radio list of admins, each row = avatar + name + role: Ramesh Adhikari (Treasurer, selected default), Sunita Shrestha (Secretary), Deepak Rai (Admin · committee member). Copy: "Only admins may take cash."
- Field: "When" — e.g. "At the Bhadra meeting, 2 Bhadra".
- Optional dashed-border upload: "Photo of the written receipt — Optional — only if you were given one."
- Explainer: "Ramesh gets a note asking him to confirm he took NPR 750 and banked it. Once he does, it is in the ledger with both your names against it."
- Footer button: **"Send to Ramesh to confirm"** (button label is dynamic to the chosen admin).

**`5c` — "My contributions" (member-facing payment-status screen)**
- Header: avatar "SK" + "My contributions" / np "मेरो योगदान".
- Hero card, accent-ringed: "Waiting for approval" kicker, NPR 2,500, `Pending` outline tag. **3-stage stepper**: Paid to the fund (done) → Matched to statement (current) → In the ledger (pending). Copy: "Paid into the Hamro Kosh account 20 minutes ago. An admin matches it against the account statement, usually the same day." Buttons: "View proof" / "Cancel".
- "Counted so far" card: NPR 27,500 "covered to Poush" (approved only) with a note "NPR 30,000 once the waiting payment clears, and covered to Mangsir" (i.e. shows what balance *will* be once pending clears).
- "All my payments" list — 4 example rows showing every lifecycle state: **Pending** (2,500, eSewa+screenshot), **In ledger** (500, TX-4796, approved by Ramesh), **Resend** (1,000, "Returned — the screenshot was unreadable" — a rejected payment, shown in neutral tag not as a penalty), **In ledger** (1,000, cash to Ramesh, banked later).
- Closing note: "A returned payment is not a mark against you — send a clearer screenshot and it goes back in the queue."
- Bottom tab bar active on **Give**.

**`5d` — "Check the payment" (admin single-item review/detail)**
- Header: "Check the payment" · "1 of 3 waiting · NPR 6,300".
- Member row: avatar + name (Sabin Karki) + trust signal "14 payments, none ever queried" + claimed amount (2,500).
- Large tappable screenshot placeholder ("tap to enlarge" / "Open full size"), uploaded timestamp.
- **3-point checklist** ("Check these three · तीन कुरा जाँच्नुहोस्"): ✓ "The amount matches" (screenshot reads NPR 2,500), ✓ "0BX7QK41 is in the Hamro Kosh statement" (credited timestamp shown), ☐ "The months are right" (Asar gap + Bhadra–Mangsir at 500 each, unchecked/pending in this example).
- Consequence-of-approval note: "Approving records it as TX-4821, adds NPR 2,500 to the fund's counted balance, emails him a receipt, moves his covered-to date to Mangsir, and puts the entry in the public ledger under your name."
- "If you send it back" — reason chips (required if rejecting): Screenshot unclear / Amount differs / Not in the fund's account / Wrong months.
- Footer: "Send back" (secondary) / **"Approve · स्वीकृत"** (primary).

**`5e` — "Record a payment" (admin manual/no-proof entry)**
- For: cash handed directly to an admin, OR back-filling an older cash-book entry.
- Notice: "You are the proof here — Notes taken in your hand, or a payment already in the cash book, need no screenshot. The entry goes straight into the ledger with your name on it — you then bank the cash into the Hamro Kosh account."
- "Why no proof" radio (3 reasons): Member handed me the cash / Already recorded in the cash book / Taken at a committee meeting.
- Field: Which member (avatar-picker, e.g. "Kamala Maharjan").
- Fields: Amount (NPR 1,800), Date received (28 Shrawan).
- "Which months it settles" — auto-filled 4-month grid (Jestha/Asar/Shrawan filled solid accent = 600 each; Bhadra greyed = not covered), with note "Clears her three months of arrears. She was the furthest behind in the group."
- **Required** field: "Note for the audit trail" (free text, e.g. "Cash taken at the Shrawan meeting, counted in front of Sunita.").
- Transparency note: "This appears in the public ledger straight away, marked no proof — recorded by Ramesh Adhikari, so any member can see how it was confirmed and ask about it."
- Footer: **"Record NPR 1,800 in the ledger"**.

### Turn 4 — "Your real terms, bilingual, plus the missing flows" [ADDITIVE — 6 distinct screens]

This turn's subtitle establishes 3 cross-cutting rules that retroactively govern the whole app: (1) the group's **actual** bylaws replace earlier placeholder numbers; (2) **every screen is bilingual**, EN leading with NE beneath, with a language toggle in onboarding; (3) **type/target sizes increase** (13–15px body, ≥48px buttons) for readability by older members on cheap phones.

**`4a` — Joining / registration screen**
- Logo/brand block: shield-check icon, "Hamro Kosh" / np "हाम्रो कोष".
- Tagline: "A fund we build together, and anyone in it can see every rupee." + np translation.
- **"Choose your language · भाषा"** — two cards, English (selected, "Nepali shown below") / नेपाली ("English shown below") — this is the one-time toggle for which language leads throughout the rest of the app.
- Fields: **Full name** (पूरा नाम) — e.g. "Sabin Karki"; **Mobile number** (मोबाइल नम्बर) — `+977` prefix, masked `98•• ••• •••`; **Invite code from your committee** (निमन्त्रणा कोड) — e.g. "KOSH-4A7", letter-spaced input.
- Notice: "The treasurer approves new members — You will get a message once you are in — usually the same day. Nothing is asked of you before then."
- Footer: primary button **"Continue · जारी राख्नुहोस्"**, plus text link **"Already a member? Sign in"** (no destination screen designed — see headline finding above).
- **This is the only registration/account-creation screen in the entire design.**

**`4b` — Terms and conditions (all 16 numbered bylaws, bilingual, grouped)**
- Header: "Terms and conditions" / np "नियम र सर्तहरू".
- Framing line: "This is a non-profit fund." / "यो नाफारहित कोष हो।"
- **Depositing** section (rules 1,2,3,7):
  1. The fund will be deposited monthly.
  2. Minimum monthly amount should be **NPR 250**.
  3. Amount should be deposited monthly **or** quarterly.
  7. Any deposit on a special occasion (birthdays, anniversaries) is appreciated (voluntary/bonus).
- **Using the fund** section (rules 4,5,6):
  4. Fund health should be reviewed quarterly.
  5. The deposited amount should be utilized based on members' alignment/agreement.
  6. This will be a non-profit fund.
- **Borrowing** section (rules 8–14):
  8. Fund members can take a loan from the fund.
  9. Max **2 members** can hold a loan at a time; no new loan disbursed while 2 are outstanding.
  10. A loan can be taken under different categories.
  11. **Personal** — up to **30%** of the amount remaining in the fund; principal + interest due **within the quarter** from disbursement date.
  12. Personal interest rate: **1% monthly, 12% per annum**, on the principal.
  13. **Emergency** — up to **80%** of the amount remaining in the fund, for medical/accidental emergencies only; repay within **1–2 quarters** from disbursement.
  14. Emergency interest rate: **0.5% monthly, 6% per annum**, on the principal.
- **Interest and penalty** section (rules 15,16):
  15. Interest should be deposited monthly or quarterly, based on availability.
  16. If interest is not paid in time, an additional **1.5% monthly penalty interest** is added to the principal from the disbursement date; if still unpaid at the next payment date, the rate increases by a further 1.5% (compounding).
- Cross-reference card: "See what a loan would cost you — Rule 16 is the one members misjudge. Step your own amount through a month, a quarter, a year and two years in 6a, then see the late case in 6b." (explicit forward-reference, confirming turn 6 exists specifically to visualize this rule).
- Footer: required checkbox "I have read and accept these terms" (+ np) → **"Accept · स्वीकार गर्नुहोस्"**.

**`4c` — Loan category selection (step "1 of 3" of loan request)**
- Header: "Request a loan" / np "ऋण अनुरोध", "1 of 3".
- Slot-availability notice: "1 of 2 loan slots is free — Bikash Tamang holds the other. Two loans running means no new loan can be given until one closes."
- Category cards (radio-select), each showing live figures against the current fund balance:
  - **Personal (selected)**: "You can borrow up to 93,735 (30% of the fund)"; "Interest 1%/mo (12%/yr)"; "Principal and interest are due within the quarter from the day the money reaches you."
  - **Emergency**: "You can borrow up to 2,49,960 (80% of the fund)"; "Interest 0.5%/mo (6%/yr)"; "For medical and accidental emergencies only. Repay within 1 to 2 quarters. The committee may ask for documents."
- "If interest is late" preview card — the same rate-escalation table pattern as `6b`, worked on a round NPR 1,000 example (3mo=30 · 6mo=150 · 9mo=360 · 12mo=660 · 15mo=1,050(terracotta) · 18mo=1,530(terracotta)).
- Footer: **"Continue with Personal"** (button label reflects selected category).

**`4d` — Member management (admin)**
- Header: "Members" / np "सदस्य व्यवस्थापन · 24 active" + an "add" icon button.
- "Waiting for approval" card (count: 2): each pending joiner shown with avatar, name, "Invited by [X] · code [KOSH-4A7] · [when]" (or "No invite code — needs checking" for an anomalous case), Reject/Approve buttons.
- Filter chips: All 24 / Behind 5 / Borrowing 2 / Inactive 1.
- Member list rows (avatar, name, "given amount · status detail", trailing tag): shows Admin tag (Ramesh, Sunita), Current tag (Bikash — borrowing 38,600), Behind tag (Nirmala — 2 months behind; Kamala — 3 months behind), and a dimmed **Inactive** row (Gita Sharma — "Left the group Falgun 2082 · records kept").
- "Nudging the five who are behind" card: "A reminder goes out in the member's own language, with the exact months and amount owed. Nothing is charged for being behind — up to six months is allowed." → button "Send reminders to 5 members".
- Footer note: "A member who leaves is made inactive, never deleted — their contributions and loans stay in the ledger and the reports."
- Admin tab bar, active on **Members**.

**`4e` — "Something looks wrong" (member dispute/query screen)**
- Header: "Something looks wrong" / np "केही मिलेको छैन?".
- Intro: "Tell us which entry you are asking about. The treasurer must reply, and their reply stays visible to you."
- "The entry" card: the specific ledger line being disputed (e.g. "NPR 1,000 · Shrawan · TX-4720 · recorded 2 Bhadra") with a "Change" link to pick a different entry — **the dispute is always attached to a specific transaction, never freeform.**
- "What is wrong" radio (5 options): The amount is not right / The months it covers are wrong / I did not make this payment / My loan balance looks wrong / Something else — each bilingual.
- Free-text field: "In your own words" (e.g. "I paid 1,500 by eSewa on 2 Bhadra but only 1,000 is showing.").
- Optional screenshot attach.
- "Your earlier queries" history list, showing prior disputes with resolution and admin's literal reply text, e.g. Ramesh: *"You were right — the tent was NPR 400 less. Corrected on 30 Shrawan, both records are in the ledger."* (tags: Resolved / Closed).
- Footer: **"Send to the treasurer"** + note "You will get a reply within 3 days" (implying an SLA).

**`4f` — Email templates (admin)**
- List of transactional email types with usage stats and on/off state: Contribution received (editing, "sent 19 times this month"), Loan approved ("with the full terms attached"), Interest due in 7 days ("names the 1.5% penalty"), Fund money used ("to everyone, whenever money leaves"), Quarterly fund health ("Rule 4 · sent on the quarter's last day") — all shown as toggled **On**.
- Template editor for "Contribution received": EN/NE language tab toggle, Subject field ("Thank you — NPR {amount} received"), Body field with merge-tag placeholders: `{name}`, `{amount}`, `{months}`, `{covered_to}`, `{tx_id}`, `{fund_balance}`.
- Live preview of the rendered email as the member would receive it (light "email client" card — the design's one deliberate light-theme exception): brand header, subject, bilingual body, then a receipt-style detail block: Transaction (TX-4821), Method (eSewa), Verified by (Ramesh Adhikari), Your total given (NPR 30,000), Fund now holds (NPR 3,14,950), plus a closing line "You can check this entry against the ledger in the app at any time. Reply to this email if anything looks wrong."
- Footer note: "Receipts, loan letters and overdue notices cannot be switched off — they are the member's record. Notices and the quarterly summary can." (i.e. some emails are mandatory/non-optional).
- Footer buttons: "Send a test" (secondary) / **"Save template"** (primary).

### Turn 3 — "Admin — the treasurer's side" [ADDITIVE — 4 distinct admin screens]

Establishes: admin's home question is "what is waiting on me" (not the balance), and every admin action must write an audit line (old value, new value, reason) per §39/§44.

**`3a` — Admin dashboard**
- Header: "Treasurer view" kicker + name "Ramesh Adhikari" + settings-gear icon button.
- **"Waiting on you"** hero card (6 items): 2 loan requests (NPR 50,000 and 15,000, oldest 3 days), 3 payments to verify (NPR 6,300 total, screenshots attached), 1 overdue instalment (Prakash Thapa, 7 days past grace) — each a tappable row with chevron.
- 2×2 stat grid: In hand 3,12,450 · Out on loan 1,73,750 · Members 24 (5 behind, 1 pending) · This month in 18,900 (19 of 24 paid).
- "Collected each month" bar chart, last 8 months (Nepali month abbreviations), with callout: "Shrawan was high because six members paid several months ahead."
- "Recent admin activity" log (audit trail preview): "Loan approved — Bikash Tamang, 40,000 (You · 2 Bhadra, 11:04 am)"; "Expense corrected — Teej, 9,800 → 9,400 (You · 30 Shrawan · reason recorded)"; "Minimum contribution 200 → 250 (Sunita Shrestha · 1 Baisakh · agreed at AGM)".
- Admin tab bar, active on **Dashboard**.

**`3b` — Reviewing a loan request (admin decision screen)**
- Header: "Loan request" · "LR-0042 · 3 days waiting", tag "Review".
- Borrower card: avatar, name (Sunita Shrestha), "Member since Baisakh 2081 · never borrowed", requested amount NPR 50,000 "over 12 months", stated purpose quote ("Shop rent and stock for the Dashain season. I will repay from the shop's takings and can manage NPR 4,500 a month."), tags "Business" / "2 documents".
- "Her record" mini-table: Given to the fund 31,500 · Months covered 26 of 26 · Paid ahead to Mangsir 2083 · Previous loans None · **Eligible for up to NPR 94,500**.
- "What approving does to the fund": before/after "in hand" figures (3,12,450 → 2,62,450), a segmented allocation bar, and the cap check: "Lending would rise to 46% of the fund. The rule the group set caps it at 60%." **(This 60% aggregate-lending cap is a distinct rule from the per-loan 30%/80% ceilings in rules 11/13 — it caps total fund exposure across all loans combined.)**
- "Terms you are setting" editable fields: Amount approved (50,000), Months (12), Interest %/yr (12), Method (**Reducing** — i.e. reducing-balance amortization), plus a required "Note for the audit trail" field.
- Note: "Needs a second admin's approval before the money moves. Sunita sees these terms and must accept them." — confirms **two-admin (dual-control) approval** for loan disbursement, and that acceptance (`2h`) happens after this approval.
- Footer: Reject / Ask more / **Approve** (3-button row).

**`3c` — Verifying payments (admin queue, list form of `5d`)**
- Header: "Verify payments" · "3 waiting · NPR 6,300".
- Three payment cards:
  - Deepak Rai — eSewa, TX-4823, NPR 3,000, screenshot preview, claimed months (Asar 500/Shrawan 500/Bhadra 1,000/Aswin 1,000 as accent chips), buttons Query/**Verify and record**.
  - Kamala Maharjan — Cash to treasurer, TX-4822, NPR 1,800, no screenshot ("cash was handed over at the Shrawan meeting. Clears 3 months of arrears."), claimed months chips (Jestha/Asar/Shrawan 600 each).
  - Nirmala Bhandari — Bank transfer, TX-4820, NPR 1,500, **flagged mismatch**: "The reference number does not match the bank statement. Worth a query before recording." (shown in terracotta warning color).
- Footer note: "Verifying writes the entry into the ledger, updates the member's covered months, sends them a receipt by email, and records your name against it."
- Admin tab bar, active on **Fund**.

**`3d` — Fund rules & audit trail (admin settings)**
- Header: "Fund rules" · "Every change is kept with its reason".
- **Contributions** group: Minimum a month = NPR 250 (changed by Sunita Shrestha, 1 Baisakh 2083, "agreed at AGM"); Paying ahead = Unlimited (unchanged since fund began); Arrears allowed = **6 months** (set by Ramesh Adhikari, 12 Shrawan 2082).
- **Lending** group: Personal loan (1% monthly/12% yr, repay within quarter) = up to 30%; Emergency loan (0.5% monthly/6% yr, repay 1–2 quarters) = up to 80%; Loans running at once = **2 maximum**; Late interest penalty = **+1.5%/mo** (on principal, from disbursement, compounding each missed date); Approvals needed = **2 admins** (set by Sunita Shrestha, 1 Baisakh 2083, "after the 2081 dispute" — implies a past incident motivated dual-control).
- **What members can see** group (visibility/privacy settings): Each other's contributions = **On**; Who is borrowing and how much = **On**; What a loan was for = **Off**; Phone numbers and email = **Member's choice**; Every expense, itemised = **On**.
- "Changing a rule" card: "A reason is required, and the old value stays in the audit trail. Members are told when a rule about their money changes." + button "Open the full audit trail" (implies a deeper, dedicated audit-log screen not itself mocked up).
- Admin tab bar, active on **More**.

### Turn 2 — "Member app — the rest of the screens, built on `1a`" [ADDITIVE — confirms `1a` is canon; 8 distinct member screens]

The turn title's `href="#1a"` is the explicit textual proof that **home screen option `1a` was the one carried forward**. Subtitle: 5 tabs (Home, Ledger, Give, Loans, Members) rather than "the nine sections in §52" of the underlying spec — Reports/Notifications/Terms live off the profile instead of being top-level tabs.

**`2a` — Members directory (member-facing, read-only)**
- Header: "Members" · "24 members · 19 current, 5 behind".
- Search bar, filter chips (All 24 / Current 19 / Behind 5 / Borrowing 4).
- Rows: avatar, name (with inline "treasurer" or "you" tag where relevant), "Given [amount] · covered to [month]" or "· [n] months behind", or "· borrowing"; trailing tag Ahead/Current/Behind.
- Example data: Ramesh Adhikari (treasurer, 34,000, covered to Chaitra, Ahead); Sunita Shrestha (31,500, Mangsir, Ahead); Sabin Karki (you, 27,500, Poush, borrowing, Ahead); Anita Gurung, Bikash Tamang (Current); Nirmala Bhandari, Prakash Thapa, Kamala Maharjan (Behind).
- Privacy note: "Phone numbers and email addresses are hidden — each member chooses whether to share them." (matches the `3d` visibility setting: "Member's choice").

**`2b` — Yearly report**
- Header: "Year report 2082" · "Baisakh 2082 — Chaitra 2082" + export icon.
- Closing balance hero: NPR 2,84,150, "Up NPR 1,02,000 on the year".
- **Money in** breakdown: Monthly contributions 2,46,000 · Festival collections 48,000 · Loan repayments 92,800 · Interest received 21,600 · **Total in 4,08,400**.
- **Money out** breakdown: Loans given 1,60,000 · Dashain and Tihar 62,400 · Emergency help — 3 families 38,000 · Welfare and gifts 19,800 · Running costs 8,400 · **Total out 2,88,600**.
- Reconciliation walk: Opening 1,82,150 + everything in 4,08,400 − everything out 2,88,600 − still on loan 17,800 = **Closing 2,84,150**.
- Footer: Download PDF / Email to me.

**`2c` — Notifications**
- Header: "Notifications" · "4 unread", "Mark all read" link.
- Filter chips: All / Money / Reminders / Notices.
- Feed items (unread = highlighted bg): instalment-due reminder (NPR 2,240 due in 3 days, "instalment 8 of 12," 7-day grace period mentioned); payment-verified confirmation (NPR 2,500, TX-4821, verified by Ramesh, receipt emailed); loan-disbursed notice (NPR 40,000 to Bikash Tamang, approved by two admins, new fund-in-hand figure shown); festival-collection notice (Dashain hamper, NPR 1,000/household, 17 of 24 paid, closing date); a read correction notice (Teej expense 9,800→9,400); a read monthly-statement notice (Shrawan: collected 24,500 · spent 9,400 · lent 0 · closing 2,89,950).
- Footer note: "You can switch off notices and monthly statements in settings. Reminders about your own money stay on." (matches `4f`'s "cannot be switched off" list).

**`2d` — Ledger**
- Header: "Ledger" · "486 entries · nothing ever removed" + filter icon.
- Segmented control: All / Money in / Money out.
- Summary card: Total in 6,82,100 · Total out 3,95,150 · In hand 3,12,450, with a 2-segment allocation bar and note "In hand = everything in, less everything spent, less what is still out on loan."
- Grouped-by-month list (e.g. "Bhadra 2083" section header), each entry showing icon, description, sub-detail (TX id / method), amount (+ green-ish accent for in, muted for out) and a status word (verified/disbursed).
- **Correction pattern demonstrated live**: an original entry ("Teej gathering — tent and food," −9,800, TX-4802) shown struck-through and dimmed, with a nested correction below it ("Corrected to −9,400... Tent hire was NPR 400 less than the quote. Changed by Ramesh Adhikari, 30 Shrawan.") — confirms **corrections never overwrite/delete, they append.**

**`2e` — Give (contribution flow, step 1)**
- Header: "Give to the fund".
- Large amount entry (NPR 2,500 shown) with preset chips: 250 / 750·quarter / **2,500 (selected)** / 3,000·year / Other.
- Note: "The floor is NPR 250 a month, set by the committee. Anything above it is welcome, and you may pay monthly or a whole quarter at once — ahead or in arrears."
- **"Which months does this cover?"** — 12-month grid (Baisakh…Chaitra), color states: dim-purple = already covered (Baisakh, Jestha, Shrawan), bright-purple = covered by *this* payment (Asar's gap + Bhadra/Aswin/Kartik/Mangsir), dark = not yet due (Poush onward). Legend: "Already covered" vs "This payment". Result line: "NPR 2,500 covers Asar's gap plus Bhadra through Mangsir. You will be paid up to Mangsir 2083."
- "How are you paying?" radio: eSewa — Hamro Kosh 9841••••21 (selected) / Bank transfer — Hamro Kosh, Nabil 0201… / Cash to an admin, who banks it.
- Optional screenshot dropzone.
- Footer: "5 months · Asar to Mangsir → NPR 2,500" + **"Send for verification"** (leads into `5a`/`5b` for the proof step).

**`2f` — My record (personal 2-year contribution history)**
- Header: avatar, name, "Member since Baisakh 2081," tag "Paid to Poush".
- Stat row: Given 27,500 · Payments 14 · Months 21/26.
- Two-year month-grid (2083 and 2082), color-coded solid/gap/advance exactly as in `2e`'s legend, with per-month amounts (mostly 500–1,000, with one advance block "3,000" for a multi-month single payment).
- "Every payment" list: NPR 500 Bhadra (eSewa, verified); NPR 1,000 Shrawan (cash, verified); NPR 2,000 Baisakh–Jestha (bank transfer, verified); NPR 1,000 "Dashain hamper 2082" (tag "Special" — a non-standard/festival collection, distinct from monthly contributions).

**`2g` — Loans (member-facing loan tab)**
- Header: "Loans" · "NPR 1,73,750 out with 4 members" (group-wide transparency figure shown even on the member's own tab).
- "Your loan" hero card: NPR 12,400 still to pay, tag "On track", progress bar (52%), "13,600 of 26,000 payable" / "7 of 12 instalments"; detail row Principal 25,000 / Interest 12%/yr / Method **Reducing**; "Next instalment NPR 2,240 · Due 15 Bhadra · 1,990 principal + 250 interest" + **Repay** button.
- "Repayment schedule" list (instalments 6–10 shown, "Show remaining 2" to expand) — each row shows principal/interest split changing over time (declining interest, growing principal — consistent with reducing-balance amortization) and paid/next/upcoming state.
- **"Request a new loan"** button, with eligibility note: **"You may borrow up to three times what you have given (NPR 82,500), once an existing loan is below half its principal."** — a distinct borrowing-limit rule (3× own total contributions) layered on top of the 30%/80%-of-fund-balance caps and the 2-concurrent-loans cap. *(Flag: this creates potential rule tension worth resolving with real stakeholders — see §7.)*
- "Where the group's money is lent" transparency list: Prakash Thapa (60,000 principal, 18mo, since Aswin 2082, balance 58,600, "7 days late"), Bikash Tamang (40,000, 12mo, balance 38,600, on track), Anita Gurung (35,000, 12mo, balance 14,150, on track), You (25,000, 12mo, balance 12,400, on track). Footer: "Amounts and repayment status are open to every member. What the money was for is not." (matches `3d`'s visibility rule).

**`2h` — Loan terms review & acceptance ("Step 3 of 3" — see flow-ordering note below)**
- Header: "Your loan terms" · "Step 3 of 3 · approved 4 Bhadra", 3-segment progress bar (all filled/near-filled).
- Hero card: "You will receive NPR 50,000" then "You will pay back NPR 53,250 (3,250 of it interest)" — "In 12 monthly instalments of about NPR 4,440, starting 15 Aswin 2083."
- Detail table: Category Personal · Interest rate 1%/mo, 12%/yr · Calculated on The principal · Repay by End of the quarter · Interest deposits Monthly or quarterly · Paying early Allowed, no charge · If interest is late **+1.5%/mo penalty**.
- "What the group agreed" card: "This loan comes out of money 24 members put in together. Your name, the amount and your repayment progress will be visible to every member in the ledger. What you are borrowing for stays between you and the committee." + link "Read the full terms and conditions" (→ `4b`).
- Required acceptance radio: "I have read these terms and I accept them. I will repay NPR 53,250 over 12 months."
- Footer: "Not now" (secondary) / **"Accept and receive"** (primary).
- **Flow-ordering note (implementer flag):** `4c`→`6a`→`6b` are explicitly labeled steps "1/2/3 of 3" of the *loan request* wizard (before committee review). `2h` is separately labeled "Step 3 of 3" but occurs logically *after* committee approval (`3b`) — its own 3-step counter almost certainly belongs to a **separate** short flow (e.g. "approved → review terms → accept," or is a pre-turn-6 artifact never renumbered after 6a/6b were inserted). Do not treat `2h`'s "3 of 3" as the same wizard as `4c`'s "1 of 3" — build them as two distinct step sequences: **Loan Request** (category → cost preview → late-cost warning → submit) and **Loan Acceptance** (single screen, shown once committee approves).

### Turn 1 — "Hamro Kosh — home screen, three directions" [3 REAL ALTERNATIVES — only one chosen]

Sample data used throughout (and inherited by all later turns): fund "Hamro Kosh," 24 members, current month Bhadra 2083, in-hand 3,12,450, lent-out 1,73,750, total fund position 4,86,200.

**`1a` — "Balance-first" [CANON — explicitly confirmed by turn 2's title `"...built on 1a"`]**
- Header: avatar, "Hamro Kosh" title, "Sabin Karki · member since 2081" caption, notification bell icon (with unread-dot badge).
- Hero card: kicker "Available right now," NPR 3,12,450 (huge numeral), caption "Matches 486 recorded entries · as of today, 4:20 pm," a 2-segment allocation bar (in-hand 64% vs lent-out 36%) with legend, and a footer row "Total fund position → NPR 4,86,200."
- 2×2 stat grid: Members have given 5,42,000 (24 members) · Spent by the group 1,28,600 (7 categories) · Interest earned 41,300 (since 2081) · Owed back to us 1,73,750 (4 borrowers).
- "You are covered to Poush" card: personal 12-month coverage bar (month grid, one gap at Asar) + "Asar is still open" note + minimum/frequency reminder + **Give** button.
- "Latest in the ledger" preview list (4 items) + "See all" link.
- Bottom tab bar (Home active): Home / Ledger / Give / Loans / Members.
- **This is the canonical home screen structure that all of turn 2's screens share (same header style, same tab bar, same card language).**

**`1b` — "Questions answered" [ALTERNATE — REJECTED]**
- Reframes the entire home screen as a literal FAQ: "How much can we spend today?", "How much have we all put in?", "How much have we spent?", "How much is lent out?", "How much interest have we earned?", "Who owes the fund money?" (a mini borrower list), "Where do I stand?" (personal balance + Give now/Fill Asar buttons), "What happened last?" (single latest activity item).
- Rationale given: turns the underlying spec's §54 question list directly into UI, "so nobody has to interpret a dashboard."
- Not referenced by any later turn — no forward link, no "built on" citation. Treated as rejected.

**`1c` — "Flow-first" (river/Sankey-style diagram) [ALTERNATE — REJECTED]**
- Visualizes contributions/repayments/interest/other as inbound "river" bars on the left and member-loans/festivals/emergency-help/welfare/admin-cost bars on the right, converging on a center balance figure (NPR 3,12,450 "what is left in hand" + 1,73,750 "due back").
- Includes a 12-month area/line sparkline ("The fund over a year," +1,02,000, with a callout "Dashain payout dipped it in Kartik") and a personal-contribution donut ("Your part in it," 78%, "You have given NPR 27,500 — 78% of the months since you joined... Asar is the one gap.").
- Explicitly framed by its own label as "heavier on graphics, lighter on figures" — a deliberately different philosophy from `1a`.
- Not referenced by any later turn. Treated as rejected. (Note for the rebuild: the *donut "% of months paid"* and *12-month trend sparkline* are genuinely nice supplementary widgets that could still be reused elsewhere, e.g. inside `2f` "My record" or `2b` "Yearly report," even though the overall home-screen direction was not chosen.)

---

## 4. Consolidated final screen list (deduplicated, with source option IDs)

### Onboarding
| Screen | Source(s) | Notes |
|---|---|---|
| Language + Join/Register | `4a` | Name, mobile (+977, masked), invite code (`KOSH-XXX` format); submits to treasurer for approval |
| Terms & Conditions (16 rules) | `4b` | Must be read/accepted; grouped Depositing / Using the fund / Borrowing / Interest & penalty |
| **Sign in — NOT DESIGNED** | (link only, in `4a`) | No screen exists. Needs to be designed/decided (password? OTP via the already-collected mobile number? magic link?). |

### Member app (5 tabs: Home · Ledger · Give · Loans · Members)
| Screen | Source(s) |
|---|---|
| Home / dashboard | `1a` (canon) |
| Ledger (all entries, filterable, corrections shown inline) | `2d` |
| Give — step 1 (amount + months + method) | `2e` |
| Give — step 2 (confirm w/ proof: digital) | `5a` |
| Give — step 2 (confirm w/ proof: cash-to-admin) | `5b` |
| My contributions / payment status tracker | `5c` |
| My record (2-year contribution grid + full history) | `2f` |
| Loans tab (active loan + schedule + transparency list) | `2g` |
| Loan request — step 1 (category choice) | `4c` |
| Loan request — step 2 (on-time cost calculator) | `6a` |
| Loan request — step 3 (late-payment cost calculator) | `6b` |
| Loan acceptance (terms review + sign) | `2h` |
| Members directory (read-only) | `2a` |
| Notifications centre | `2c` |
| Yearly report | `2b` |
| Dispute / "Something looks wrong" | `4e` |

### Admin app (5 tabs: Dashboard · Members · Loans · Fund · More)
| Screen | Source(s) |
|---|---|
| Admin dashboard ("waiting on you" queue + stats) | `3a` |
| Loan request review/approval | `3b` |
| Payment verification queue | `3c` |
| Payment verification detail (single item, expanded) | `5d` |
| Manual/no-proof payment entry | `5e` |
| Member management (approve joiners, roster, reminders) | `4d` |
| Fund rules & audit trail | `3d` |
| Email templates editor | `4f` |

### Rejected alternates (documented for reference, not to be built)
- `1b` — "Questions answered" home screen variant.
- `1c` — "Flow-first" river-diagram home screen variant (though its donut/sparkline widgets may be worth reusing elsewhere).

**Total distinct canonical screens: 24** (7 onboarding/loan-wizard steps + 12 member screens + 8 admin screens, with a few counted once each despite appearing as multi-step sequences — see table above for exact breakdown; two screens, `5a`/`5b`, are really one screen in two data-driven states, similarly `4c`/`6a`/`6b` are one 3-step wizard). Counting each Give/Loan-request step and each payment-proof state as its own screen (as a Flutter route likely would), the practical route count is **~28-30 individual screens/route-states**.

---

## 5. Cross-cutting requirement: bilingual EN/NE on nearly every screen

This is not a "nice to have" localization pass — it is baked into the layout of almost every element in the source file via the repeated `.np` pattern (see §2, pattern 1). Concretely, for the Flutter rebuild:
- Every label, section heading, button, and most body/explainer copy needs **two strings**: an English string and a Devanagari string, laid out as English-primary/Nepali-secondary (smaller, greyer, directly beneath or after a `·`).
- The **join screen (`4a`)** is the one place a user chooses which language leads; that choice should persist as a user preference/setting, and (per `4a`'s copy — "Nepali shown below" / "English shown below") the *non-primary* language never disappears, it just demotes to the secondary line. Build this as a first-class i18n architecture (e.g. always-visible dual-locale strings), not a simple locale-switch that hides one language.
- Nepali text must render in **Noto Sans Devanagari** (weights 400/500/600); English/Latin in **Inter**.
- Money amounts, dates, and Nepali calendar month names (Baisakh, Jestha, Asar, Shrawan, Bhadra, Aswin, Kartik, Mangsir, Poush, Magh, Falgun, Chaitra — and their 3-letter abbreviations Bai/Jes/Asa/Shr/Bha/Asw/Kar/Man/Pou/Mag/Fal/Cha) appear in **Bikram Sambat (BS)** dates throughout (e.g. "2 Bhadra 2083," "Baisakh 2082 — Chaitra 2082") — the app needs a BS calendar system, not just Gregorian, and should probably support BS↔AD conversion since the underlying platform/infra is presumably Gregorial.

---

## 6. Business-rule numbers embedded in the mockups (for data modeling — SRS.md remains the formal source of truth, but these are the concrete figures actually drawn)

- **Non-profit fund.**
- **Contribution:** minimum NPR 250/month (raised from an earlier NPR 200 per the audit-trail example — treat 250 as current canon); monthly or quarterly cadence, either is acceptable; no cap on paying ahead; **6 months of arrears allowed** before being flagged "Behind" (no charge/penalty for being behind, just a nudge/reminder); optional bonus/festival deposits are welcomed but not required (rule 7); a member may pay for multiple months (past gaps, current, or future) in a single transaction, and the payment form must let them select exactly which months a given amount covers.
- **Loan categories** (a member may hold loans in either category, subject to the 2-concurrent cap):
  - **Personal**: ceiling = 30% of "the amount remaining in the fund" (examples show this computed off the **cash-in-hand** figure, not total fund position — 93,735 ≈ 30% of 3,12,450); interest 1%/month = 12%/year on principal; principal+interest due **within one quarter (3 months)** of disbursement.
  - **Emergency**: ceiling = 80% of the amount remaining in the fund (for medical/accidental emergencies only, committee may request supporting documents); interest 0.5%/month = 6%/year; repay within **1–2 quarters** of disbursement.
- **Concurrency cap:** maximum **2 members** may hold a loan at the same time; no new loan disbursed while 2 are outstanding (a hard queue/slot system, not a soft warning).
- **Aggregate lending cap:** total money out on loan must not exceed **60%** of the fund (distinct from the per-loan 30%/80% ceilings — this caps the sum across all concurrent loans) — seen in `3b`'s "the rule the group set caps it at 60%."
- **Alternate/possibly-conflicting per-member cap:** a member "may borrow up to **three times** what they have given" (3× their own lifetime contributions), and only once any existing loan of theirs is **below half its principal** — seen in `2g`. *(This 3×-contributions rule and the 30%/80%-of-fund rule both appear as live copy in the mockups; it is not clear from the design alone whether both must be satisfied simultaneously (whichever is lower governs) or whether one supersedes the other. Flag this for confirmation with the actual committee/stakeholders before encoding into the loan-eligibility calculation.)*
- **Late-interest penalty (Rule 16):** if interest isn't paid on schedule, an additional **1.5% per month** penalty accrues on the **original principal**, counted from the **disbursement date** (not from the missed date) — and it **compounds**: each subsequent missed payment date adds another 1.5% on top. Worked table (on any principal P): 3mo→3%·P, 6mo→15%·P, 9mo→36%·P, 12mo→66%·P, 15mo→105%·P (84%+21%), 18mo→153%·P (102%+51%). Interest exceeds principal somewhere around month 15–16.
- **Interest calculation method:** "Reducing" (reducing-balance/declining-balance amortization) — explicitly labeled as a field value in both `3b` (admin sets terms) and `2g` (member's active loan detail).
- **Approvals:** **2 admins** required to approve/disburse a loan (dual control) — instituted "after the 2081 dispute" per the audit trail, i.e. this was a rule change with a specific incident motivating it. **2 admins** also required to move money **out of** the fund's own payment account (per `5a`'s copy) — likely the same dual-control rule applied at the banking layer.
- **The fund's own account model:** all money — whether contributions or loan repayments — is paid into **the fund's own accounts**, never an individual member's: `eSewa 9841••••21` and `Nabil Bank 0201017500924`, account name "Hamro Kosh." Loans are disbursed *from* this same account. This is fundamental to the data model: there is no concept of member-to-member transfer; every transaction is member↔fund.
- **Proof requirements are conditional on method:**
  - Digital (eSewa/bank transfer): **requires** a transaction reference number + a screenshot. Money is NOT counted toward the member's covered months until an admin matches the reference against the fund's own account statement.
  - Cash handed to an admin in person: **no screenshot required** — the receiving admin's identity IS the proof; only admins may accept cash; the admin must subsequently bank it and confirm the entry (a confirmation is sent to that named admin).
  - Admin-entered backfill (e.g. bringing an old cash-book entry into the app) or admin-witnessed cash: no proof required, but a **mandatory audit-trail note** is required, and the ledger entry is marked publicly "no proof — recorded by [admin name]" so it remains inspectable/challengeable by any member.
  - A rejected/returned payment is not penalized — it just goes back into the member's queue to resend with better evidence.
- **Reminders/notifications:** instalment-due reminder sent **7 days before** the due date; **7-day grace period** after a due date before something is marked "overdue" / "past grace"; quarterly fund-health summary sent automatically on the **last day of the quarter** (Rule 4). Certain notification types are mandatory and cannot be disabled by a member (receipts, loan letters, overdue notices); others (general notices, the quarterly statement) can be opted out of, but reminders about the member's *own* money always stay on.
- **Membership lifecycle:** treasurer approves new joiners (via invite code); a member who leaves is set **inactive**, never deleted — their historical contributions/loans remain visible in the ledger and reports.
- **Visibility/privacy matrix** (admin-configurable, defaults shown in `3d`): contributions visible to all members = On; who is borrowing & how much = On; what a loan is *for* = Off (private, committee-only); phone/email = each member's own choice; itemized expenses = On (full transparency on spending).
- **Audit trail is mandatory infrastructure, not optional:** every admin-mutable value (contribution minimum, loan terms, an expense correction, a visibility toggle) is stored with **actor, timestamp, old value, new value, and a required reason string** — this should be modeled as a first-class `audit_log` entity from the start, not bolted on later, since §39/§44 of the underlying spec apparently require it and the UI treats "the settings screen and the audit trail" as literally the same screen (`3d`).
- **Corrections never delete/overwrite ledger history** — a corrected entry keeps its original (struck-through) record visible, with the correction nested beneath it, carrying its own reason/actor/timestamp.

---

## 7. Summary for planning

- **24 canonical screens** across onboarding, a 5-tab member app, and a 5-tab admin app (roughly 28–30 if every wizard step/proof-state is counted as a separate route).
- **No login/authentication screen was designed.** Registration/invite-code join exists (`4a`); a "Sign in" text link exists but nothing behind it. This must be designed or explicitly deferred as a known gap before/while rebuilding.
- Everything is **dark theme only** (bg `#161826`), Inter + Noto Sans Devanagari, with a near-universal English-primary/Nepali-secondary bilingual label pattern that should be treated as core i18n architecture, not a late localization pass.
- The home screen direction (`1a`, balance-first) is explicitly confirmed as canon by turn 2's own title; the other two home-screen concepts (`1b` question-cards, `1c` flow/river-diagram) were explored and dropped, though a couple of their widgets (contribution-% donut, 12-month trend sparkline) are reusable ideas for secondary screens.
- Turn 4 quietly redefines the type scale upward (13–15px body, ≥48px targets) but this was never visually back-ported into turns 1–3's already-drawn screens — build to turn 4's scale everywhere.
- The lending business rules are rich and in a couple of places **internally inconsistent across mockups** (the 30%/80%-of-fund caps vs. the "3× your own contributions" cap in `2g`; the "quarter" repayment window in Rule 11 vs. 12–18 month installment schedules shown in example loans) — these need a stakeholder conversation before being hard-coded into the loan-eligibility/interest engine, rather than silently picking one interpretation.
