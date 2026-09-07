import 'package:nepali_utils/nepali_utils.dart';

/// Bikram Sambat (Nepali calendar) date formatting — every date in the
/// reference design is shown in BS, e.g. "2 Bhadra 2083"
/// (`design_spec.md` §5). Wraps `package:nepali_utils` behind one call site
/// so screens never touch `NepaliDateTime`/`NepaliDateFormat` directly.
abstract final class BsDateFormatter {
  /// 3-letter Nepali month abbreviations, index 0 = Baisakh, matching the
  /// month-grid heatmap's column order used on Home/Give/My Record.
  static const monthAbbreviations = [
    'Bai',
    'Jes',
    'Asa',
    'Shr',
    'Bha',
    'Asw',
    'Kar',
    'Man',
    'Pou',
    'Mag',
    'Fal',
    'Cha',
  ];

  static const monthNames = [
    'Baisakh',
    'Jestha',
    'Asar',
    'Shrawan',
    'Bhadra',
    'Aswin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  /// "2 Bhadra 2083"
  static String full(DateTime date) {
    return NepaliDateFormat('d MMMM y', Language.english).format(date.toNepaliDateTime());
  }

  /// "Bhadra 2083"
  static String monthYear(DateTime date) {
    return NepaliDateFormat('MMMM y', Language.english).format(date.toNepaliDateTime());
  }

  /// "Bha" — 3-letter month abbreviation for the month-grid heatmap.
  static String monthAbbr(DateTime date) {
    return monthAbbreviations[date.toNepaliDateTime().month - 1];
  }

  /// The BS month index (1-12, Baisakh = 1) for grid-cell placement.
  static int monthIndex(DateTime date) => date.toNepaliDateTime().month;

  /// The current BS year, e.g. 2083.
  static int currentYear() => NepaliDateTime.now().year;

  /// Devanagari rendering (used beside the English form per the bilingual
  /// pattern), e.g. "२ भदौ २०८३" — `NepaliDateFormat`'s own Devanagari-digit
  /// conversion (via `NepaliUnicode.convert` internally) handles the year
  /// and day numerals, so this just formats with `Language.nepali`.
  static String fullNepali(DateTime date) {
    return NepaliDateFormat('d MMMM y', Language.nepali).format(date.toNepaliDateTime());
  }
}
