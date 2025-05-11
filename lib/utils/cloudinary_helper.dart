// lib/utils/cloudinary_helper.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants.dart';

Future<String> uploadToCloudinary(
    dynamic src, String claimId, String spot) async {
  final publicId =
      'claim_photos/$claimId/$spot/${DateTime.now().millisecondsSinceEpoch}';

  final req = http.MultipartRequest('POST', Uri.parse(uploadUrl))
    ..fields['upload_preset'] = uploadPreset
    ..fields['public_id']    = publicId;

  if (src is File) {
    req.files.add(await http.MultipartFile.fromPath(
      'file',
      src.path,
      contentType: MediaType('image', 'jpeg'),
    ));
  } else if (src is Uint8List) {
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      src,
      filename: 'frame.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
  }

  final res  = await req.send();
  final body = await http.Response.fromStream(res);
  if (res.statusCode != 200) {
    throw Exception('Cloudinary ${res.statusCode}: ${body.body}');
  }
  final url = (jsonDecode(body.body) as Map)['secure_url'] as String?;
  if (url == null || url.isEmpty) throw Exception('No secure_url returned');
  return url;
}
