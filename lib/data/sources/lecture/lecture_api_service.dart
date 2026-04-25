import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/data/sources/api/api_client.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/service_locator.dart';

abstract class LectureApiService {
  Future<Either> getRecentLectures();
  Future<Either> getLectureLibrary();
  Future<Either> getLecture(String lectureId);
  Future<Either> getSubjects();
  Future<Either> getSubjectLectures(String subjectId);
  Future<Either> deleteSubject(String subjectId);
  Future<Either> getLectureTracks(String lectureId);
  Future<Either> toggleSavedLecture(String lectureId);
  Future<bool> isSavedLecture(String lectureId);
  Future<Either> getSavedLectures();
  Future<Either> deleteLecture(String lectureId);
  Future<Either> regenerateLecture(String lectureId);
}

class LectureApiServiceImpl extends LectureApiService {
  static const _savedLectureIdsKey = 'saved_lecture_ids';

  final SharedPreferences _preferences;
  final ApiClient _apiClient = sl<ApiClient>();

  LectureApiServiceImpl({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  @override
  Future<Either> getRecentLectures() async {
    final result = await _apiClient.getJson(ApiUrls.libraryHome);
    return result.fold(
      (failure) => Left(failure),
      (body) async {
        if (body is! Map<String, dynamic>) {
          return const Left('Unable to load recent lectures.');
        }
        final lectures = (body['recent_lectures'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final items = await Future.wait(lectures.map(_buildLectureCard));
        return Right(items);
      },
    );
  }

  @override
  Future<Either> getLectureLibrary() async {
    final result = await _apiClient.getJson(ApiUrls.lectures);
    return result.fold(
      (failure) => Left(failure),
      (body) async {
        if (body is! List<dynamic>) {
          return const Left('Unable to load lectures.');
        }
        final lectures = body.cast<Map<String, dynamic>>();
        final items = await Future.wait(lectures.map(_buildLectureCard));
        return Right(items);
      },
    );
  }

  @override
  Future<Either> getSubjects() async {
    final result = await _apiClient.getJson(ApiUrls.subjects);
    return result.fold(
      (failure) => Left(failure),
      (body) {
        if (body is! List<dynamic>) {
          return const Left('Unable to load subjects.');
        }
        return Right(body.cast<Map<String, dynamic>>());
      },
    );
  }

  @override
  Future<Either> getSubjectLectures(String subjectId) async {
    final result = await _apiClient.getJson(ApiUrls.subjectLectures(subjectId));
    return result.fold(
      (failure) => Left(failure),
      (body) async {
        if (body is! List<dynamic>) {
          return const Left('Unable to load subject lectures.');
        }
        final lectures = body.cast<Map<String, dynamic>>();
        final items = await Future.wait(lectures.map(_buildLectureCard));
        return Right(items);
      },
    );
  }

  @override
  Future<Either> deleteSubject(String subjectId) async {
    final result = await _apiClient.deleteJson(ApiUrls.subjectById(subjectId));
    return result.fold(
      (failure) => Left(failure),
      (_) => const Right(true),
    );
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
    final result = await _apiClient.deleteJson(ApiUrls.lectureById(lectureId));
    return result.fold(
      (failure) => Left(failure),
      (_) async {
        final savedLectureIds =
            _preferences.getStringList(_savedLectureIdsKey) ?? <String>[];
        savedLectureIds.remove(lectureId);
        await _preferences.setStringList(_savedLectureIdsKey, savedLectureIds);
        return const Right(true);
      },
    );
  }

  @override
  Future<Either> getLectureTracks(String lectureId) async {
    final result = await _apiClient.getJson(ApiUrls.lectureTracks(lectureId));
    return result.fold(
      (failure) => Left(failure),
      (body) {
        if (body is! List<dynamic>) {
          return const Left('Unable to load lecture tracks.');
        }
        final tracks = body.cast<Map<String, dynamic>>().map((track) {
          final mediaUrl = track['media_url'] as String?;
          final fullUrl = _resolveMediaUrl(mediaUrl);
          return {...track, 'media_url': fullUrl};
        }).toList();
        return Right(tracks);
      },
    );
  }

  @override
  Future<Either> regenerateLecture(String lectureId) async {
    final result = await _apiClient.postJson(ApiUrls.lectureRegenerate(lectureId));
    return result.fold(
      (failure) => Left(failure),
      (_) => const Right(true),
    );
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
    final result = await _apiClient.getJson(ApiUrls.lectureById(lectureId));
    return result.fold(
      (failure) => Left(failure),
      (body) async {
        if (body is! Map<String, dynamic>) {
          return const Left('Unable to load lecture.');
        }
        final item = await _buildLectureCard(body);
        return Right(item);
      },
    );
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
