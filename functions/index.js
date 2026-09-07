/**
 * Hamro Kosh Cloud Functions.
 *
 * This is the ONLY place the Resend API key is allowed to exist. It is
 * injected at runtime from Secret Manager (see README.md → "Deploy the
 * Cloud Function") — never hardcode it here, and never move this logic
 * into the Flutter app, where any embedded key could be extracted from the
 * compiled APK/IPA.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const crypto = require("crypto");
const logger = require("firebase-functions/logger");

initializeApp();

const ROLE_RANKS = { member: 0, admin: 1, superAdmin: 2 };
const BRAND_PURPLE = "#7C5CFC";
const BRAND_DARK = "#2B2A3D";

// SRS §17-§19 — Hamro Kosh's fixed lending policy (mirrors
// lib/core/models/loan_category.dart). There is no admin-chosen interest
// rate: the category a member requests under fixes the rate, the
// fund-share cap, and the allowed repayment windows.
const LOAN_CATEGORIES = {
  personal: { monthlyRatePercent: 1.0, maxFundShare: 0.30, allowedMonths: [3] },
  emergency: { monthlyRatePercent: 0.5, maxFundShare: 0.80, allowedMonths: [3, 6] },
};
const MAX_CONCURRENT_LOANS = 2;
const OUTSTANDING_LOAN_STATUSES = ["approved", "active", "partiallyPaid", "overdue"];
// SRS §21 / mirrors lib/core/models/loan_category.dart's
// loanLatePenaltyMonthlyRatePercent — keep both in sync.
const LATE_PENALTY_MONTHLY_RATE_PERCENT = 1.5;

function addMonths(date, months) {
  const result = new Date(date.getTime());
  result.setMonth(result.getMonth() + months);
  return result;
}

function monthsBetween(start, end) {
  const msPerMonth = 1000 * 60 * 60 * 24 * 30; // a flat 30-day month is fine for this app's scale
  return Math.max(0, (end.getTime() - start.getTime()) / msPerMonth);
}

/**
 * Total interest+penalty owed once `elapsedMonths` have passed since
 * disbursement — mirrors `LoanCostTimeline._interestAt` in the Flutter app
 * exactly (same formula, same constant), so the "what this will cost"
 * preview a member sees before requesting a loan never disagrees with what
 * verifyRepayment actually charges them.
 */
function interestOwedAt(principal, monthlyRatePercent, dueMonths, elapsedMonths) {
  const months = Math.max(elapsedMonths, 0);
  if (months <= dueMonths) {
    return principal * (monthlyRatePercent / 100) * months;
  }
  const missedCycles = Math.ceil((months - dueMonths) / dueMonths);
  const effectiveRate = monthlyRatePercent + missedCycles * LATE_PENALTY_MONTHLY_RATE_PERCENT;
  return principal * (effectiveRate / 100) * months;
}

// Transaction types that should notify the whole community for
// transparency (SRS §12/§41/§54 — "members should be able to understand
// where the fund came from and where it went"), per the explicit ask to
// broadcast every contribution and loan disbursement. `loanRepayment`
// mirrors `loanDisbursement` for symmetry (money coming back is as
// newsworthy as money going out); the accompanying `interestPayment`
// ledger entry isn't separately broadcast — it's the same real-world
// event as the repayment, not a second one.
const BROADCAST_TRANSACTION_TYPES = new Set([
  "monthlyContribution",
  "specialContribution",
  "loanDisbursement",
  "loanRepayment",
]);

/**
 * Generates a random, human-typeable temporary password (avoids visually
 * ambiguous characters like 0/O/1/l) — the user is expected to change it
 * on first login (SRS.md §58 flow).
 */
function generateTempPassword() {
  const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  const bytes = crypto.randomBytes(12);
  let password = "";
  for (const byte of bytes) {
    password += alphabet[byte % alphabet.length];
  }
  return password;
}

/**
 * The one branded HTML shell every Hamro Kosh email is built from —
 * greeting, a "pre-content" lede, the main content block, and a closing
 * note, wrapped in a simple table layout (inline CSS only, no external
 * image) so it renders consistently across email clients without
 * depending on any hosted asset.
 */
