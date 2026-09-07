import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bilingual_text.dart';
import 'initials_avatar.dart';

/// The design's `.hd` header pattern: an optional leading control (back
/// chevron, or an avatar that opens Profile), a title block (bilingual
/// title, with an optional kicker line above or step-counter/tag trailing),
/// and an optional trailing widget. Placed at the top of a screen's body
/// column rather than as a `Scaffold.appBar`, since the design's header
/// sits flush with the body rather than as a separate Material app bar.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.titleEn,
    required this.titleNe,
    this.kickerEn,
    this.kickerNe,
    this.showBackButton = false,
    this.onBack,
    this.avatarInitials,
    this.avatarUrl,
    this.onAvatarTap,
    this.trailing,
  });

  final String titleEn;
  final String titleNe;
  final String? kickerEn;
  final String? kickerNe;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? avatarInitials;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: context.colors.textSecondary,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            )
          else if (avatarInitials != null)
            GestureDetector(
              onTap: onAvatarTap,
              child: InitialsAvatar(
                initials: avatarInitials!,
                imageUrl: avatarUrl,
                radius: 18,
              ),
            ),
          if (showBackButton || avatarInitials != null)
            const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kickerEn != null)
                  BilingualText(
                    kickerEn!,
                    kickerNe!,
                    layout: BilingualLayout.inline,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                BilingualText(
                  titleEn,
                  titleNe,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
