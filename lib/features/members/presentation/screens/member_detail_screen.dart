import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/members_providers.dart';

/// SRS §32 — a member's public financial profile, subject to the app's
/// configured privacy rules (§47) — fields like [totalContributed] are only
/// ever populated server-side when transparency settings allow it.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberDetailProvider(memberId));

    return Scaffold(
      appBar: AppBar(title: const Text('Member profile')),
      body: member.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) {
          if (data == null) {
            return const EmptyState(icon: Icons.person_off_outlined, title: 'Member not found');
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      data.photoUrl == null ? null : NetworkImage(data.photoUrl!),
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
                child: Text(data.fullName, style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(
                child: Text(
                  'Member since ${DateFormatter.monthYear(data.memberSince)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (data.totalContributed != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.volunteer_activism_outlined),
                    title: const Text('Total contributed'),
                    trailing: Text(CurrencyFormatter.format(data.totalContributed!)),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.request_quote_outlined),
                  title: const Text('Active loan'),
                  trailing: Text(data.hasActiveLoan ? 'Yes' : 'None'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
