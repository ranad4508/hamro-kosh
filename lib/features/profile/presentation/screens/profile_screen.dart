import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/data/app_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../loans/providers/loans_providers.dart';

/// The member's account hub (SRS §4, §32) — everything account-related
/// (profile, security, preferences, support, and for admins a shortcut back
/// into the admin app) lives here in one organized, grouped menu, reached
/// via the avatar in each tab's header rather than a tab of its own.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final isAdmin = profile?.role.canAccessAdminShell ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ProfileHeaderCard(profile: profile),
          const SizedBox(height: AppSpacing.md),
          if (profile != null) _MyFundSummaryCard(uid: profile.uid),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Account'),
          _MenuGroup(
            items: [
              _MenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit profile',
                onTap: () => context.push(RoutePaths.profileEdit),
              ),
              _MenuItem(
                icon: Icons.password_outlined,
                label: 'Change password',
                onTap: () => context.push(RoutePaths.changePassword),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Preferences'),
          _MenuGroup(
            items: [
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Settings & notifications',
                subtitle: 'Language, app lock, email preferences',
                onTap: () => context.push(RoutePaths.profileSettings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Support & legal'),
          _MenuGroup(
            items: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                onTap: () => context.push(RoutePaths.profileTerms),
              ),
              _MenuItem(
                icon: Icons.report_problem_outlined,
                label: 'Report an issue',
                onTap: () => context.push(RoutePaths.disputes),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('Admin'),
            _MenuGroup(
              items: [
                _MenuItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Go to admin dashboard',
                  onTap: () => context.go(RoutePaths.adminDashboard),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _MenuGroup(
            items: [
              _MenuItem(
                icon: Icons.logout,
                label: 'Sign out',
                iconColor: context.colors.warning,
                labelColor: context.colors.warning,
                onTap: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final AppUser? profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final role = profile?.role;
    final roleLabel = switch (role) {
      UserRole.superAdmin => 'Super Admin',
      UserRole.admin => 'Admin',
      _ => 'Member',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: profile?.initials ?? '?',
            imageUrl: profile?.photoUrl,
            radius: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile?.fullName ?? '—',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: roleLabel,
                      tone: role == UserRole.member
                          ? StatusTone.neutral
                          : StatusTone.positive,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  profile?.email ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textTertiary,
                  ),
                ),
                if (profile?.memberSince != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Member since ${DateFormatter.monthYear(profile!.memberSince!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textQuaternary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: context.colors.accent,
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.divider),
            ListTile(
              leading: Icon(
                items[i].icon,
                color: items[i].iconColor ?? colors.textSecondary,
              ),
              title: Text(
                items[i].label,
                style: TextStyle(color: items[i].labelColor),
              ),
              subtitle: items[i].subtitle == null
                  ? null
                  : Text(
                      items[i].subtitle!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textQuaternary,
                      ),
                    ),
              trailing: items[i].labelColor == null
                  ? Icon(Icons.chevron_right, color: colors.textQuaternary)
                  : null,
              onTap: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// SRS §4/§32 — the member's own contribution total and loan status, right
/// on their profile rather than only reachable via the Ledger/Loans tabs.
class _MyFundSummaryCard extends ConsumerWidget {
  const _MyFundSummaryCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalContributed = ref.watch(
      memberVerifiedContributionsTotalProvider(uid),
    );
    final hasActiveLoan = ref.watch(memberHasActiveLoanProvider(uid));

    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: Icon(
                Icons.volunteer_activism_outlined,
                color: colors.accentLight,
              ),
              title: const Text('My contributions'),
              subtitle: switch (totalContributed) {
                AsyncData(:final value) => Text(
                  CurrencyFormatter.format(value),
                ),
                AsyncError() => const Text('—'),
                _ => const Text('…'),
              },
            ),
          ),
          VerticalDivider(width: 1, color: colors.divider),
          Expanded(
            child: ListTile(
              leading: Icon(
                Icons.request_quote_outlined,
                color: colors.accentLight,
              ),
              title: const Text('Active loan'),
              subtitle: switch (hasActiveLoan) {
                AsyncData(:final value) => Text(value ? 'Yes' : 'None'),
                AsyncError() => const Text('—'),
                _ => const Text('…'),
              },
            ),
          ),
        ],
      ),
    );
  }
}
