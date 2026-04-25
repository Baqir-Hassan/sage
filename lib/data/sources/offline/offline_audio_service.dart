import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/data/sources/auth/auth_token_provider.dart';
import 'package:sage/service_locator.dart';

import 'offline_audio_store.dart';

class OfflineAudioService {
  final OfflineAudioStore _store;
  final AuthTokenProvider _tokenProvider = sl<AuthTokenProvider>();

  OfflineAudioService({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _store = createOfflineAudioStore(
          client: client,
          preferences: preferences,
        );

  Future<String?> downloadLecture({
    required String lectureId,
    required String url,
  }) {
    final headers = _getDownloadHeaders(url);
    return _store.download(lectureId, url, headers: headers);
  }

  Map<String, String>? _getDownloadHeaders(String url) {
    final token = _tokenProvider.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final apiUri = Uri.tryParse(ApiUrls.baseUrl);
    if (apiUri == null) {
      return null;
    }

    final requestUri = Uri.tryParse(url);
    if (requestUri == null) {
      return null;
    }

    final resolvedUri = requestUri.hasScheme
        ? requestUri
        : apiUri.resolveUri(requestUri);
    if (resolvedUri.scheme != 'https') {
      return null;
    }
    if (resolvedUri.host != apiUri.host) {
      return null;
    }
    final protectedPath = resolvedUri.path.startsWith('/api/') ||
        resolvedUri.path.startsWith('/media/');
    if (protectedPath) {
      return {'Authorization': 'Bearer $token'};
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
