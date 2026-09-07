import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_audit_screen.dart';
import '../../features/admin/presentation/screens/admin_campaigns_screen.dart';
import '../../features/admin/presentation/screens/admin_correct_transaction_screen.dart';
import '../../features/admin/presentation/screens/admin_create_campaign_screen.dart';
import '../../features/admin/presentation/screens/admin_create_user_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_fund_rules_screen.dart';
import '../../features/admin/presentation/screens/admin_fund_screen.dart';
import '../../features/admin/presentation/screens/admin_loan_review_screen.dart';
import '../../features/admin/presentation/screens/admin_loans_screen.dart';
import '../../features/admin/presentation/screens/admin_members_screen.dart';
import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_record_contribution_screen.dart';
import '../../features/admin/presentation/screens/admin_record_expense_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_disputes_screen.dart';
import '../../features/admin/presentation/screens/admin_email_templates_screen.dart';
import '../../features/admin/presentation/screens/admin_privacy_settings_screen.dart';
import '../../features/disputes/presentation/screens/disputes_screen.dart';
import '../../features/disputes/presentation/screens/report_issue_screen.dart';
import '../../features/auth/presentation/screens/account_pending_screen.dart';
import '../../features/auth/presentation/screens/forced_password_change_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import 'auth_redirect.dart';
import '../../features/contributions/data/campaign.dart';
import '../../features/contributions/presentation/screens/add_contribution_screen.dart';
import '../../features/contributions/presentation/screens/campaigns_screen.dart';
import '../../features/contributions/presentation/screens/contributions_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/member_shell_screen.dart';
import '../../features/fund/data/fund_transaction.dart';
import '../../features/fund/presentation/screens/fund_screen.dart';
import '../../features/fund/presentation/screens/transactions_screen.dart';
import '../../features/loans/presentation/screens/loan_acceptance_screen.dart';
import '../../features/loans/presentation/screens/loan_detail_screen.dart';
import '../../features/loans/presentation/screens/loan_request_screen.dart';
import '../../features/loans/presentation/screens/record_repayment_screen.dart';
import '../../features/loans/presentation/screens/loans_screen.dart';
import '../../features/members/data/member_directory_entry.dart';
import '../../features/members/presentation/screens/member_detail_screen.dart';
import '../../features/members/presentation/screens/members_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/member_walkthrough_screen.dart';
import '../../features/onboarding/presentation/screens/terms_screen.dart';
import '../../features/onboarding/providers/walkthrough_controller.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

/// The single [GoRouter] instance for the app. `redirect` is the router's
/// entire access-control policy (SRS §51 rule 9: only authorized roles
/// reach admin screens) — kept in one place rather than scattered
/// `if (role != admin) return` guards inside individual screens.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) {
      final profile = ref.read(userProfileProvider).value;
      final seen = ref.read(walkthroughSeenControllerProvider);
      return resolveAuthRedirect(
        authState: ref.read(authStateProvider),
        profileState: ref.read(userProfileProvider),
        location: state.matchedLocation,
        hasSeenWalkthrough: profile == null || seen.contains(profile.uid),
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.accountPending,
        builder: (context, state) => const AccountPendingScreen(),
      ),
      GoRoute(
        path: RoutePaths.forcedPasswordChange,
        builder: (context, state) => const ForcedPasswordChangeScreen(),
      ),
      GoRoute(
        path: RoutePaths.memberWalkthrough,
        builder: (context, state) => const MemberWalkthroughScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingTerms,
        builder: (context, state) => const TermsScreen(requireAcceptance: true),
      ),
      GoRoute(
        path: RoutePaths.profileTerms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.addContribution,
        builder: (context, state) =>
            AddContributionScreen(campaign: state.extra as Campaign?),
      ),
      GoRoute(
        path: RoutePaths.campaigns,
        builder: (context, state) => const CampaignsScreen(),
      ),
      GoRoute(
        path: RoutePaths.fund,
        builder: (context, state) => const FundScreen(),
      ),
      GoRoute(
        path: RoutePaths.members,
        builder: (context, state) => const MembersScreen(),
      ),
      GoRoute(
        path: RoutePaths.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.loanRequest,
        builder: (context, state) => const LoanRequestScreen(),
      ),
      GoRoute(
        path: '/members/:memberId',
        builder: (context, state) =>
            MemberDetailScreen(memberId: state.pathParameters['memberId']!),
      ),
      GoRoute(
        path: '/loans/:loanId',
        builder: (context, state) =>
            LoanDetailScreen(loanId: state.pathParameters['loanId']!),
      ),
      GoRoute(
        path: '/loans/:loanId/terms',
        builder: (context, state) =>
            LoanAcceptanceScreen(loanId: state.pathParameters['loanId']!),
      ),
      GoRoute(
        path: '/admin/loans/:loanId/review',
        builder: (context, state) =>
            AdminLoanReviewScreen(loanId: state.pathParameters['loanId']!),
      ),
      GoRoute(
        path: '/loans/:loanId/repay',
        builder: (context, state) =>
            RecordRepaymentScreen(loanId: state.pathParameters['loanId']!),
      ),

      // Member shell — Home / Ledger / Give / Loans / Members
      // (`design_spec.md` §2). Fund and Profile are still real screens, just
      // reached by push rather than a tab of their own (see the standalone
      // routes above) — Fund's summary content now lives on Home (§1a) and
      // Profile is reached via the avatar in each tab's header.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MemberShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ledger,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.give,
                builder: (context, state) => const ContributionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.loans,
                builder: (context, state) => const LoansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin shell — Dashboard / Members / Loans / Fund / More
      // (`design_spec.md` §2's admin `.tb` tab list — "More" lands on Fund
      // rules & audit, screen `3d`; Reports/Notifications/Campaigns/
      // Disputes/Privacy move into `AdminMoreMenu`, reached from there).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminDashboard,
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminMembers,
                builder: (context, state) => const AdminMembersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminLoans,
                builder: (context, state) => const AdminLoansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminFund,
                builder: (context, state) => const AdminFundScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminSettings,
                builder: (context, state) => const AdminSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.adminFundRules,
        builder: (context, state) => const AdminFundRulesScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminNotifications,
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminAudit,
        builder: (context, state) => const AdminAuditScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminCreateUser,
        builder: (context, state) => const AdminCreateUserScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminEditUser,
        builder: (context, state) => AdminCreateUserScreen(
          member: state.extra as MemberDirectoryEntry?,
        ),
      ),
      GoRoute(
        path: RoutePaths.adminRecordExpense,
        builder: (context, state) => const AdminRecordExpenseScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminRecordContribution,
        builder: (context, state) => const AdminRecordContributionScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminCorrectTransaction,
        builder: (context, state) => AdminCorrectTransactionScreen(
          original: state.extra as FundTransaction,
        ),
      ),
      GoRoute(
        path: RoutePaths.adminCampaigns,
        builder: (context, state) => const AdminCampaignsScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminCreateCampaign,
        builder: (context, state) => const AdminCreateCampaignScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminEditCampaign,
        builder: (context, state) => AdminCreateCampaignScreen(
          campaign: state.extra as Campaign?,
        ),
      ),
      GoRoute(
        path: RoutePaths.adminDisputes,
        builder: (context, state) => const AdminDisputesScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminEmailTemplates,
        builder: (context, state) => const AdminEmailTemplatesScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminPrivacySettings,
        builder: (context, state) => const AdminPrivacySettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.disputes,
        builder: (context, state) => const DisputesScreen(),
      ),
      GoRoute(
        path: RoutePaths.reportIssue,
        builder: (context, state) => const ReportIssueScreen(),
      ),
    ],
  );
});
