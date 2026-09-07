import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../notifications/providers/notifications_providers.dart';

/// SRS §33 — admins compose and publish community announcements, which the
/// member notification center's Announcements tab reads from the same
/// `announcements` collection.
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
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'publishedAt': Timestamp.now(),
      });
      _title.clear();
      _body.clear();
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: 'Announcement published',
          message: 'All members will see it in their notification center.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not publish',
          message: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
                  'New announcement',
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
                AppButton(
                  label: 'Publish',
                  isLoading: _sending,
                  onPressed: _publish,
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
                      trailing: Text(DateFormatter.shortDate(item.publishedAt)),
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
