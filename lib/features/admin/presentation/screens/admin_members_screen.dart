import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/models/loan_status.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../members/data/member_directory_entry.dart';
import '../../../members/providers/members_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §35 — enable/disable members. Also the entry point for directly
/// provisioning an account (SRS.md §58 RBAC addition), via
/// [RoutePaths.adminCreateUser]. There is no approval queue and no invite
/// code: only member/admin/superAdmin roles exist, and both self-
/// registration and admin-provisioned accounts are immediately active.
///
/// Hierarchy (per the RBAC addition): a plain admin manages `member`
/// accounts only — admin accounts never appear in their list at all, and
/// `firestore.rules` backs that up so it isn't just a UI omission. Only a
/// super admin sees and manages admin accounts too.
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
    final viewerIsSuperAdmin =
        ref.watch(userProfileProvider).value?.role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () async {
              final items = members.value;
              if (items == null || items.isEmpty) return;
              await _exportMembersCsv(context, items);
            },
          ),
          const AdminMoreMenu(),
        ],
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
        heroTag: 'admin_members_fab',
        onPressed: () => context.push(RoutePaths.adminCreateUser),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Create account'),
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (allItems) {
          // A plain admin's reach stops at `member` accounts — admin
          // accounts (created directly by a super admin) never show up
          // here for them to touch at all.
          final visibleItems = viewerIsSuperAdmin
              ? allItems
              : allItems.where((m) => m.role == UserRole.member).toList();

          if (visibleItems.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No members yet',
            );
          }
          final items = _query.isEmpty
              ? visibleItems
              : visibleItems
                    .where((m) => m.fullName.toLowerCase().contains(_query))
                    .toList();
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No matching members',
            );
          }
          final admins = items.where((m) => m.role == UserRole.admin).toList();
          final regularMembers = items
              .where((m) => m.role == UserRole.member)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (admins.isNotEmpty) ...[
                Text('Admins', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                for (final member in admins) _MemberTile(member: member),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Members', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final member in regularMembers) _MemberTile(member: member),
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
          member.role == UserRole.admin
              ? 'Admin • since ${DateFormatter.monthYear(member.memberSince)}'
              : 'Member since ${DateFormatter.monthYear(member.memberSince)}',
        ),
        trailing: PopupMenuButton<bool>(
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
            tone: member.isActive ? StatusTone.positive : StatusTone.negative,
          ),
        ),
      ),
    );
  }
}

/// SRS §43 — exports the member list as CSV.
Future<void> _exportMembersCsv(
  BuildContext context,
  List<MemberDirectoryEntry> items,
) async {
  final rows = <List<dynamic>>[
    ['Full name', 'Role', 'Phone', 'Member since', 'Active'],
    for (final m in items)
      [
        m.fullName,
        m.role.name,
        m.phone ?? '',
        DateFormatter.shortDate(m.memberSince),
        m.isActive ? 'Yes' : 'No',
      ],
  ];
  await CsvExportService.exportAndShare(
    fileName:
        'hamro_kosh_members_${DateTime.now().toIso8601String().split('T').first}.csv',
    rows: rows,
    shareText: 'Hamro Kosh member list export',
  );
  if (context.mounted) {
    AppSnackbar.showSuccess(
      context,
      title: 'Export ready',
      message: '${items.length} members exported.',
    );
  }
}
