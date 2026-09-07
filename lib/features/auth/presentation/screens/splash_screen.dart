import 'package:flutter/material.dart';

import '../../../../core/constants/asset_paths.dart';

/// Shown briefly while `bootstrap.dart`/the router resolve Firebase auth
/// state. The native splash (flutter_native_splash) shows just the icon
/// mark for the first frame before Flutter even renders; this Dart-level
/// splash takes over immediately after with its own animation — the icon
/// settles in first, then the "HAMRO KOSH" wordmark animates in as real
/// text (not baked into the image), so the two can move independently.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // Icon: scales/fades in first (0 - 55% of the timeline).
  late final Animation<double> _iconScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _iconFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.4, curve: Curves.easeOut),
  );

  // Wordmark: fades/slides up after the icon has mostly settled (35% - 80%).
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide =
      Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
        ),
      );

  // Progress indicator: last to appear (80% - 100%).
  late final Animation<double> _progressFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.8, 1, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _iconFade,
              child: ScaleTransition(
                scale: _iconScale,
                child: Image.asset(AssetPaths.logoIconSplash, height: 120),
              ),
            ),
            const SizedBox(height: 20),
            ClipRect(
              child: FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Text(
                    'HAMRO KOSH',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: isDark ? Colors.white : const Color(0xFF2B2A3D),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _progressFade,
              child: const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
