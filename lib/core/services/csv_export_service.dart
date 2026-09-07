import 'dart:io';

import 'package:csv/csv.dart' show Csv;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// SRS §43 — CSV export for admin reports/lists. There's no server to host
/// a generated report on, so this writes the CSV to a temp file and hands
/// it to the OS share sheet, where the admin can save it to Drive/email/
/// Files or open it directly in a spreadsheet app.
abstract final class CsvExportService {
  static Future<void> exportAndShare({
    required String fileName,
    required List<List<dynamic>> rows,
    String? shareText,
  }) async {
    final csvString = Csv().encode(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  }
}
