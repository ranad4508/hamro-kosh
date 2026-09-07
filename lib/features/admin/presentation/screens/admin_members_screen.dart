import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/models/loan_status.dart';
import '../../../members/data/member_directory_entry.dart';
import '../../../members/providers/members_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §35 — approve/reject registrations, enable/disable members. Also
/// the entry point for directly provisioning an account (SRS.md §58 RBAC
/// addition), via [RoutePaths.adminCreateUser].
class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(allMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        actions: const [AdminMoreMenu()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SearchBar(
              hintText: 'Search members',
              leading: const Icon(Icons.search),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.adminCreateUser),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Create account'),
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (allItems) {
          if (allItems.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No members yet',
            );
          }
          final items = _query.isEmpty
              ? allItems
              : allItems
                    .where((m) => m.fullName.toLowerCase().contains(_query))
                    .toList();
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No matching members',
            );
          }
          final pending = items.where((m) => !m.isApproved).toList();
          final approved = items.where((m) => m.isApproved).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (pending.isNotEmpty) ...[
                Text(
                  'Pending approval',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final member in pending) _MemberTile(member: member),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Members', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final member in approved) _MemberTile(member: member),
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});

  final MemberDirectoryEntry member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(membersRepositoryProvider);

    Future<void> run(
      Future<void> Function() action, {
      required String successMessage,
    }) async {
      try {
        await action();
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            title: 'Updated',
            message: successMessage,
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            title: 'Could not update member',
            message: 'Something went wrong. Please try again.',
          );
        }
      }
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.photoUrl == null
              ? null
              : NetworkImage(member.photoUrl!),
          child: member.photoUrl == null
              ? Text(member.fullName.isEmpty ? '?' : member.fullName[0])
              : null,
        ),
        title: Text(member.fullName),
        subtitle: Text(
          'Member since ${DateFormatter.monthYear(member.memberSince)}',
        ),
        trailing: !member.isApproved
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Approve',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => run(
                      () => repo.setApproved(member.uid, true),
                      successMessage: '${member.fullName} approved.',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () => run(
                      () => repo.setApproved(member.uid, false),
                      successMessage: '${member.fullName} rejected.',
                    ),
                  ),
                ],
              )
            : PopupMenuButton<bool>(
                onSelected: (active) => run(
                  () => repo.setActive(member.uid, active),
                  successMessage:
                      '${member.fullName} ${active ? 'activated' : 'deactivated'}.',
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: true, child: Text('Activate')),
                  const PopupMenuItem(value: false, child: Text('Deactivate')),
                ],
                child: StatusBadge(
                  label: member.isActive ? 'Active' : 'Disabled',
                  tone: member.isActive
                      ? StatusTone.positive
                      : StatusTone.negative,
                ),
              ),
      ),
    );
  }
}
