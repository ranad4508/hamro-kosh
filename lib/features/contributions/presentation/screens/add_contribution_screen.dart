import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/contribution.dart';
import '../../providers/contributions_providers.dart';

/// SRS §7 — "Add contribution" with payment method + optional proof.
/// Payment-proof upload (image_picker/firebase_storage) is left as a TODO:
/// this screen wires the record-creation path end-to-end already.
class AddContributionScreen extends ConsumerStatefulWidget {
  const AddContributionScreen({super.key});

  @override
  ConsumerState<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends ConsumerState<AddContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _occasion = TextEditingController();
  ContributionCategory _category = ContributionCategory.monthly;
  String _paymentMethod = 'Cash';
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _occasion.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final memberName = ref.read(userProfileProvider).value?.fullName;

    setState(() => _submitting = true);
    try {
      await ref.read(contributionsRepositoryProvider).submit(
            uid,
            Contribution(
              id: '',
              category: _category,
              amount: double.parse(_amount.text.trim()),
              date: DateTime.now(),
              status: ContributionStatus.pending,
              memberUid: uid,
              memberName: memberName,
              occasionName:
                  _category == ContributionCategory.special ? _occasion.text.trim() : null,
              paymentMethod: _paymentMethod,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Contribution submitted',
          message: 'An admin will verify it shortly.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not submit',
          message: 'Something went wrong recording your contribution. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add contribution')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SegmentedButton<ContributionCategory>(
              segments: const [
                ButtonSegment(value: ContributionCategory.monthly, label: Text('Monthly')),
                ButtonSegment(value: ContributionCategory.special, label: Text('Special')),
              ],
              selected: {_category},
              onSelectionChanged: (selection) =>
                  setState(() => _category = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_category == ContributionCategory.special) ...[
              AppTextField(
                label: 'Occasion (e.g. Dashain, Emergency)',
                controller: _occasion,
                validator: (v) => Validators.required(v, field: 'Occasion'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: 'Amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Bank transfer', child: Text('Bank transfer')),
                DropdownMenuItem(value: 'eSewa / Khalti', child: Text('eSewa / Khalti')),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