function buildEmailShell({ preheader, greeting, preContent, mainContentHtml, postContent }) {
  return `<!DOCTYPE html>
<html>
  <head><meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /></head>
  <body style="margin:0;padding:0;background:#F4F2FA;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <span style="display:none;max-height:0;overflow:hidden;opacity:0;">${preheader}</span>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F4F2FA;padding:32px 16px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" style="max-width:520px;background:#FFFFFF;border-radius:16px;overflow:hidden;">
            <tr>
              <td style="background:${BRAND_PURPLE};padding:28px 32px;text-align:center;">
                <span style="color:#FFFFFF;font-size:22px;font-weight:800;letter-spacing:3px;">HAMRO KOSH</span>
              </td>
            </tr>
            <tr>
              <td style="padding:32px;">
                <p style="margin:0 0 16px;color:${BRAND_DARK};font-size:17px;font-weight:700;">${greeting}</p>
                <p style="margin:0 0 20px;color:#4B4A5E;font-size:14px;line-height:1.6;">${preContent}</p>
                <div style="margin:0 0 20px;">${mainContentHtml}</div>
                <p style="margin:0;color:#4B4A5E;font-size:13px;line-height:1.6;">${postContent}</p>
              </td>
            </tr>
            <tr>
              <td style="padding:20px 32px;background:#F9F8FC;text-align:center;">
                <p style="margin:0;color:#8B899C;font-size:12px;">This is an automated message from Hamro Kosh — your transparent community fund.</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

/**
 * SRS §40 — every privileged administrative action gets an audit entry.
 * `performedBy` is a uid rather than an email so this never has to be
 * corrected if someone changes their email later.
 */
async function writeAuditLog({ action, performedBy, newValue }) {
  await getFirestore().collection("audit_log").add({
    action,
    performedBy,
    newValue: newValue ?? null,
    timestamp: FieldValue.serverTimestamp(),
  });
}

/**
 * SRS §23/§45 — writes one entry into a specific member's notification
 * center (this is what NotificationsScreen has been reading from since
 * Phase 7; nothing ever called it until now, so it always showed "you're
 * all caught up") and pushes it to their device via FCM, if they have a
 * token saved (NotificationService on the Flutter side saves it — this was
 * the other missing link). `category` must match `NotificationCategory` in
 * lib/core/models/notification_item.dart (financial/reminder/loan/
 * announcement/system). A stale/invalid token never blocks the caller —
 * this is a best-effort side effect, not the primary write.
 */
async function notifyUser(uid, { title, body, category }) {
  if (!uid) return;
  const db = getFirestore();

  await db.collection("users").doc(uid).collection("notifications").add({
    title,
    body,
    category,
    createdAt: FieldValue.serverTimestamp(),
    isRead: false,
  });

  try {
    const userSnap = await db.collection("users").doc(uid).get();
    const token = userSnap.exists ? userSnap.data().fcmToken : null;
    if (token) {
      await getMessaging().send({ token, notification: { title, body } });
    }
  } catch (error) {
    logger.warn(`Push notification failed for ${uid}: ${error.message}`);
  }
}

/**
 * Loads the caller's own `users/{uid}` doc and throws unless they're an
 * active admin or super admin. Shared by every callable below that performs
 * a privileged financial action (SRS §37: these must never be reachable by
 * an ordinary member, and firestore.rules alone can't express the
 * multi-document side effects — ledger entry + fund total + audit log —
 * that have to happen atomically with the status change).
 */
async function requireAdmin(auth) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const db = getFirestore();
  const callerSnap = await db.collection("users").doc(auth.uid).get();
  const caller = callerSnap.data();
  if (!caller || !caller.isActive || (ROLE_RANKS[caller.role] ?? -1) < ROLE_RANKS.admin) {
    throw new HttpsError("permission-denied", "Only an active admin or super admin can do this.");
  }
  return caller;
}

async function sendEmail({ toEmails, subject, html }) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "Email service is not configured (missing RESEND_API_KEY secret).",
    );
  }
  if (toEmails.length === 0) return;

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: "Hamro Kosh <onboarding@resend.dev>",
      to: toEmails,
      subject,
      html,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError("internal", `Resend API error (${response.status}): ${body}`);
  }
}

async function sendWelcomeEmail({ toEmail, fullName, tempPassword, role }) {
  const html = buildEmailShell({
    preheader: `Your Hamro Kosh ${role} account is ready`,
    greeting: `Namaste ${fullName},`,
    preContent: `An administrator has created a <strong>${role}</strong> account for you on Hamro Kosh, your community's transparent fund &amp; lending app.`,
    mainContentHtml: `
      <table role="presentation" width="100%" style="background:#F4F2FA;border-radius:12px;">
        <tr><td style="padding:16px 20px;">
          <p style="margin:0 0 8px;color:#8B899C;font-size:12px;">EMAIL</p>
          <p style="margin:0 0 16px;color:${BRAND_DARK};font-size:15px;font-weight:600;">${toEmail}</p>
          <p style="margin:0 0 8px;color:#8B899C;font-size:12px;">TEMPORARY PASSWORD</p>
          <p style="margin:0;color:${BRAND_DARK};font-size:15px;font-weight:600;letter-spacing:1px;">${tempPassword}</p>
        </td></tr>
      </table>`,
    postContent: "Please sign in and set your own password from Profile &rarr; Change password as soon as possible.",
  });

  await sendEmail({ toEmails: [toEmail], subject: "Your Hamro Kosh account is ready", html });
}

