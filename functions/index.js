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
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const crypto = require("crypto");
const logger = require("firebase-functions/logger");

initializeApp();

const ROLE_RANKS = { member: 0, admin: 1, superAdmin: 2 };
const BRAND_PURPLE = "#7C5CFC";
const BRAND_DARK = "#2B2A3D";

// Transaction types that should notify the whole community for
// transparency (SRS §12/§41/§54 — "members should be able to understand
// where the fund came from and where it went"), per the explicit ask to
// broadcast every contribution and loan disbursement.
const BROADCAST_TRANSACTION_TYPES = new Set([
  "monthlyContribution",
  "specialContribution",
  "loanDisbursement",
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
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const db = getFirestore();
  const callerSnap = await db.collection("users").doc(request.auth.uid).get();
  const caller = callerSnap.data();

  if (!caller || !caller.isActive || ROLE_RANKS[caller.role] === undefined || ROLE_RANKS[caller.role] < ROLE_RANKS.admin) {
    throw new HttpsError("permission-denied", "Only an active admin or super admin can create accounts.");
  }

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

  return { uid: userRecord.uid };
});

/**
 * Turns an admin's contribution verification into an actual ledger entry.
 * The Flutter app only ever writes the contribution's own status
 * (`ContributionsRepository.setStatus`) — it never touches `transactions`
 * or `fund/summary` directly (SRS §51 rule 9: only authorized admin
 * *actions* move money; the client shouldn't also be trusted to keep the
 * aggregate balance consistent). This is what actually moves a verified
 * contribution into the public ledger and updates the fund total, which in
 * turn is what makes `notifyOnTransaction` below fire.
 */
exports.onContributionVerified = onDocumentUpdated(
  "users/{userId}/contributions/{contributionId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;
    if (before.status === "verified" || after.status !== "verified") return;

    const db = getFirestore();
    const isSpecial = after.category === "special";

    await db.collection("transactions").add({
      type: isSpecial ? "specialContribution" : "monthlyContribution",
      amount: after.amount,
      date: after.date ?? FieldValue.serverTimestamp(),
      description: after.occasionName || "Monthly contribution",
      memberName: after.memberName ?? null,
      reference: event.params.contributionId,
    });

    await db.collection("fund").doc("summary").set(
      {
        availableBalance: FieldValue.increment(after.amount),
        totalContributions: isSpecial ? FieldValue.increment(0) : FieldValue.increment(after.amount),
        totalSpecialContributions: isSpecial ? FieldValue.increment(after.amount) : FieldValue.increment(0),
      },
      { merge: true },
    );
  },
);

/**
 * Mirrors onContributionVerified for the loan side: approving a loan
 * (AdminLoansScreen's review sheet) is this app's disbursement moment, so
 * that's what creates the ledger entry and updates the fund total.
 */
exports.onLoanApproved = onDocumentUpdated("loans/{loanId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status === "approved" || after.status !== "approved") return;

  const db = getFirestore();

  await db.collection("transactions").add({
    type: "loanDisbursement",
    amount: after.amount,
    date: FieldValue.serverTimestamp(),
    description: after.purpose || "Loan disbursement",
    memberName: after.borrowerName ?? null,
    reference: event.params.loanId,
  });

  await db.collection("fund").doc("summary").set(
    {
      availableBalance: FieldValue.increment(-after.amount),
      totalLoaned: FieldValue.increment(after.amount),
      outstandingLoans: FieldValue.increment(after.totalPayable ?? after.amount),
    },
    { merge: true },
  );
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
    const headline = isLoan
      ? `A loan of ${amountText} was disbursed`
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
      subject: isLoan ? "A loan was disbursed from the community fund" : "New contribution to the community fund",
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

  logger.info("Super admin seed complete.");
}

seedSuperAdminIfMissing().catch((error) => {
  logger.error("Super admin seed failed", error);
});
