import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/bs_date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/nepali_date_picker.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../contributions/data/campaign.dart';
import '../../../contributions/providers/campaigns_providers.dart';

/// SRS §15 — admin creates or edits a named special-contribution campaign.
class AdminCreateCampaignScreen extends ConsumerStatefulWidget {
  const AdminCreateCampaignScreen({super.key, this.campaign});

  final Campaign? campaign;

  @override
  ConsumerState<AdminCreateCampaignScreen> createState() =>
      _AdminCreateCampaignScreenState();
}

class _AdminCreateCampaignScreenState
    extends ConsumerState<AdminCreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.campaign?.name);
  late final _description =
      TextEditingController(text: widget.campaign?.description);
  late final _target = TextEditingController(
    text: widget.campaign?.targetAmount?.toStringAsFixed(0) ?? '',
  );
  late DateTime _startDate = widget.campaign?.startDate ?? DateTime.now();
  late DateTime _endDate =
      widget.campaign?.endDate ?? DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;

  bool get _isEditing => widget.campaign != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showNepaliDatePicker(
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
      final targetText = _target.text.trim();
      final targetAmount =
          targetText.isEmpty ? null : double.tryParse(targetText);

      final campaign = Campaign(
        id: widget.campaign?.id ?? '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        targetAmount: targetAmount,
        startDate: _startDate,
        endDate: _endDate,
        isPublished: widget.campaign?.isPublished ?? true,
        createdBy: widget.campaign?.createdBy ?? uid,
      );

      final repo = ref.read(campaignsRepositoryProvider);
      if (_isEditing) {
        await repo.updateCampaign(campaign);
      } else {
        await repo.createCampaign(campaign);
      }

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: _isEditing ? 'Campaign updated' : 'Campaign created',
          message: _isEditing
              ? 'Changes have been saved.'
              : 'Members can now contribute toward it.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not save campaign',
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit campaign' : 'New campaign'),
      ),
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
              label: 'Target amount (optional, blank for no limit)',
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'Rs. ',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(
                      'Start: ${BsDateFormatter.full(_startDate)}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text('End: ${BsDateFormatter.full(_endDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isEditing ? 'Save changes' : 'Create campaign',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
