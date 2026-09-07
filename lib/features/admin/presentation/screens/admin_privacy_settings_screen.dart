import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_toggle.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/privacy_settings.dart';
import '../../providers/admin_providers.dart';

/// SRS §29 — configurable member-to-member visibility. See
/// `PrivacySettings`'s doc comment for which fields are (and deliberately
/// aren't) toggleable and why.
class AdminPrivacySettingsScreen extends ConsumerWidget {
  const AdminPrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy settings')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) => _PrivacyForm(settings: data),
      ),
    );
  }
}

class _PrivacyForm extends ConsumerWidget {
  const _PrivacyForm({required this.settings});

  final PrivacySettings settings;

  Future<void> _update(
    WidgetRef ref,
    PrivacySettings updated, {
    required String settingLabel,
    required bool newValue,
  }) {
    final uid = ref.read(authStateProvider).value?.uid ?? '';
    return ref
        .read(privacyRepositoryProvider)
        .updateWithAudit(
          settings: updated,
          settingLabel: settingLabel,
          newValue: newValue,
          performedBy: uid,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'These control what an ordinary member can see about other '
          'members — not what admins can see, and not the fund ledger '
          '(contributions/loans/expenses stay transparent to everyone by '
          "design, per this app's core principle).",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show contribution totals'),
          subtitle: const Text(
            "Other members can see a member's total contributed",
          ),
          value: settings.showContributionAmounts,
          onChanged: (value) => _update(
            ref,
            settings.copyWith(showContributionAmounts: value),
            settingLabel: 'Show contribution totals',
            newValue: value,
          ),
        ),
        AppSwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show active loan status'),
          subtitle: const Text(
            'Other members can see whether someone has an outstanding loan',
          ),
          value: settings.showActiveLoanStatus,
          onChanged: (value) => _update(
            ref,
            settings.copyWith(showActiveLoanStatus: value),
            settingLabel: 'Show active loan status',
            newValue: value,
          ),
        ),
        AppSwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show phone number'),
          subtitle: const Text("Other members can see a member's phone number"),
          value: settings.showPhoneNumber,
          onChanged: (value) => _update(
            ref,
            settings.copyWith(showPhoneNumber: value),
            settingLabel: 'Show phone number',
            newValue: value,
          ),
        ),
      ],
    );
  }
}
