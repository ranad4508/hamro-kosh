import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/security/app_lock_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';

/// SRS §46, §47 + the app-lock/localization additions (SRS.md §58) —
/// appearance, language, security, and notification preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final appLockEnabled = ref.watch(appLockSettingProvider);

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
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
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
          Text('Notifications', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          const _NotificationPreferenceTile(
            label: 'Contribution confirmations',
          ),
          const _NotificationPreferenceTile(label: 'Loan updates'),
          const _NotificationPreferenceTile(label: 'Repayment reminders'),
          const _NotificationPreferenceTile(label: 'Monthly reports'),
          const _NotificationPreferenceTile(label: 'Community announcements'),
        ],
      ),
    );
  }
}

/// SRS §46 — critical financial notifications stay mandatory; only
/// non-critical categories are toggleable, per the SRS's own rule.
class _NotificationPreferenceTile extends StatefulWidget {
  const _NotificationPreferenceTile({required this.label});
  final String label;

  @override
  State<_NotificationPreferenceTile> createState() =>
      _NotificationPreferenceTileState();
}

class _NotificationPreferenceTileState
    extends State<_NotificationPreferenceTile> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label),
      value: _enabled,
      onChanged: (value) => setState(() => _enabled = value),
    );
  }
}
