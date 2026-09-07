import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/security/app_lock_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/email_preferences.dart';
import '../../providers/profile_providers.dart';

/// SRS §46, §47 + the app-lock/localization additions (SRS.md §58) —
/// appearance, language, security, and notification preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final appLockEnabled = ref.watch(appLockSettingProvider);
    final emailPrefs =
        ref.watch(emailPreferencesProvider).value ?? EmailPreferences.defaults;
    final uid = ref.watch(authStateProvider).value?.uid;

    Future<void> updateEmailPrefs(EmailPreferences next) async {
      if (uid == null) return;
      await ref.read(emailPreferencesRepositoryProvider).update(uid, next);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref
                .read(themeModeControllerProvider.notifier)
                .setThemeMode(selection.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Language', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<Locale?>(
            segments: const [
              ButtonSegment(value: null, label: Text('System')),
              ButtonSegment(value: Locale('en'), label: Text('English')),
              ButtonSegment(value: Locale('ne'), label: Text('नेपाली')),
            ],
            selected: {locale},
            onSelectionChanged: (selection) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(selection.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Security', style: Theme.of(context).textTheme.titleSmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('App lock'),
            subtitle: const Text(
              'Require biometric/device unlock to open the app',
            ),
            value: appLockEnabled,
            onChanged: (value) =>
                ref.read(appLockSettingProvider.notifier).setEnabled(value),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Email notifications',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Critical account emails are always sent — these control the '
            'rest.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Contribution confirmations'),
            value: emailPrefs.contributionConfirmations,
            onChanged: (value) => updateEmailPrefs(
              emailPrefs.copyWith(contributionConfirmations: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loan updates'),
            value: emailPrefs.loanUpdates,
            onChanged: (value) =>
                updateEmailPrefs(emailPrefs.copyWith(loanUpdates: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repayment reminders'),
            value: emailPrefs.repaymentReminders,
            onChanged: (value) => updateEmailPrefs(
              emailPrefs.copyWith(repaymentReminders: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Monthly reports'),
            value: emailPrefs.monthlyReports,
            onChanged: (value) =>
                updateEmailPrefs(emailPrefs.copyWith(monthlyReports: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Community announcements'),
            value: emailPrefs.communityAnnouncements,
            onChanged: (value) => updateEmailPrefs(
              emailPrefs.copyWith(communityAnnouncements: value),
            ),
          ),
        ],
      ),
    );
  }
}
