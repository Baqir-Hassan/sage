import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_audio_store.dart';

class OfflineAudioService {
  final OfflineAudioStore _store;
  final SharedPreferences _preferences;

  OfflineAudioService({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _store = createOfflineAudioStore(
          client: client,
          preferences: preferences,
        ),
        _preferences = preferences;

  Future<String?> downloadLecture({
    required String lectureId,
    required String url,
  }) {
    final headers = _getDownloadHeaders(url);
    return _store.download(lectureId, url, headers: headers);
  }

  Map<String, String>? _getDownloadHeaders(String url) {
    final token = _preferences.getString('auth_token');
    if (token == null || token.isEmpty) {
      return null;
    }

    // If the URL requires authorization, add the token
    if (url.contains('api.sageai.live') ||
        url.startsWith('/') ||
        !url.startsWith('http')) {
      return {
        'Authorization': 'Bearer $token',
      };
    }

    return null;
  }

  Future<String?> getLocalLecturePath(String lectureId) {
    return _store.getLocalPath(lectureId);
  }

  Future<bool> isLectureDownloaded(String lectureId) {
    return _store.isDownloaded(lectureId);
  }

  Future<void> removeDownloadedLecture(String lectureId) {
    return _store.remove(lectureId);
  }
}