/**
 * Callable from the Flutter app by an authenticated admin/super-admin to
 * provision a new member or admin account (SRS §3, §35, and the RBAC
 * addition in SRS.md §58). Only the Admin SDK — never client-side Firestore
 * writes — is allowed to create `users/{uid}` documents with an elevated
 * role, so this function is the sole path for that write.
 */
exports.createUserAccount = onCall({ secrets: ["RESEND_API_KEY"] }, async (request) => {
  const caller = await requireAdmin(request.auth);
  const db = getFirestore();

  const { fullName, email, phone, role } = request.data ?? {};

  if (typeof fullName !== "string" || fullName.trim().length < 2) {
    throw new HttpsError("invalid-argument", "A valid full name is required.");
  }
  if (typeof email !== "string" || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "A valid email is required.");
  }
  if (role !== "member" && role !== "admin") {
    throw new HttpsError("invalid-argument", "role must be 'member' or 'admin'.");
  }
  // A plain admin may only create members; only a super admin may create
  // another admin. Nobody — including this function — creates superAdmin
  // accounts through this path; see seedSuperAdminIfMissing below.
  if (role === "admin" && caller.role !== "superAdmin") {
    throw new HttpsError("permission-denied", "Only a super admin can create admin accounts.");
  }

  const tempPassword = generateTempPassword();

  const userRecord = await getAuth().createUser({
    email,
    password: tempPassword,
    displayName: fullName.trim(),
  });

  await db.collection("users").doc(userRecord.uid).set({
    fullName: fullName.trim(),
    email,
    phone: typeof phone === "string" ? phone.trim() : null,
    role,
    isApproved: true,
    isActive: true,
    memberSince: FieldValue.serverTimestamp(),
    createdBy: request.auth.uid,
    mustChangePassword: true,
  });

  await sendWelcomeEmail({ toEmail: email, fullName: fullName.trim(), tempPassword, role });

  await writeAuditLog({
    action: `Created ${role} account for ${email}`,
    performedBy: request.auth.uid,
    newValue: userRecord.uid,
  });

  await notifyUser(userRecord.uid, {
    title: "Welcome to Hamro Kosh",
    body: "Your account is ready. Check your email for your temporary password.",
    category: "system",
  });

  return { uid: userRecord.uid };
});

/**
 * Callable from AdminFundScreen's "Verify contributions" tab. Verifying (or
 * rejecting) a contribution can't be a direct client write to its `status`
 * field: verifying one also has to record a ledger entry and update the
 * fund total atomically (SRS §51 rule 9 — only authorized admin *actions*
 * move money; a client write can't be trusted to keep the aggregate
 * consistent). Writing the `transactions` doc below is what makes
 * `notifyOnTransaction` fire the transparency broadcast email.
 */
