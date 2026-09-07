import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Uploads images directly from the Flutter client to Cloudinary using an
/// **unsigned** upload preset.
///
/// Deliberately does NOT use the Cloudinary API secret: any secret embedded
/// in a mobile app can be extracted from the compiled APK/IPA, which would
/// let an attacker upload/transform/delete assets on this Cloudinary
/// account indefinitely. The cloud name below is a public identifier (every
/// Cloudinary upload URL contains it) — not a credential — so it's safe to
/// ship in the client. [uploadPreset] must be created once in the
/// Cloudinary console with **Signing Mode: Unsigned** (Settings → Upload →
/// Upload presets); configure it there with folder/format/size
/// restrictions to control what unsigned callers can upload.
class CloudinaryService {
  static const String cloudName = 'qgqkws4z';
  static const String uploadPreset = 'hamro_kosh_unsigned';

  static final Uri _uploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  /// Uploads [file] and returns its Cloudinary `secure_url`. Images are
  /// uploaded as-is; use a Cloudinary named transformation on the preset
  /// (rather than client-side resizing) to keep optimization consistent
  /// across the app.
  Future<String> uploadImage(File file, {String folder = 'hamro_kosh'}) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw CloudinaryUploadException(response.statusCode, response.body);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}

class CloudinaryUploadException implements Exception {
  CloudinaryUploadException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Cloudinary upload failed ($statusCode): $body';
}
