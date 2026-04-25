import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/data/sources/api/api_client.dart';
import 'package:sage/data/sources/auth/auth_token_provider.dart';
import 'package:sage/service_locator.dart';

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
  // Kept in constructor to avoid churn in service locator wiring.
  // ignore: unused_field
  final http.Client _client;
  // ignore: unused_field
  final SharedPreferences _preferences;
  final ApiClient _apiClient = sl<ApiClient>();
  final AuthTokenProvider _tokenProvider = sl<AuthTokenProvider>();

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
      final token = _tokenProvider.getToken();
      if (token == null || token.isEmpty) {
        return const Left('Please sign in before uploading notes.');
      }

      final bytes = file.bytes;
      if (bytes == null) {
        return const Left('Unable to read the selected file.');
      }

      final request = http.MultipartRequest('POST', Uri.parse(ApiUrls.uploads))
        ..headers.addAll(
          _apiClient.headers(
            json: false,
            authenticated: true,
          ),
        )
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
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in before viewing usage limits.');
    }
    final result = await _apiClient.getJson(ApiUrls.uploadLimits);
    return result.fold((l) => Left(l), (r) => Right(r));
  }

  @override
  Future<Either> listUploads() async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in before viewing uploads.');
    }
    final result = await _apiClient.getJson(ApiUrls.uploads);
    return result.fold((l) => Left(l), (r) => Right(r));
  }

  @override
  Future<Either> getUploadStatus(String documentId) async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in before viewing upload status.');
    }
    final result = await _apiClient.getJson(ApiUrls.uploadStatus(documentId));
    return result.fold((l) => Left(l), (r) => Right(r));
  }

  @override
  Future<Either> deleteUpload(String documentId) async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in before deleting uploads.');
    }

    final result = await _apiClient.deleteJson(ApiUrls.uploadById(documentId));
    return result.fold((l) => Left(l), (_) => const Right(true));
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