exports.verifyContribution = onCall(async (request) => {
  const caller = await requireAdmin(request.auth);
  const { memberUid, contributionId, status } = request.data ?? {};

  if (typeof memberUid !== "string" || typeof contributionId !== "string" ||
      (status !== "verified" && status !== "rejected")) {
    throw new HttpsError("invalid-argument", "memberUid, contributionId, and a valid status are required.");
  }

  const db = getFirestore();
  const ref = db.collection("users").doc(memberUid).collection("contributions").doc(contributionId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Contribution not found.");
  }
  const contribution = snap.data();

  await ref.update({ status });
  await writeAuditLog({
    action: `Set contribution ${contributionId} to ${status}`,
    performedBy: request.auth.uid,
    newValue: status,
  });

  await notifyUser(memberUid, {
    title: status === "verified" ? "Contribution verified" : "Contribution rejected",
    body:
      status === "verified"
        ? `Your ${contribution.occasionName || "monthly"} contribution of NPR ${contribution.amount.toLocaleString()} has been verified.`
        : `Your contribution of NPR ${contribution.amount.toLocaleString()} was rejected. Contact an admin for details.`,
    category: "financial",
  });

  if (status === "verified") {
    const isSpecial = contribution.category === "special";

    await db.collection("transactions").add({
      type: isSpecial ? "specialContribution" : "monthlyContribution",
      amount: contribution.amount,
      date: contribution.date ?? FieldValue.serverTimestamp(),
      description: contribution.occasionName || "Monthly contribution",
      memberName: contribution.memberName ?? null,
      reference: contributionId,
    });

    await db.collection("fund").doc("summary").set(
      {
        availableBalance: FieldValue.increment(contribution.amount),
        totalContributions: isSpecial ? FieldValue.increment(0) : FieldValue.increment(contribution.amount),
        totalSpecialContributions: isSpecial ? FieldValue.increment(contribution.amount) : FieldValue.increment(0),
      },
      { merge: true },
    );
  }

  return { ok: true };
});

/**
 * Callable from AdminLoansScreen's review sheet. Approving a loan is this
 * app's disbursement moment — same reasoning as verifyContribution above:
 * the ledger entry, fund total, interest terms, and audit log all have to
 * land together, which a bare client write to `loans/{id}.status` can't
 * guarantee. The interest rate is never taken from the client: it's fixed
 * by the loan's own `category` (SRS §17-§19), and the fund-share cap and
 * the fund-wide `MAX_CONCURRENT_LOANS` limit are enforced here, server-side,
 * against the current fund balance — a client can't be trusted to check
 * either at the moment money actually moves.
 */
exports.approveLoan = onCall(async (request) => {
  await requireAdmin(request.auth);
  const { loanId, action, repaymentMonths } = request.data ?? {};

  if (typeof loanId !== "string" || (action !== "approve" && action !== "reject")) {
    throw new HttpsError("invalid-argument", "loanId and a valid action are required.");
  }

  const db = getFirestore();
  const ref = db.collection("loans").doc(loanId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Loan not found.");
  }
  const loan = snap.data();

  if (action === "reject") {
    await ref.update({ status: "rejected" });
    await writeAuditLog({ action: `Rejected loan ${loanId}`, performedBy: request.auth.uid });
    await notifyUser(loan.memberId, {
      title: "Loan request rejected",
      body: `Your ${loan.category || ""} loan request for NPR ${loan.amount.toLocaleString()} was rejected.`,
      category: "loan",
    });
    return { ok: true };
  }

  const category = LOAN_CATEGORIES[loan.category] ? loan.category : "personal";
  const config = LOAN_CATEGORIES[category];
  const months = config.allowedMonths.includes(Number(repaymentMonths))
    ? Number(repaymentMonths)
    : config.allowedMonths[0];

  const fundSnap = await db.collection("fund").doc("summary").get();
  const availableBalance = fundSnap.exists ? (fundSnap.data().availableBalance ?? 0) : 0;
  const cap = availableBalance * config.maxFundShare;
  if (loan.amount > cap) {
    throw new HttpsError(
      "failed-precondition",
      `A ${category} loan can't exceed ${Math.round(config.maxFundShare * 100)}% of the fund balance ` +
        `(NPR ${Math.floor(cap).toLocaleString()} available for this category).`,
    );
  }

  const outstandingSnap = await db
    .collection("loans")
    .where("status", "in", OUTSTANDING_LOAN_STATUSES)
    .get();
  if (outstandingSnap.size >= MAX_CONCURRENT_LOANS) {
    throw new HttpsError(
      "failed-precondition",
      `Only ${MAX_CONCURRENT_LOANS} loans may be outstanding fund-wide at once, and that limit is already reached.`,
    );
  }

  const rate = config.monthlyRatePercent;
  const totalPayable = loan.amount * (1 + (rate / 100) * months);
  const disbursedAt = new Date();

  await ref.update({
    status: "approved",
    interestRatePercent: rate,
    repaymentMonths: months,
    totalPayable,
    disbursedAt,
    nextDueDate: addMonths(disbursedAt, months),
  });

  await db.collection("transactions").add({
    type: "loanDisbursement",
    amount: loan.amount,
    date: FieldValue.serverTimestamp(),
    description: loan.purpose || "Loan disbursement",
    memberName: loan.borrowerName ?? null,
    reference: loanId,
  });

  await db.collection("fund").doc("summary").set(
    {
      availableBalance: FieldValue.increment(-loan.amount),
      totalLoaned: FieldValue.increment(loan.amount),
      outstandingLoans: FieldValue.increment(totalPayable),
    },
    { merge: true },
  );

  await writeAuditLog({
    action: `Approved ${category} loan ${loanId}`,
    performedBy: request.auth.uid,
    newValue: totalPayable,
  });

  await notifyUser(loan.memberId, {
    title: "Loan approved",
    body: `Your ${category} loan of NPR ${loan.amount.toLocaleString()} was approved and disbursed.`,
    category: "loan",
  });

  return { ok: true };
});

