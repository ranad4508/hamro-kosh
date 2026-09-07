import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../members/providers/members_providers.dart';
import '../../data/audit_log_entry.dart';
import '../../providers/admin_providers.dart';

/// SRS §40 — full audit trail of administrative actions: who did what, and
/// what changed.
class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(auditLogProvider);
    final members = ref.watch(allMembersProvider).value ?? const [];
    final namesByUid = {for (final m in members) m.uid: m.fullName};

    String actorName(String uid) {
      if (uid == 'system') return 'System';
      return namesByUid[uid] ?? uid;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Trail')),
      body: log.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.history_outlined,
              title: 'No audit entries yet',
              message: 'Administrative actions will be logged here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _AuditTile(
              entry: entries[index],
              actorName: actorName(entries[index].performedBy),
            ),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry, required this.actorName});

  final AuditLogEntry entry;
  final String actorName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.performedBy == 'system'
            ? Icons.dns_outlined
            : Icons.receipt_long_outlined,
      ),
      title: Text(entry.action),
      subtitle: Text('$actorName • ${DateFormatter.dateTime(entry.timestamp)}'),
      trailing: entry.newValue == null
          ? null
          : Text(
              entry.newValue!,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
