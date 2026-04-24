import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';

abstract class LectureApiService {
  Future<Either> getRecentLectures();
  Future<Either> getLectureLibrary();
  Future<Either> getLecture(String lectureId);
  Future<Either> getSubjects();
  Future<Either> getSubjectLectures(String subjectId);
  Future<Either> getLectureTracks(String lectureId);
  Future<Either> toggleSavedLecture(String lectureId);
  Future<bool> isSavedLecture(String lectureId);
  Future<Either> getSavedLectures();
  Future<Either> deleteLecture(String lectureId);
  Future<Either> regenerateLecture(String lectureId);
}

class LectureApiServiceImpl extends LectureApiService {
  static const _tokenKey = 'auth_token';
  static const _savedLectureIdsKey = 'saved_lecture_ids';

  final http.Client _client;
  final SharedPreferences _preferences;

  LectureApiServiceImpl({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _client = client,
        _preferences = preferences;

  @override
  Future<Either> getRecentLectures() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.libraryHome),
        headers: _authorizedHeaders(),
      );

      if (!_isSuccess(response.statusCode)) {
        return Left(
            _extractError(response.body, 'Unable to load recent lectures.'));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final lectures = (body['recent_lectures'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final items = await Future.wait(lectures.map(_buildLectureCard));
      return Right(items);
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> getLectureLibrary() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.lectures),
        headers: _authorizedHeaders(),
      );

      if (!_isSuccess(response.statusCode)) {
        return Left(_extractError(response.body, 'Unable to load lectures.'));
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      final lectures = body.cast<Map<String, dynamic>>();
      final items = await Future.wait(lectures.map(_buildLectureCard));
      return Right(items);
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> getSubjects() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.subjects),
        headers: _authorizedHeaders(),
      );

      if (!_isSuccess(response.statusCode)) {
        return Left(_extractError(response.body, 'Unable to load subjects.'));
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      final subjects = body.cast<Map<String, dynamic>>();
      return Right(subjects);
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> getSubjectLectures(String subjectId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.subjectLectures(subjectId)),
        headers: _authorizedHeaders(),
      );

      if (!_isSuccess(response.statusCode)) {
        return Left(_extractError(response.body, 'Unable to load subject lectures.'));
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      final lectures = body.cast<Map<String, dynamic>>();
      final items = await Future.wait(lectures.map(_buildLectureCard));
      return Right(items);
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> toggleSavedLecture(String lectureId) async {
    final savedLectureIds =
        _preferences.getStringList(_savedLectureIdsKey) ?? <String>[];
    late bool isSaved;

    if (savedLectureIds.contains(lectureId)) {
      savedLectureIds.remove(lectureId);
      isSaved = false;
    } else {
      savedLectureIds.add(lectureId);
      isSaved = true;
    }

    await _preferences.setStringList(_savedLectureIdsKey, savedLectureIds);
    return Right(isSaved);
  }

  @override
  Future<bool> isSavedLecture(String lectureId) async {
    final savedLectureIds =
        _preferences.getStringList(_savedLectureIdsKey) ?? <String>[];
    return savedLectureIds.contains(lectureId);
  }

  @override
  Future<Either> getSavedLectures() async {
    final result = await getLectureLibrary();
    return result.fold(
      (failure) => Left(failure),
      (items) {
        final savedLectureIds =
            _preferences.getStringList(_savedLectureIdsKey) ?? <String>[];
        final lectures = (items as List<LectureEntity>)
            .where((lecture) => savedLectureIds.contains(lecture.lectureId))
            .toList();
        return Right(lectures);
      },
    );
  }

  @override
  Future<Either> deleteLecture(String lectureId) async {
    try {
      final response = await _client.delete(
        Uri.parse(ApiUrls.lectureById(lectureId)),
        headers: _authorizedHeaders(),
      );

      if (_isSuccess(response.statusCode)) {
        final savedLectureIds = _preferences.getStringList(_savedLectureIdsKey) ?? <String>[];
        savedLectureIds.remove(lectureId);
        await _preferences.setStringList(_savedLectureIdsKey, savedLectureIds);
        return const Right(true);
      }

      return Left(_extractError(response.body, 'Unable to delete lecture.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> getLectureTracks(String lectureId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.lectureTracks(lectureId)),
        headers: _authorizedHeaders(),
      );

      if (!_isSuccess(response.statusCode)) {
        return Left(_extractError(response.body, 'Unable to load lecture tracks.'));
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      final tracks = body.cast<Map<String, dynamic>>().map((track) {
        final mediaUrl = track['media_url'] as String?;
        final fullUrl = _resolveMediaUrl(mediaUrl);

        return {
          ...track,
          'media_url': fullUrl,
        };
      }).toList();

      return Right(tracks);
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  @override
  Future<Either> regenerateLecture(String lectureId) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.lectureRegenerate(lectureId)),
        headers: _authorizedHeaders(),
      );

      if (_isSuccess(response.statusCode)) {
        return const Right(true);
      }

      return Left(_extractError(response.body, 'Unable to regenerate lecture.'));
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  Future<LectureEntity> _buildLectureCard(Map<String, dynamic> lecture) async {
    final lectureId = lecture['id'] as String;
    final isSaved = await isSavedLecture(lectureId);
    final audioUrl = _resolveMediaUrl(lecture['primary_audio_url'] as String?);
    final duration = (lecture['total_duration_seconds'] as num?)?.toInt() ?? 0;

    return LectureEntity(
      title: lecture['title'] as String? ?? 'Untitled Lecture',
      summary: _buildSubtitle(lecture),
      duration: duration,
      audioUrl: audioUrl,
      imageUrl: null,
      isSaved: isSaved,
      lectureId: lectureId,
    );
  }

  @override
  Future<Either> getLecture(String lectureId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.lectureById(lectureId)),
        headers: _authorizedHeaders(),
      );

      if (!_isSuccess(response.statusCode)) {
        return Left(_extractError(response.body, 'Unable to load lecture.'));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final item = await _buildLectureCard(body);
      return Right(item);
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  String _buildSubtitle(Map<String, dynamic> lecture) {
    final description = (lecture['description'] as String?)?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }

    final voiceOption = lecture['voice_option'] as String?;
    if (voiceOption != null && voiceOption.isNotEmpty) {
      return '${voiceOption[0].toUpperCase()}${voiceOption.substring(1)} voice lecture';
    }

    return 'Generated lecture';
  }

  Map<String, String> _authorizedHeaders() {
    final token = _preferences.getString(_tokenKey) ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  String _extractError(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return fallback;
  }

  String? _resolveMediaUrl(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return null;
    }
    if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
      return mediaUrl;
    }
    return '${ApiUrls.baseUrl}$mediaUrl';
  }
}