/**
 * Callable from AdminLoansScreen's "Verify repayments" tab. A member's
 * repayment submission (LoansRepository.submitRepayment) only ever claims
 * "I paid NPR X" — this is what actually splits that into principal/
 * interest/penalty, updates the loan's running balances and status, and
 * records the ledger entries (SRS §21, §36 — never trust a client-computed
 * split for money that's actually moving).
 *
 * Allocation order for a payment: penalty first (stop further exposure),
 * then interest, then principal. `totalPayable` is recomputed on every
 * call to include any newly-accrued penalty, so `Loan.outstanding`
 * (totalPayable - amountPaid) always stays correct without the Flutter
 * side needing to know about penalty accrual separately.
 */
exports.verifyRepayment = onCall(async (request) => {
  await requireAdmin(request.auth);
  const { repaymentId, status } = request.data ?? {};

  if (typeof repaymentId !== "string" || (status !== "verified" && status !== "rejected")) {
    throw new HttpsError("invalid-argument", "repaymentId and a valid status are required.");
  }

  const db = getFirestore();
  const repaymentRef = db.collection("loan_repayments").doc(repaymentId);
  const repaymentSnap = await repaymentRef.get();
  if (!repaymentSnap.exists) {
    throw new HttpsError("not-found", "Repayment not found.");
  }
  const repayment = repaymentSnap.data();
  if (repayment.status !== "pending") {
    throw new HttpsError("failed-precondition", "This repayment has already been reviewed.");
  }

  if (status === "rejected") {
    await repaymentRef.update({ status: "rejected" });
    await writeAuditLog({ action: `Rejected repayment ${repaymentId}`, performedBy: request.auth.uid });
    await notifyUser(repayment.memberUid, {
      title: "Repayment rejected",
      body: `Your repayment of NPR ${repayment.amount.toLocaleString()} was rejected. Contact an admin for details.`,
      category: "loan",
    });
    return { ok: true };
  }

  const loanRef = db.collection("loans").doc(repayment.loanId);
  const loanSnap = await loanRef.get();
  if (!loanSnap.exists) {
    throw new HttpsError("not-found", "Loan not found.");
  }
  const loan = loanSnap.data();
  if (!OUTSTANDING_LOAN_STATUSES.includes(loan.status)) {
    throw new HttpsError("failed-precondition", "This loan isn't open for repayment.");
  }

  const principal = loan.amount;
  const rate = loan.interestRatePercent ?? 0;
  const dueMonths = loan.repaymentMonths ?? 1;
  const disbursedAt = loan.disbursedAt ? loan.disbursedAt.toDate() : new Date();
  const elapsedMonths = monthsBetween(disbursedAt, new Date());

  const totalInterestDue = principal * (rate / 100) * dueMonths; // fixed on-time interest
  const totalOwedNow = interestOwedAt(principal, rate, dueMonths, elapsedMonths);
  const accruedPenalty = Math.max(0, totalOwedNow - totalInterestDue);

  const principalPaidSoFar = loan.principalPaid ?? 0;
  const interestPaidSoFar = loan.interestPaid ?? 0;
  const penaltyPaidSoFar = loan.penaltyPaid ?? 0;
  const oldOutstanding = (loan.totalPayable ?? principal) - (loan.amountPaid ?? 0);

  const remainingPenalty = Math.max(0, accruedPenalty - penaltyPaidSoFar);
  const remainingInterest = Math.max(0, totalInterestDue - interestPaidSoFar);
  const remainingPrincipal = Math.max(0, principal - principalPaidSoFar);
  const totalOutstanding = remainingPenalty + remainingInterest + remainingPrincipal;

  const payment = repayment.amount;
  if (payment > totalOutstanding + 0.01) {
    throw new HttpsError(
      "failed-precondition",
      `This repayment (NPR ${payment.toLocaleString()}) exceeds the outstanding balance ` +
        `(NPR ${Math.ceil(totalOutstanding).toLocaleString()}).`,
    );
  }

  let remaining = payment;
  const penaltyComponent = Math.min(remaining, remainingPenalty);
  remaining -= penaltyComponent;
  const interestComponent = Math.min(remaining, remainingInterest);
  remaining -= interestComponent;
  const principalComponent = remaining;

  const newPrincipalPaid = principalPaidSoFar + principalComponent;
  const newInterestPaid = interestPaidSoFar + interestComponent;
  const newPenaltyPaid = penaltyPaidSoFar + penaltyComponent;
  const newAmountPaid = newPrincipalPaid + newInterestPaid + newPenaltyPaid;
  const newTotalPayable = principal + totalInterestDue + accruedPenalty;
  const newOutstanding = newTotalPayable - newAmountPaid;

  const newStatus =
    newOutstanding <= 0.01
      ? "completed"
      : new Date() > (loan.nextDueDate ? loan.nextDueDate.toDate() : new Date())
        ? "overdue"
        : "partiallyPaid";

  await loanRef.update({
    principalPaid: newPrincipalPaid,
    interestPaid: newInterestPaid,
    penaltyPaid: newPenaltyPaid,
    amountPaid: newAmountPaid,
    totalPayable: newTotalPayable,
    status: newStatus,
  });

  await repaymentRef.update({
    status: "verified",
    principalComponent,
    interestComponent,
    penaltyComponent,
  });

  const memberName = repayment.borrowerName ?? loan.borrowerName ?? null;
  if (principalComponent + penaltyComponent > 0) {
    await db.collection("transactions").add({
      type: "loanRepayment",
      amount: principalComponent + penaltyComponent,
      date: FieldValue.serverTimestamp(),
      description: `Repayment on loan ${repayment.loanId}`,
      memberName,
      reference: repaymentId,
    });
  }
  if (interestComponent > 0) {
    await db.collection("transactions").add({
      type: "interestPayment",
      amount: interestComponent,
      date: FieldValue.serverTimestamp(),
      description: `Interest on loan ${repayment.loanId}`,
      memberName,
      reference: repaymentId,
    });
  }

  // Penalty revenue is folded into interestEarned too — both are fund
  // income beyond the principal lent out, and SRS doesn't track a
  // separate "penalty earned" figure.
  await db.collection("fund").doc("summary").set(
    {
      availableBalance: FieldValue.increment(payment),
      outstandingLoans: FieldValue.increment(newOutstanding - oldOutstanding),
      interestEarned: FieldValue.increment(interestComponent + penaltyComponent),
    },
    { merge: true },
  );

  await writeAuditLog({
    action: `Recorded NPR ${payment.toLocaleString()} repayment on loan ${repayment.loanId}`,
    performedBy: request.auth.uid,
    newValue: newStatus,
  });

  await notifyUser(repayment.memberUid, {
    title: "Repayment verified",
    body:
      newStatus === "completed"
        ? `Your repayment of NPR ${payment.toLocaleString()} was verified — this loan is now fully paid off.`
        : `Your repayment of NPR ${payment.toLocaleString()} was verified.`,
    category: "loan",
  });

  return { ok: true };
});

