import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../contributions/data/campaign.dart';
import '../../../contributions/providers/campaigns_providers.dart';

/// SRS §15 — admin creates a named special-contribution campaign with a
/// target amount and a date window (e.g. "Dashain Contribution 2083").
class AdminCreateCampaignScreen extends ConsumerStatefulWidget {
  const AdminCreateCampaignScreen({super.key});

  @override
  ConsumerState<AdminCreateCampaignScreen> createState() =>
      _AdminCreateCampaignScreenState();
}

class _AdminCreateCampaignScreenState
    extends ConsumerState<AdminCreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      AppSnackbar.showError(
        context,
        title: 'Invalid dates',
        message: 'End date must be on or after the start date.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      await ref
          .read(campaignsRepositoryProvider)
          .createCampaign(
            Campaign(
              id: '',
              name: _name.text.trim(),
              description: _description.text.trim(),
              targetAmount: double.parse(_target.text.trim()),
              startDate: _startDate,
              endDate: _endDate,
              createdBy: uid,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Campaign created',
          message: 'Members can now contribute toward it.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not create campaign',
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
      appBar: AppBar(title: const Text('New campaign')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              label: 'Campaign name (e.g. Dashain Contribution 2083)',
              controller: _name,
              validator: (v) => Validators.required(v, field: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Description',
              controller: _description,
              maxLines: 3,
              validator: (v) => Validators.required(v, field: 'Description'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Target amount (NPR)',
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'Rs. ',
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(
                      'Start: ${DateFormatter.shortDate(_startDate)}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text('End: ${DateFormatter.shortDate(_endDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Create campaign',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
