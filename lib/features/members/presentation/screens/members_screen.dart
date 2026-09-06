import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/members_providers.dart';

/// SRS §31 — searchable community member directory.
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Members'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm,
            ),
            child: SearchBar(
              hintText: 'Search members',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (items) {
          final filtered = _query.isEmpty
              ? items
              : items.where((m) => m.fullName.toLowerCase().contains(_query)).toList();

          if (filtered.isEmpty) {
            return const EmptyState(icon: Icons.people_outline, title: 'No members found');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final member = filtered[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.photoUrl == null
                      ? null
                      : NetworkImage(member.photoUrl!),
                  child: member.photoUrl == null
                      ? Text(member.fullName.isEmpty ? '?' : member.fullName[0])
                      : null,
                ),
                title: Text(member.fullName),
                subtitle: Text('Member since ${DateFormatter.monthYear(member.memberSince)}'),
                trailing: member.hasActiveLoan
                    ? const Icon(Icons.request_quote_outlined, size: 18)
                    : null,
                onTap: () => context.push(RoutePaths.memberDetail(member.uid)),
              );
            },
          );
        },
      ),
    );
  }
}
