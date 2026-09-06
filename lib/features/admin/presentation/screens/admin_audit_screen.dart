import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/admin_providers.dart';

/// SRS §40 — full audit trail of administrative actions.
class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(auditLogProvider);

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
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(entry.action),
                subtitle: Text('${entry.performedBy} • ${DateFormatter.dateTime(entry.timestamp)}'),
              );
            },
          );
        },
      ),
    );
  }
}
