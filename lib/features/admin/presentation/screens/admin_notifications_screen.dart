import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../notifications/data/announcement.dart';
import '../../../notifications/providers/notifications_providers.dart';

/// SRS §33 — admins compose, publish, and moderate community announcements.
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  Announcement? _editing;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _startEditing(Announcement item) {
    setState(() {
      _editing = item;
      _title.text = item.title;
      _body.text = item.body;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = null;
      _title.clear();
      _body.clear();
    });
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      if (_editing != null) {
        await repo.updateAnnouncement(
          _editing!.id,
          _title.text.trim(),
          _body.text.trim(),
        );
      } else {
        await FirebaseFirestore.instance.collection('announcements').add({
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          'publishedAt': Timestamp.now(),
        });
      }
      _title.clear();
      _body.clear();
      setState(() => _editing = null);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: _editing != null ? 'Updated' : 'Published',
          message: _editing != null
              ? 'Announcement updated.'
              : 'All members will see it in their notification center.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Error',
          message: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Announcement item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('This will remove it for all members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(notificationsRepositoryProvider)
          .deleteAnnouncement(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _editing != null ? 'Edit announcement' : 'New announcement',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Title',
                  controller: _title,
                  validator: (v) => Validators.required(v, field: 'Title'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(label: 'Message', controller: _body, maxLines: 3),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (_editing != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelEditing,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: AppButton(
                        label: _editing != null ? 'Save changes' : 'Publish',
                        isLoading: _sending,
                        onPressed: _publish,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Published announcements',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          announcements.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppErrorState(message: '$error'),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'None published yet',
                );
              }
              return Column(
                children: [
                  for (final item in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _startEditing(item);
                          if (v == 'delete') _delete(item);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
