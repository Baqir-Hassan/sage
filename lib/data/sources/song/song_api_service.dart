import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_with_flutter/core/constants/api_urls.dart';
import 'package:spotify_with_flutter/domain/entities/songs/songs.dart';

abstract class SongApiService {
  Future<Either> getNewsSongs();
  Future<Either> getPlayList();
  Future<Either> getSubjects();
  Future<Either> getSubjectLectures(String subjectId);
  Future<Either> getLectureTracks(String lectureId);
  Future<Either> addOrRemoveFavoriteSong(String songId);
  Future<bool> isFavoriteSong(String songId);
  Future<Either> getUserFavoriteSong();
  Future<Either> deleteLecture(String lectureId);
  Future<Either> regenerateLecture(String lectureId);
}

class SongApiServiceImpl extends SongApiService {
  static const _tokenKey = 'auth_token';
  static const _favoriteIdsKey = 'favorite_lecture_ids';

  final http.Client _client;
  final SharedPreferences _preferences;

  SongApiServiceImpl({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _client = client,
        _preferences = preferences;

  @override
  Future<Either> getNewsSongs() async {
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
  Future<Either> getPlayList() async {
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
  Future<Either> addOrRemoveFavoriteSong(String songId) async {
    final favoriteIds =
        _preferences.getStringList(_favoriteIdsKey) ?? <String>[];
    late bool isFavorite;

    if (favoriteIds.contains(songId)) {
      favoriteIds.remove(songId);
      isFavorite = false;
    } else {
      favoriteIds.add(songId);
      isFavorite = true;
    }

    await _preferences.setStringList(_favoriteIdsKey, favoriteIds);
    return Right(isFavorite);
  }

  @override
  Future<bool> isFavoriteSong(String songId) async {
    final favoriteIds =
        _preferences.getStringList(_favoriteIdsKey) ?? <String>[];
    return favoriteIds.contains(songId);
  }

  @override
  Future<Either> getUserFavoriteSong() async {
    final result = await getPlayList();
    return result.fold(
      (failure) => Left(failure),
      (items) {
        final favoriteIds =
            _preferences.getStringList(_favoriteIdsKey) ?? <String>[];
        final lectures = (items as List<SongEntity>)
            .where((lecture) => favoriteIds.contains(lecture.songId))
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
        final favoriteIds = _preferences.getStringList(_favoriteIdsKey) ?? <String>[];
        favoriteIds.remove(lectureId);
        await _preferences.setStringList(_favoriteIdsKey, favoriteIds);
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
        final fullUrl = mediaUrl == null || mediaUrl.isEmpty
            ? null
            : '${ApiUrls.baseUrl}$mediaUrl';

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

  Future<SongEntity> _buildLectureCard(Map<String, dynamic> lecture) async {
    final lectureId = lecture['id'] as String;
    final trackInfo = await _fetchPrimaryTrack(lectureId);
    final isFavorite = await isFavoriteSong(lectureId);

    return SongEntity(
      title: lecture['title'] as String? ?? 'Untitled Lecture',
      artist: _buildSubtitle(lecture),
      duration: trackInfo.durationSeconds,
      audioUrl: trackInfo.audioUrl,
      imageUrl: null,
      isFavorite: isFavorite,
      songId: lectureId,
    );
  }

  Future<_TrackInfo> _fetchPrimaryTrack(String lectureId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiUrls.lectureTracks(lectureId)),
        headers: _authorizedHeaders(),
      );
      if (!_isSuccess(response.statusCode)) {
        return const _TrackInfo(durationSeconds: 0, audioUrl: null);
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      final tracks = body.cast<Map<String, dynamic>>();
      if (tracks.isEmpty) {
        return const _TrackInfo(durationSeconds: 0, audioUrl: null);
      }

      final totalDuration = tracks.fold<int>(
        0,
        (sum, item) => sum + ((item['duration_seconds'] as num?)?.round() ?? 0),
      );
      final firstTrackUrl = tracks.first['media_url'] as String?;
      final fullUrl = firstTrackUrl == null || firstTrackUrl.isEmpty
          ? null
          : '${ApiUrls.baseUrl}$firstTrackUrl';
      return _TrackInfo(durationSeconds: totalDuration, audioUrl: fullUrl);
    } catch (_) {
      return const _TrackInfo(durationSeconds: 0, audioUrl: null);
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
}

class _TrackInfo {
  final int durationSeconds;
  final String? audioUrl;

  const _TrackInfo({
    required this.durationSeconds,
    required this.audioUrl,
  });
}
