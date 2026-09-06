import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_audit_screen.dart';
import '../../features/admin/presentation/screens/admin_create_user_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_fund_screen.dart';
import '../../features/admin/presentation/screens/admin_loans_screen.dart';
import '../../features/admin/presentation/screens/admin_members_screen.dart';
import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/contributions/presentation/screens/add_contribution_screen.dart';
import '../../features/contributions/presentation/screens/contributions_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/member_shell_screen.dart';
import '../../features/fund/presentation/screens/fund_screen.dart';
import '../../features/fund/presentation/screens/transactions_screen.dart';
import '../../features/loans/presentation/screens/loan_detail_screen.dart';
import '../../features/loans/presentation/screens/loan_request_screen.dart';
import '../../features/loans/presentation/screens/loans_screen.dart';
import '../../features/members/presentation/screens/member_detail_screen.dart';
import '../../features/members/presentation/screens/members_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/terms_screen.dart';
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
      final location = state.matchedLocation;
      final isAuthRoute = location == RoutePaths.login ||
          location == RoutePaths.register ||
          location == RoutePaths.forgotPassword;

      final authState = ref.read(authStateProvider);

      // Firebase Auth hasn't reported an initial state yet — hold on the
      // splash screen rather than bouncing to /login prematurely. (This
      // also covers the placeholder-Firebase case: an error here is
      // treated as "resolved, logged out" below rather than hanging
      // forever, so the scaffold stays explorable before real Firebase
      // credentials are configured.)
      if (authState.isLoading && !authState.hasError) {
        return null;
      }

      final isLoggedIn = authState.value != null;

      if (!isLoggedIn) {
        return isAuthRoute ? null : RoutePaths.login;
      }

      // Logged in but the Firestore profile hasn't resolved yet — hold on
      // the splash screen rather than guessing a role.
      final profileState = ref.read(userProfileProvider);
      if (profileState.isLoading && location == RoutePaths.splash) {
        return null;
      }

      final isAdmin = ref.read(userRoleProvider).canAccessAdminShell;

      if (isAuthRoute || location == RoutePaths.splash) {
        return isAdmin ? RoutePaths.adminDashboard : RoutePaths.home;
      }

      if (!isAdmin && location.startsWith('/admin')) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.register, builder: (context, state) => const RegisterScreen()),
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
        builder: (context, state) => const AddContributionScreen(),
      ),
      GoRoute(
        path: RoutePaths.transactions,
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(path: RoutePaths.reports, builder: (context, state) => const ReportsScreen()),
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

      // Member shell — Home / Fund / Loans / Members / Profile (SRS §52).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MemberShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.home, builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.fund, builder: (context, state) => const FundScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.loans, builder: (context, state) => const LoansScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.members, builder: (context, state) => const MembersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.profile, builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),

      // Admin shell — Dashboard / Members / Loans / Fund / Reports (SRS §53).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.adminDashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.adminMembers,
              builder: (context, state) => const AdminMembersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.adminLoans,
              builder: (context, state) => const AdminLoansScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.adminFund,
              builder: (context, state) => const AdminFundScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.adminReports,
              builder: (context, state) => const AdminReportsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: RoutePaths.adminNotifications,
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminAudit,
        builder: (context, state) => const AdminAuditScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminCreateUser,
        builder: (context, state) => const AdminCreateUserScreen(),
      ),
      // ContributionsScreen (monthly/special tabs) is reachable from the
      // Fund tab's quick actions rather than the bottom nav; registered as
      // a normal push route so it keeps the Fund tab's back stack.
      GoRoute(
        path: RoutePaths.contributions,
        builder: (context, state) => const ContributionsScreen(),
      ),
    ],
  );
});
