import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The design's `.av` component: a circular avatar showing a member's photo
/// when available, otherwise their two-letter initials on a tinted accent
/// background (`design_spec.md` §2) — used throughout member rows, headers,
/// and admin radio-pickers. Read-only; see `AvatarPicker` for the editable
/// upload variant used on Edit Profile.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.radius = 20,
  });

  /// Full name to derive initials from, e.g. "Sabin Karki" → "SK". Pass
  /// already-computed initials directly, or use [InitialsAvatar.fromName].
  final String initials;
  final String? imageUrl;
  final double radius;

  factory InitialsAvatar.fromName(
    String name, {
    Key? key,
    String? imageUrl,
    double radius = 20,
  }) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return InitialsAvatar(
      key: key,
      initials: letters.isEmpty ? '?' : letters,
      imageUrl: imageUrl,
      radius: radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.accentDark2,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.accentDark2,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.accentLightest,
          fontWeight: FontWeight.w500,
          fontSize: radius * 0.55,
        ),
      ),
    );
  }
}
