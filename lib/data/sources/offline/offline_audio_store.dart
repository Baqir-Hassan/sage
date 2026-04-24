import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_audio_store_stub.dart'
    if (dart.library.io) 'offline_audio_store_io.dart';

abstract class OfflineAudioStore {
  Future<String?> getLocalPath(String lectureId);
  Future<bool> isDownloaded(String lectureId);
  Future<String?> download(String lectureId, String url);
  Future<void> remove(String lectureId);
}

OfflineAudioStore createOfflineAudioStore({
  required http.Client client,
  required SharedPreferences preferences,
}) {
  return createPlatformOfflineAudioStore(
    client: client,
    preferences: preferences,
  );
}