/**
 * Callable from AdminFundScreen's "Record expense" action (SRS §17). Unlike
 * contributions/repayments, an expense is asserted directly by the admin
 * who spent the money — there's no member claim to verify first — but it
 * still has to go through a Cloud Function rather than a direct client
 * write, for the same reason every other ledger entry does: the fund total
 * has to move atomically with it (SRS §36/§37).
 */
exports.recordExpense = onCall(async (request) => {
  await requireAdmin(request.auth);
  const { amount, category, description, recipient, paymentMethod, proofUrl } = request.data ?? {};

  if (typeof amount !== "number" || amount <= 0) {
    throw new HttpsError("invalid-argument", "A valid positive amount is required.");
  }
  if (typeof description !== "string" || description.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A description is required.");
  }

  const db = getFirestore();

  await db.collection("transactions").add({
    type: "fundExpense",
    amount,
    date: FieldValue.serverTimestamp(),
    description: description.trim(),
    category: typeof category === "string" ? category : "other",
    recipient: typeof recipient === "string" ? recipient.trim() : null,
    paymentMethod: typeof paymentMethod === "string" ? paymentMethod : null,
    proofUrl: typeof proofUrl === "string" ? proofUrl : null,
    memberName: null,
  });

  await db.collection("fund").doc("summary").set(
    {
      availableBalance: FieldValue.increment(-amount),
      totalExpenses: FieldValue.increment(amount),
    },
    { merge: true },
  );

  await writeAuditLog({
    action: `Recorded expense of NPR ${amount.toLocaleString()} (${category ?? "other"})`,
    performedBy: request.auth.uid,
    newValue: description.trim(),
  });

  return { ok: true };
});

