import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/walkthrough_controller.dart';

class _WalkthroughSlide {
  const _WalkthroughSlide(
    this.icon,
    this.titleEn,
    this.titleNe,
    this.bodyEn,
    this.bodyNe,
  );

  final IconData icon;
  final String titleEn;
  final String titleNe;
  final String bodyEn;
  final String bodyNe;
}

const _slides = [
  _WalkthroughSlide(
    Icons.account_balance_outlined,
    'Home is your balance, at a glance',
    'गृह पृष्ठमा तपाईंको मुख्य जानकारी',
    "See the fund's balance, how much is in hand versus lent out, and "
        'whether you are caught up on your own months — all in one card, '
        'every time you open the app.',
    'कोषको ब्यालेन्स, कति रकम हातमा छ र कति ऋणमा गएको छ, र तपाईं आफ्नो महिना '
        'पुर्‍याउनुभएको छ कि छैन — सबै एउटै कार्डमा देखिन्छ।',
  ),
  _WalkthroughSlide(
    Icons.volunteer_activism_outlined,
    'Give — add your monthly contribution',
    'दिनुहोस् — मासिक योगदान थप्नुहोस्',
    'Pick how much and which months it covers, choose eSewa, Khalti, bank '
        'transfer, or cash to an admin, and attach proof if needed. An admin '
        'verifies it, usually the same day.',
    'रकम र महिना छान्नुहोस्, भुक्तानी विधि छान्नुहोस्, र आवश्यक भए प्रमाण संलग्न '
        'गर्नुहोस्। प्रशासकले प्रायः त्यसै दिन पुष्टि गर्नेछन्।',
  ),
  _WalkthroughSlide(
    Icons.receipt_long_outlined,
    'Ledger — every rupee, traceable',
    'खाताबही — हरेक रुपैयाँको हिसाब',
    'Every entry the fund has ever recorded — money in, money out, who '
        'verified it — is visible to you. Nothing is ever deleted; a '
        'correction is added, never hidden.',
    'कोषले अहिलेसम्म राखेको हरेक हिसाब तपाईंले हेर्न सक्नुहुन्छ। कुनै पनि प्रविष्टि कहिल्यै '
        'मेटिँदैन।',
  ),
  _WalkthroughSlide(
    Icons.request_quote_outlined,
    'Loans — know the cost before you ask',
    'ऋण — माग्नु अघि नै लागत थाहा पाउनुहोस्',
    'See exactly what a loan will cost on time, and what a late payment '
        'adds, before you submit a request — not buried in fine print '
        'afterwards.',
    'अनुरोध पठाउनु अघि नै ऋणको लागत र ढिलो भुक्तानीको जरिवाना स्पष्ट रूपमा देख्नुहुन्छ।',
  ),
  _WalkthroughSlide(
    Icons.groups_outlined,
    'Members — a transparent community',
    'सदस्यहरू — पारदर्शी समुदाय',
    "See who's contributed, who's borrowing, and how the group is doing "
        'together. Your phone number and email stay private unless you '
        'choose to share them.',
    'को-कसले योगदान गरेको छ, को-कसले ऋण लिएको छ भन्ने कुरा पारदर्शी रूपमा देख्न सकिन्छ।',
  ),
];

/// A short, skippable tour of the member app's core screens — Home, Give,
/// Ledger, Loans, Members — shown once after a member's first successful
/// sign-in (gated in `auth_redirect.dart` via [walkthroughSeenControllerProvider])
/// and re-openable any time from Profile's "App walkthrough" menu item.
class MemberWalkthroughScreen extends ConsumerStatefulWidget {
  const MemberWalkthroughScreen({super.key});

  @override
  ConsumerState<MemberWalkthroughScreen> createState() =>
      _MemberWalkthroughScreenState();
}

class _MemberWalkthroughScreenState
    extends ConsumerState<MemberWalkthroughScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      await ref.read(walkthroughSeenControllerProvider.notifier).markSeen(uid);
    }
    if (!mounted) return;
    // Reached the first time (forced by the router, nothing to pop back to)
    // vs. replayed from Profile's "App walkthrough" item (pushed, so pop
    // back to where the member came from instead of jumping to Home).
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: TextButton(
                  onPressed: _finish,
                  child: const BilingualText(
                    'Skip',
                    'छोड्नुहोस्',
                    layout: BilingualLayout.inline,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: colors.accentDark2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 36, color: colors.accentLight),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        BilingualText(
                          slide.titleEn,
                          slide.titleNe,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        BilingualText(
                          slide.bodyEn,
                          slide.bodyNe,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? colors.accent : colors.neutralRing,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: isLast ? 'Get started' : 'Next',
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
