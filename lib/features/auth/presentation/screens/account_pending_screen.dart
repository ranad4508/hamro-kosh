import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/app_user.dart';
import '../../providers/auth_providers.dart';

/// Shown for a signed-in Firebase Auth user whose account isn't usable —
/// either no Firestore profile exists at all, or an admin disabled it.
/// There is no approval step to wait on: registering with a valid invite
/// code (or being created by an admin/super admin) makes an account active
/// immediately, so this screen only ever appears for those two edge cases.
class AccountPendingScreen extends ConsumerWidget {
  const AccountPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(accountStatusProvider) ?? AccountStatus.noProfile;

    final (String titleEn, String messageEn, IconData icon) = switch (status) {
      AccountStatus.noProfile => (
        'Account not set up',
        "We couldn't find a profile for this account. Please contact an "
            'administrator.',
        Icons.person_off_outlined,
      ),
      AccountStatus.disabled => (
        'Account disabled',
        'Your account has been disabled. Please contact an administrator '
            'if you believe this is a mistake.',
        Icons.block_outlined,
      ),
      AccountStatus.active => ('', '', Icons.check_circle_outline),
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetPaths.logoMark, height: 72),
                const SizedBox(height: AppSpacing.xl),
                Icon(icon, size: 56, color: context.colors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  titleEn,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  messageEn,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppOutlinedButton(
                  label: 'Sign out',
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
