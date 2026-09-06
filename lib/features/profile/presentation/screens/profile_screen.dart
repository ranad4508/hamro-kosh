import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/providers/auth_providers.dart';

/// SRS §4, §32 — the member's own profile, plus entry points to settings
/// and the Terms & Conditions viewer.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage:
                  profile?.photoUrl == null ? null : NetworkImage(profile!.photoUrl!),
              child: profile?.photoUrl == null
                  ? Text(
                      (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName[0] : '?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              profile?.fullName ?? '—',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Center(
            child: Text(
              profile == null ? '' : 'Member since ${DateFormatter.monthYear(profile.memberSince)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(profile?.email ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone'),
                  subtitle: Text(profile?.phone ?? '—'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RoutePaths.profileEdit),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RoutePaths.changePassword),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RoutePaths.profileSettings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RoutePaths.profileTerms),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
