import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/providers/auth_providers.dart';

/// The admin app's "More" tab — a pure navigation hub, the admin-side
/// equivalent of the member `ProfileScreen`: an account header, then every
/// row a tappable link to its own screen (Fund rules & accounts, Reports,
/// Notifications, Campaigns, Disputes, Privacy settings, Audit trail) —
/// nothing embedded inline here, unlike the earlier version of this screen
/// which showed the fund-rules form directly and left admins with no way
/// to reach their own account actions (edit profile, change password, sign
/// out) at all, since only the member shell's header exposed them.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _AccountHeaderCard(
            name: profile?.fullName ?? '—',
            email: profile?.email ?? '',
            initials: profile?.initials ?? '?',
            photoUrl: profile?.photoUrl,
            role: profile?.role,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Fund management'),
          _MenuGroup(
            items: [
              _MenuItem(
                icon: Icons.account_balance_outlined,
                label: 'Fund rules & accounts',
                subtitle: 'Contribution amount, payment accounts, lending policy',
                onTap: () => context.push(RoutePaths.adminFundRules),
              ),
              _MenuItem(
                icon: Icons.bar_chart_outlined,
                label: 'Reports',
                onTap: () => context.push(RoutePaths.adminReports),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => context.push(RoutePaths.adminNotifications),
              ),
              _MenuItem(
                icon: Icons.campaign_outlined,
                label: 'Campaigns',
                onTap: () => context.push(RoutePaths.adminCampaigns),
              ),
              _MenuItem(
                icon: Icons.report_problem_outlined,
                label: 'Disputes',
                onTap: () => context.push(RoutePaths.adminDisputes),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy settings',
                onTap: () => context.push(RoutePaths.adminPrivacySettings),
              ),
              _MenuItem(
                icon: Icons.history_outlined,
                label: 'Audit trail',
                subtitle: 'Every change, kept with its reason',
                onTap: () => context.push(RoutePaths.adminAudit),
              ),
            ],
          ),
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
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'App settings',
                subtitle: 'Appearance, language, app lock, email',
                onTap: () => context.push(RoutePaths.profileSettings),
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                label: 'Terms & conditions',
                subtitle: "The fund's 16 bylaws",
                onTap: () => context.push(RoutePaths.profileTerms),
              ),
            ],
          ),
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

class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.role,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String initials;
  final String? photoUrl;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (role) {
      UserRole.superAdmin => 'Super Admin',
      UserRole.admin => 'Admin',
      _ => 'Member',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: initials, imageUrl: photoUrl, radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: roleLabel, tone: StatusTone.positive),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(fontSize: 12.5, color: context.colors.textTertiary),
                ),
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
                      style: TextStyle(fontSize: 11.5, color: colors.textQuaternary),
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
