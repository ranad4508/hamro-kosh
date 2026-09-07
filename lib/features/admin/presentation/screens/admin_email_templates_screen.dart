import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';

/// SRS §28, design_spec.md §4f — admin editor for transactional emails.
/// Allows customizing the subject and body of automatic notifications like
/// contribution receipts and loan approvals.
class AdminEmailTemplatesScreen extends ConsumerStatefulWidget {
  const AdminEmailTemplatesScreen({super.key});

  @override
  ConsumerState<AdminEmailTemplatesScreen> createState() =>
      _AdminEmailTemplatesScreenState();
}

class _AdminEmailTemplatesScreenState
    extends ConsumerState<AdminEmailTemplatesScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedType = 'contribution_receipt';
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  final Map<String, String> _types = {
    'contribution_receipt': 'Contribution Receipt',
    'loan_approved': 'Loan Approved',
    'repayment_reminder': 'Repayment Reminder',
    'announcement': 'New Announcement',
  };

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    setState(() => _loading = true);
    try {
      final doc = await _db.collection('email_templates').doc(_selectedType).get();
      if (doc.exists) {
        final data = doc.data()!;
        _subject.text = data['subject'] as String? ?? '';
        _body.text = data['body'] as String? ?? '';
      } else {
        _subject.clear();
        _body.clear();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _db.collection('email_templates').doc(_selectedType).set({
        'subject': _subject.text.trim(),
        'body': _body.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: 'Template saved',
          message: 'Changes applied to future emails.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Save failed',
          message: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Templates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text(
                  'Select template to edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: _types.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedType = v);
                      _loadTemplate();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email Subject',
                  controller: _subject,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email Body',
                  controller: _body,
                  maxLines: 10,
                  hintText: 'Use placeholders like {name}, {amount}, {date}',
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Placeholders',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        '{name} - Member Full Name\n'
                        '{amount} - NPR Amount\n'
                        '{date} - Transaction Date\n'
                        '{id} - Transaction/Loan ID',
                        style: TextStyle(fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Save template',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
