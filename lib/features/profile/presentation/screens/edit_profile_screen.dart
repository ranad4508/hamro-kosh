import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../auth/providers/auth_providers.dart';

/// SRS §4 — edit the member's own name, phone, and profile photo (uploaded
/// via [AvatarPicker] → Cloudinary).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _fullName = TextEditingController(
    text: ref.read(userProfileProvider).value?.fullName ?? '',
  );
  late final _phone = TextEditingController(
    text: ref.read(userProfileProvider).value?.phone ?? '',
  );
  String? _photoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = ref.read(userProfileProvider).value?.photoUrl;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            uid: uid,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            photoUrl: _photoUrl,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Profile updated',
          message: 'Your changes have been saved.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not save',
          message:
              'Something went wrong updating your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: AvatarPicker(
                currentUrl: _photoUrl,
                onUploaded: (url) => setState(() => _photoUrl = url),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Full name',
              controller: _fullName,
              prefixIcon: Icons.person_outline,
              validator: (v) => Validators.required(v, field: 'Full name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Phone number',
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Save changes',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
