import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import 'app_snackbar.dart';

/// A tappable circular avatar that lets the user pick a photo, uploads it
/// to Cloudinary, and reports the resulting URL — reused by Edit Profile
/// (SRS §4) and, later, any other photo-attach flow (payment proof, loan
/// documents) without re-plumbing image_picker + Cloudinary each time.
class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    required this.currentUrl,
    required this.onUploaded,
    this.radius = 48,
    this.folder = 'hamro_kosh/profile_photos',
  });

  final String? currentUrl;
  final ValueChanged<String> onUploaded;
  final double radius;
  final String folder;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _uploading = false;
  // Set the instant the picker is invoked, not after it resolves — a
  // second tap during the gallery UI's open animation would otherwise
  // call pickImage() again while the first call is still active, which
  // throws PlatformException(already_active) instead of just no-op'ing.
  bool _picking = false;

  Future<void> _pickAndUpload() async {
    if (_picking) return;
    _picking = true;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      try {
        final url = await _cloudinary.uploadImage(
          File(picked.path),
          folder: widget.folder,
        );
        widget.onUploaded(url);
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
    } finally {
      _picking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundImage: widget.currentUrl == null
                ? null
                : CachedNetworkImageProvider(widget.currentUrl!),
            child: widget.currentUrl == null
                ? Icon(Icons.person, size: widget.radius)
                : null,
          ),
          if (_uploading)
            const CircularProgressIndicator()
          else
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
