/// Every route path in the app, in one place, so screens navigate via
/// `context.go(RoutePaths.x)` instead of hand-typed path strings.
abstract final class RoutePaths {
  // Auth / onboarding
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboardingTerms = '/onboarding/terms';
  static const accountPending = '/account-pending';
  static const forcedPasswordChange = '/set-password';

  // Member shell (bottom nav / rail destinations) — Home / Ledger / Give /
  // Loans / Members, per `design_spec.md` §2's member `.tb` tab list.
  static const home = '/home';
  static const ledger = '/transactions';
  static const give = '/give';
  static const loans = '/loans';
  static const members = '/members';

  // Member — reached via the avatar in each tab's header, not a tab itself
  // (`design_spec.md`'s home screen header pattern).
  static const profile = '/profile';
  // Retained for the fund-overview content folded into Home (§1a) — no
  // longer a tab, but still a valid deep-link target.
  static const fund = '/fund';

  // Member — reached via quick actions / profile menu, not tabs
  static const addContribution = '/contributions/add';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const announcements = '/announcements';
  static const profileTerms = '/profile/terms';
  static const profileSettings = '/profile/settings';
  static const profileEdit = '/profile/edit';
  static const changePassword = '/profile/change-password';
  static const loanRequest = '/loans/request';
  static const campaigns = '/campaigns';
  static const disputes = '/profile/disputes';
  static const reportIssue = '/profile/disputes/new';

  static String memberDetail(String memberId) => '/members/$memberId';
  static String loanDetail(String loanId) => '/loans/$loanId';
  static String loanRepay(String loanId) => '/loans/$loanId/repay';

  // Admin shell
  static const adminDashboard = '/admin';
  static const adminMembers = '/admin/members';
  static const adminLoans = '/admin/loans';
  static const adminFund = '/admin/fund';
  static const adminReports = '/admin/reports';
  static const adminNotifications = '/admin/notifications';
  static const adminSettings = '/admin/settings';
  static const adminFundRules = '/admin/fund-rules';
  static const adminAudit = '/admin/audit';
  static const adminCreateUser = '/admin/members/create';
  static const adminRecordExpense = '/admin/fund/expense';
  static const adminRecordContribution = '/admin/fund/record-contribution';
  static const adminCorrectTransaction = '/admin/fund/correct';
  static const adminCampaigns = '/admin/campaigns';
  static const adminCreateCampaign = '/admin/campaigns/create';
  static const adminDisputes = '/admin/disputes';
  static const adminPrivacySettings = '/admin/privacy';
}
