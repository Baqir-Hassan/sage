import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_audio_store.dart';

class OfflineAudioService {
  final OfflineAudioStore _store;

  OfflineAudioService({
    required http.Client client,
    required SharedPreferences preferences,
  }) : _store = createOfflineAudioStore(
          client: client,
          preferences: preferences,
        );

  Future<String?> downloadLecture({
    required String lectureId,
    required String url,
  }) {
    return _store.download(lectureId, url);
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
