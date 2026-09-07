import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../members/providers/members_providers.dart';
import '../../data/audit_log_entry.dart';
import '../../providers/admin_providers.dart';

/// SRS §40 — full audit trail of administrative actions: who did what, and
/// what changed. Each row shows only the basics (what happened, who, when)
/// — tapping opens a bottom sheet with the complete record (previous
/// value, new value, and the required reason), rather than cramming
/// everything into the list row itself.
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
        color: context.colors.textSecondary,
      ),
      title: Text(entry.action, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('$actorName • ${DateFormatter.relative(entry.timestamp)}'),
      trailing: Icon(Icons.chevron_right, color: context.colors.textQuaternary),
      onTap: () => _showAuditDetailSheet(context, entry, actorName),
    );
  }
}

Future<void> _showAuditDetailSheet(
  BuildContext context,
  AuditLogEntry entry,
  String actorName,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _AuditDetailSheet(entry: entry, actorName: actorName),
  );
}

class _AuditDetailSheet extends StatelessWidget {
  const _AuditDetailSheet({required this.entry, required this.actorName});

  final AuditLogEntry entry;
  final String actorName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Most Cloud Functions fold the reason into `action`'s text (e.g.
    // `Corrected transaction X (+NPR Y): "tent was cheaper"`) rather than
    // the dedicated `reason` field — fall back to extracting it the same
    // way `AuditLine` does, so the sheet still surfaces it either way.
    final reason =
        entry.reason ??
        RegExp(r'["“](.+?)["”]').firstMatch(entry.action)?.group(1);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.action, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(label: 'Actor', value: actorName),
            _DetailRow(
              label: 'Date & time',
              value: DateFormatter.dateTime(entry.timestamp),
            ),
            if (entry.previousValue != null)
              _DetailRow(label: 'Previous value', value: entry.previousValue!),
            if (entry.newValue != null)
              _DetailRow(label: 'New value', value: entry.newValue!),
            if (reason != null && reason.isNotEmpty)
              _DetailRow(label: 'Reason', value: reason, isQuote: true),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Audit entries are permanent and never edited or removed.',
              style: TextStyle(fontSize: 11.5, color: colors.textQuaternary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isQuote = false,
  });

  final String label;
  final String value;
  final bool isQuote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
              color: colors.textQuaternary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isQuote ? '"$value"' : value,
            style: TextStyle(
              fontSize: 14,
              fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
