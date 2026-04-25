import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_audio_store.dart';

class StubOfflineAudioStore implements OfflineAudioStore {
  @override
  Future<String?> download(String lectureId, String url, {Map<String, String>? headers}) async => null;

  @override
  Future<String?> getLocalPath(String lectureId) async => null;

  @override
  Future<bool> isDownloaded(String lectureId) async => false;

  @override
  Future<void> remove(String lectureId) async {}
}

OfflineAudioStore createPlatformOfflineAudioStore({
  required http.Client client,
  required SharedPreferences preferences,
}) {
  return StubOfflineAudioStore();
}
