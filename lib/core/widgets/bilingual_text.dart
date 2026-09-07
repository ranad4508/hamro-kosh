import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

/// Renders an English string and its Nepali translation together —
/// English-primary/Nepali-secondary by default, or swapped when the user
/// has chosen Nepali as their leading language (the join screen's
/// "Choose your language" toggle, `design_spec.md` §5). Both languages are
/// **always shown**; this is not a locale switch that hides one of them.
///
/// This is the single most-repeated pattern in the reference design — English
/// label, Nepali translation directly beneath (or after a `·`) in a smaller,
/// dimmer style — so nearly every label/button/heading in the app should go
/// through this widget rather than a bare [Text].
class BilingualText extends ConsumerWidget {
  const BilingualText(
    this.en,
    this.ne, {
    super.key,
    this.style,
    this.secondaryStyle,
    this.layout = BilingualLayout.stacked,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String en;
  final String ne;
  final TextStyle? style;
  final TextStyle? secondaryStyle;
  final BilingualLayout layout;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final nepaliLeads = locale?.languageCode == 'ne';
    final colors = context.colors;

    final primaryText = nepaliLeads ? ne : en;
    final secondaryText = nepaliLeads ? en : ne;

    final basePrimaryStyle = style ?? DefaultTextStyle.of(context).style;
    final primaryStyle = nepaliLeads
        ? notoSansDevanagari(
            fontSize: basePrimaryStyle.fontSize ?? 14,
            fontWeight: basePrimaryStyle.fontWeight ?? FontWeight.w400,
            color: basePrimaryStyle.color ?? colors.textPrimary,
          )
        : basePrimaryStyle;

    final baseSecondarySize = (basePrimaryStyle.fontSize ?? 14) * 0.88;
    final secondaryTextStyle =
        secondaryStyle ??
        (nepaliLeads
            ? basePrimaryStyle.copyWith(
                fontSize: baseSecondarySize,
                color: colors.textTertiary,
                fontWeight: FontWeight.w400,
              )
            : notoSansDevanagari(
                fontSize: baseSecondarySize,
                color: colors.textTertiary,
              ));

    if (layout == BilingualLayout.inline) {
      return Text.rich(
        TextSpan(
          style: primaryStyle,
          children: [
            TextSpan(text: primaryText),
            const TextSpan(text: '  ·  '),
            TextSpan(text: secondaryText, style: secondaryTextStyle),
          ],
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
      );
    }

    if (layout == BilingualLayout.primaryOnly) {
      return Text(
        primaryText,
        style: primaryStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryText,
          style: primaryStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
        Text(
          secondaryText,
          style: secondaryTextStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ],
    );
  }
}

enum BilingualLayout {
  /// English line, Nepali line beneath (or vice versa) — the design's most
  /// common pattern for headings/labels.
  stacked,

  /// "English  ·  नेपाली" on one line — used for compact captions.
  inline,

  /// Renders only the leading language, no secondary line — for contexts
  /// (e.g. a button that must fit one line) where the design shows a single
  /// bilingual toggle rather than both languages stacked.
  primaryOnly,
}
