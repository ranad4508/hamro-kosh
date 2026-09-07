import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/disputes_providers.dart';

/// SRS "Report transaction issues" — a member raises a dispute/issue for
/// an admin to review.
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).value?.uid;
    final memberName = ref.read(userProfileProvider).value?.fullName;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(disputesRepositoryProvider)
          .submit(
            uid: uid,
            memberName: memberName ?? 'Member',
            subject: _subject.text.trim(),
            description: _description.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Report submitted',
          message: 'An admin will review it shortly.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not submit',
          message: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              label: 'Subject',
              controller: _subject,
              validator: (v) => Validators.required(v, field: 'Subject'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'What happened?',
              controller: _description,
              maxLines: 5,
              validator: (v) => Validators.required(v, field: 'Description'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit report',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
