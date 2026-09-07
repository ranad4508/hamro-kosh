import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../admin/data/privacy_settings.dart';
import '../../../admin/providers/admin_providers.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../loans/providers/loans_providers.dart';
import '../../providers/members_providers.dart';

/// SRS §32 — a member's public financial profile. Total contributed and
/// active-loan status are computed live from the `contributions`/`loans`
/// collections (SRS §7/§12/§54's member-to-member transparency), not read
/// off a denormalized field on the user doc.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberDetailProvider(memberId));
    final totalContributed = ref.watch(
      memberVerifiedContributionsTotalProvider(memberId),
    );
    final hasActiveLoan = ref.watch(memberHasActiveLoanProvider(memberId));
    final privacy =
        ref.watch(privacySettingsProvider).value ?? PrivacySettings.defaults;

    return Scaffold(
      appBar: AppBar(title: const Text('Member profile')),
      body: member.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Member not found',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: data.photoUrl == null
                      ? null
                      : NetworkImage(data.photoUrl!),
                  child: data.photoUrl == null
                      ? Text(
                          data.fullName.isEmpty ? '?' : data.fullName[0],
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  data.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Center(
                child: Text(
                  'Member since ${DateFormatter.monthYear(data.memberSince)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (privacy.showPhoneNumber &&
                  data.phone != null &&
                  data.phone!.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Phone'),
                    trailing: Text(data.phone!),
                  ),
                ),
              if (privacy.showContributionAmounts)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.volunteer_activism_outlined),
                    title: const Text('Total contributed'),
                    trailing: switch (totalContributed) {
                      AsyncData(:final value) => Text(
                        CurrencyFormatter.format(value),
                      ),
                      AsyncError() => const Text('—'),
                      _ => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    },
                  ),
                ),
              if (privacy.showActiveLoanStatus)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.request_quote_outlined),
                    title: const Text('Active loan'),
                    trailing: switch (hasActiveLoan) {
                      AsyncData(:final value) => Text(value ? 'Yes' : 'None'),
                      AsyncError() => const Text('—'),
                      _ => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    },
                  ),
                ),
              if (!privacy.showContributionAmounts &&
                  !privacy.showActiveLoanStatus)
                const EmptyState(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Financial details are private',
                  message:
                      'The admin has hidden this information from other members.',
                ),
            ],
          );
        },
      ),
    );
  }
}