/**
 * SRS §12/§41/§54 — transparency isn't just "visible if you open the app";
 * a contribution or loan disbursement notifies every active member by
 * email, the same way SRS §28 already expects for individual account
 * events. Runs server-side because it needs the Resend key and because a
 * client shouldn't be trusted to decide who else gets emailed.
 */
exports.notifyOnTransaction = onDocumentCreated(
  { document: "transactions/{transactionId}", secrets: ["RESEND_API_KEY"] },
  async (event) => {
    const data = event.data?.data();
    if (!data || !BROADCAST_TRANSACTION_TYPES.has(data.type)) return;

    const db = getFirestore();
    const usersSnap = await db
      .collection("users")
      .where("isApproved", "==", true)
      .where("isActive", "==", true)
      .get();

    const recipients = usersSnap.docs
      .map((doc) => doc.data().email)
      .filter((email) => typeof email === "string" && email.length > 0);

    if (recipients.length === 0) return;

    const amountText = typeof data.amount === "number" ? `NPR ${data.amount.toLocaleString()}` : "an amount";
    const isLoan = data.type === "loanDisbursement";
    const isRepayment = data.type === "loanRepayment";
    const headline = isLoan
      ? `A loan of ${amountText} was disbursed`
      : isRepayment
        ? `${data.memberName || "A member"} repaid ${amountText} on their loan`
        : `${data.memberName || "A member"} contributed ${amountText}`;

    const html = buildEmailShell({
      preheader: headline,
      greeting: "Namaste,",
      preContent: "For full transparency, here's a new entry in the community fund's financial ledger:",
      mainContentHtml: `
        <table role="presentation" width="100%" style="background:#F4F2FA;border-radius:12px;">
          <tr><td style="padding:16px 20px;">
            <p style="margin:0 0 6px;color:${BRAND_DARK};font-size:16px;font-weight:700;">${headline}</p>
            <p style="margin:0;color:#4B4A5E;font-size:13px;">${data.description || ""}</p>
          </td></tr>
        </table>`,
      postContent: "You can view the complete ledger and current fund balance any time from the app's Fund tab.",
    });

    // Resend's batch endpoint sends up to 100 distinct emails in one call;
    // for a community fund's member count that's comfortably one request.
    await sendEmail({
      toEmails: recipients,
      subject: isLoan
        ? "A loan was disbursed from the community fund"
        : isRepayment
          ? "A loan repayment was recorded"
          : "New contribution to the community fund",
      html,
    });
  },
);

/**
 * Idempotent super-admin bootstrap. Runs once per cold start of this
 * Functions instance ("at runtime", per the requested behavior) rather
 * than being reachable from the Flutter client — a mobile app fundamentally
 * cannot be trusted to create a Firebase Auth user for someone else or
 * write an elevated role past Firestore's security rules, and "the first
 * client to call an endpoint becomes super admin" would be a race anyone
 * could win. Checks Firestore first and exits immediately if a super admin
 * already exists, so re-deploys/cold-starts are always safe no-ops.
 */
