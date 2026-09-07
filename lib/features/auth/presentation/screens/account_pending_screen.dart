import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/widgets/app_button.dart';
import '../../providers/auth_providers.dart';

/// Shown for a signed-in Firebase Auth user whose account isn't ready to
/// use the app yet: still awaiting admin approval (SRS §3.4/§35), disabled,
/// or missing a Firestore profile entirely (only reachable via a manually
/// console-created Auth user, but a real possibility — better a clear
/// holding screen than the member shell erroring out on permission-denied
/// reads it can't satisfy).
class AccountPendingScreen extends ConsumerWidget {
  const AccountPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;

    final String title;
    final String message;
    final IconData icon;

    if (profile == null) {
      title = 'Account not set up';
      message =
          "We couldn't find a profile for this account. Please contact "
          'an administrator.';
      icon = Icons.person_off_outlined;
    } else if (!profile.isActive) {
      title = 'Account disabled';
      message =
          'Your account has been disabled. Please contact an '
          'administrator if you believe this is a mistake.';
      icon = Icons.block_outlined;
    } else {
      title = 'Awaiting approval';
      message =
          'An administrator needs to approve your registration before '
          "you can use Hamro Kosh. You'll be able to sign in as soon as "
          "that's done.";
      icon = Icons.hourglass_top_outlined;
    }

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
                Icon(
                  icon,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
