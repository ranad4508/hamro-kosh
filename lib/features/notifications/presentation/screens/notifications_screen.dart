import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/announcement.dart';
import '../../data/notification_item.dart';
import '../../providers/notifications_providers.dart';

/// SRS §29, §33, §45 — notification center + community announcements.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Notifications'),
            Tab(text: 'Announcements'),
          ]),
        ),
        body: const TabBarView(children: [
          _NotificationsTab(),
          _AnnouncementsTab(),
        ]),
      ),
    );
  }
}

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return notifications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: "You're all caught up",
            message: 'Reminders and financial alerts will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _NotificationTile(item: items[index]),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(item.category.icon, size: 20)),
      title: Text(
        item.title,
        style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        DateFormatter.relative(item.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);

    return announcements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No announcements yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _AnnouncementCard(item: items[index]),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(item.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormatter.shortDate(item.publishedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
