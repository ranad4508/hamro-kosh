/// Centralized paths to bundled image assets so screens never hardcode
/// asset strings directly.
abstract final class AssetPaths {
  static const String _images = 'assets/images';

  static const String logoFull = '$_images/hk_logo_no_bg.png';
  static const String logoMark = '$_images/hk_logo_only.png';
  static const String logoJpg = '$_images/hamro_kosh_logo.jpg';

  /// Cropped + safe-zone-padded version of [logoFull], generated so none of
  /// its pixels get clipped by Android's masked splash-icon treatment
  /// (Android 12+ insets splash icons into a safe circle — an
  /// edge-to-edge source image gets visibly cropped there otherwise).
  static const String logoSplash = '$_images/hk_logo_splash.png';

  /// Same safe-zone treatment as [logoSplash], but cropped from [logoMark]
  /// (the icon alone, no wordmark) — used for the native OS splash and as
  /// the icon half of the animated Dart splash, which draws the "HAMRO
  /// KOSH" wordmark itself as text so it can animate in independently.
  static const String logoIconSplash = '$_images/hk_icon_splash.png';
}
