import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import 'app_snackbar.dart';

/// A rectangular photo-attach control for receipts/proof images — payment
/// proof (SRS §14), expense receipts, loan documents — sharing the same
/// image_picker + Cloudinary plumbing as [AvatarPicker] without forcing a
/// circular crop.
class ProofPicker extends StatefulWidget {
  const ProofPicker({
    super.key,
    required this.currentUrl,
    required this.onChanged,
    this.folder = 'hamro_kosh/proofs',
    this.label = 'Attach proof (optional)',
  });

  final String? currentUrl;
  final ValueChanged<String?> onChanged;
  final String folder;
  final String label;

  @override
  State<ProofPicker> createState() => _ProofPickerState();
}

class _ProofPickerState extends State<ProofPicker> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final url = await _cloudinary.uploadImage(
        File(picked.path),
        folder: widget.folder,
      );
      widget.onChanged(url);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Upload failed',
          message: 'Could not upload the photo. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.currentUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: widget.currentUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => widget.onChanged(null),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _uploading ? null : _pickAndUpload,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Center(
          child: _uploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