const SUPER_ADMIN_EMAIL = "ranad4508@gmail.com";
const SUPER_ADMIN_PASSWORD = "Password@123#";

async function seedSuperAdminIfMissing() {
  const db = getFirestore();

  const existing = await db.collection("users").where("role", "==", "superAdmin").limit(1).get();
  if (!existing.empty) {
    logger.info("Super admin already exists — skipping seed.");
    return;
  }

  const auth = getAuth();
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(SUPER_ADMIN_EMAIL);
    logger.info(`Auth user for ${SUPER_ADMIN_EMAIL} already exists; promoting to superAdmin.`);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    userRecord = await auth.createUser({
      email: SUPER_ADMIN_EMAIL,
      password: SUPER_ADMIN_PASSWORD,
      displayName: "Super Admin",
    });
    logger.info(`Created super admin Auth user ${userRecord.uid}.`);
  }

  await db.collection("users").doc(userRecord.uid).set(
    {
      fullName: "Super Admin",
      email: SUPER_ADMIN_EMAIL,
      role: "superAdmin",
      isApproved: true,
      isActive: true,
      memberSince: FieldValue.serverTimestamp(),
      mustChangePassword: true,
    },
    { merge: true },
  );

  await writeAuditLog({
    action: `Seeded super admin account (${SUPER_ADMIN_EMAIL})`,
    performedBy: "system",
    newValue: userRecord.uid,
  });

  logger.info("Super admin seed complete.");
}

seedSuperAdminIfMissing().catch((error) => {
  logger.error("Super admin seed failed", error);
});

/**
 * SRS §22 — repayment reminders (7/3/1 days before due, on the due date)
 * and SRS §24's loan-status auto-transition to `overdue`. Neither existed
 * before: a loan sat at `approved`/`active` forever regardless of the
 * calendar unless a repayment happened to be verified. Runs once daily;
 * idempotent enough for this app's scale (one notification/email per loan
 * per day it matches a reminder threshold — not a continuous nag).
 */
exports.dailyLoanSweep = onSchedule(
  { schedule: "0 8 * * *", timeZone: "Asia/Kathmandu", secrets: ["RESEND_API_KEY"] },
  async () => {
    const db = getFirestore();
    const loansSnap = await db.collection("loans").where("status", "in", OUTSTANDING_LOAN_STATUSES).get();

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (const doc of loansSnap.docs) {
      const loan = doc.data();
      if (!loan.nextDueDate || !loan.memberId) continue;

      const outstanding = (loan.totalPayable ?? loan.amount) - (loan.amountPaid ?? 0);
      if (outstanding <= 0) continue;

      const dueDate = loan.nextDueDate.toDate();
      const dueDateOnly = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());
      const daysUntilDue = Math.round((dueDateOnly.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

      let title;
      let body;
      let category;

      if (daysUntilDue < 0 && loan.status !== "overdue") {
        await doc.ref.update({ status: "overdue" });
        title = "Loan overdue";
        body =
          `Your loan is now overdue — outstanding NPR ${outstanding.toLocaleString()}. ` +
          "A late penalty is now accruing on the principal.";
        category = "loan";
      } else if ([7, 3, 1, 0].includes(daysUntilDue)) {
        const when = daysUntilDue === 0 ? "due today" : `due in ${daysUntilDue} day${daysUntilDue === 1 ? "" : "s"}`;
        title = "Loan repayment reminder";
        body = `Your loan repayment of NPR ${outstanding.toLocaleString()} is ${when}.`;
        category = "reminder";
      } else {
        continue;
      }

      await notifyUser(loan.memberId, { title, body, category });

      try {
        const userSnap = await db.collection("users").doc(loan.memberId).get();
        const email = userSnap.exists ? userSnap.data().email : null;
        if (email) {
          await sendEmail({
            toEmails: [email],
            subject: title,
            html: buildEmailShell({
              preheader: title,
              greeting: "Namaste,",
              preContent: body,
              mainContentHtml: "",
              postContent: "You can record a repayment any time from the loan's detail screen in the app.",
            }),
          });
        }
      } catch (error) {
        logger.warn(`Reminder email failed for loan ${doc.id}: ${error.message}`);
      }
    }
  },
);
