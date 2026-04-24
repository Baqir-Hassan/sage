import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';

abstract class UploadApiService {
  Future<Either> uploadDocument({
    required PlatformFile file,
    required String voiceOption,
    String? subjectId,
    String? subjectName,
  });
  Future<Either> getUploadLimits();
  Future<Either> listUploads();
  Future<Either> getUploadStatus(String documentId);
  Future<Either> deleteUpload(String documentId);
}

class UploadApiServiceImpl extends UploadApiService {
  static const _tokenKey = 'auth_token';

  final http.Client _client;
  final SharedPreferences _preferences;

  UploadApiServiceImpl({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _client = client,
        _preferences = preferences;

  @override
  Future<Either> uploadDocument({
    required PlatformFile file,
    required String voiceOption,
    String? subjectId,
    String? subjectName,
  }) async {
    try {
      final token = _preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return const Left('Please sign in before uploading notes.');
      }

      final bytes = file.bytes;
      if (bytes == null) {
        return const Left('Unable to read the selected file.');
      }

      final request = http.MultipartRequest('POST', Uri.parse(ApiUrls.uploads))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['voice_option'] = voiceOption;

      if (subjectId != null && subjectId.trim().isNotEmpty) {
        request.fields['subject_id'] = subjectId.trim();
      }
      if (subjectName != null && subjectName.trim().isNotEmpty) {
        request.fields['subject_name'] = subjectName.trim();
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = _decodeResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Right(body);
      }

      return Left(_extractError(body, fallback: 'Unable to upload document.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> getUploadLimits() async {
    try {
      final token = _preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return const Left('Please sign in before viewing usage limits.');
      }

      final response = await _client.get(
        Uri.parse(ApiUrls.uploadLimits),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Right(body);
      }

      return Left(_extractError(body, fallback: 'Unable to load usage limits.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> listUploads() async {
    try {
      final token = _preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return const Left('Please sign in before viewing uploads.');
      }

      final response = await _client.get(
        Uri.parse(ApiUrls.uploads),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Right(body);
      }

      return Left(_extractError(body, fallback: 'Unable to load uploads.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> getUploadStatus(String documentId) async {
    try {
      final token = _preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return const Left('Please sign in before viewing upload status.');
      }

      final response = await _client.get(
        Uri.parse(ApiUrls.uploadStatus(documentId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Right(body);
      }

      return Left(_extractError(body, fallback: 'Unable to load upload status.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> deleteUpload(String documentId) async {
    try {
      final token = _preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return const Left('Please sign in before deleting uploads.');
      }

      final response = await _client.delete(
        Uri.parse(ApiUrls.uploadById(documentId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Right(true);
      }

      final body = _decodeResponse(response.body);
      return Left(_extractError(body, fallback: 'Unable to delete upload.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  dynamic _decodeResponse(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(body);
  }

  String _extractError(dynamic body, {required String fallback}) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }
    return fallback;
  }
}
