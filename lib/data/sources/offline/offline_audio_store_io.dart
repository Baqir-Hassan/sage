import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_audio_store.dart';

class IoOfflineAudioStore implements OfflineAudioStore {
  static const _downloadedLecturesKey = 'downloaded_lectures';

  final http.Client _client;
  final SharedPreferences _preferences;

  IoOfflineAudioStore({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _client = client,
        _preferences = preferences;

  @override
  Future<String?> download(String lectureId, String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to download lecture audio.');
    }

    final directory = await _offlineAudioDirectory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/$lectureId.mp3');
    await file.writeAsBytes(response.bodyBytes, flush: true);

    final downloads = await _downloads();
    downloads[lectureId] = file.path;
    await _preferences.setString(_downloadedLecturesKey, jsonEncode(downloads));
    return file.path;
  }

  @override
  Future<String?> getLocalPath(String lectureId) async {
    final downloads = await _downloads();
    final path = downloads[lectureId];
    if (path == null) {
      return null;
    }

    final file = File(path);
    if (!await file.exists()) {
      downloads.remove(lectureId);
      await _preferences.setString(_downloadedLecturesKey, jsonEncode(downloads));
      return null;
    }

    return path;
  }

  @override
  Future<bool> isDownloaded(String lectureId) async {
    return (await getLocalPath(lectureId)) != null;
  }

  @override
  Future<void> remove(String lectureId) async {
    final downloads = await _downloads();
    final path = downloads.remove(lectureId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await _preferences.setString(_downloadedLecturesKey, jsonEncode(downloads));
    }
  }

  Future<Map<String, String>> _downloads() async {
    final raw = _preferences.getString(_downloadedLecturesKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return <String, String>{};
    }

    return decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  Future<Directory> _offlineAudioDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory('${root.path}/offline_audio');
  }
}

OfflineAudioStore createPlatformOfflineAudioStore({
  required http.Client client,
  required SharedPreferences preferences,
}) {
  return IoOfflineAudioStore(
    client: client,
    preferences: preferences,
  );
}
