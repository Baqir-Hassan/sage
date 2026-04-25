import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/data/sources/audio/sage_audio_handler.dart';
import 'package:sage/data/sources/auth/auth_token_provider.dart';
import 'package:sage/data/sources/offline/offline_audio_service.dart';
import 'package:sage/presentation/lecture_player/bloc/lecture_player_state.dart';
import 'package:sage/service_locator.dart';

class LecturePlayerCubit extends Cubit<LecturePlayerState> {
  final SageAudioHandler _audioHandler = sl<SageAudioHandler>();
  final AuthTokenProvider _tokenProvider = sl<AuthTokenProvider>();
  late final AudioPlayer audioPlayer = _audioHandler.player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Duration playbackDuration = Duration.zero;
  Duration playbackPosition = Duration.zero;

  String? _currentLectureId;
  String? _currentTitle;
  String? _currentSummary;
  String? _currentImageUrl;

  LecturePlayerCubit() : super(LecturePlayerLoading()) {
    _subscriptions.add(
      audioPlayer.positionStream.listen((position) {
        playbackPosition = position;
        updateLecturePlayer();
      }),
    );

    _subscriptions.add(
      audioPlayer.durationStream.listen((duration) {
        playbackDuration = duration ?? Duration.zero;
        updateLecturePlayer();
      }),
    );

    _subscriptions.add(
      audioPlayer.playerStateStream.listen((playerState) async {
        if (playerState.processingState == ProcessingState.completed) {
          playbackPosition = playbackDuration;
          await _audioHandler.pause();
          await _audioHandler.seek(Duration.zero);
        }
        updateLecturePlayer();
      }),
    );

    _subscriptions.add(
      audioPlayer.playbackEventStream.listen(
        (_) {},
        onError: (error) {
          debugPrint('Audio playback error: $error');
          emit(LecturePlayerFailure());
        },
      ),
    );
  }

  void updateLecturePlayer() {
    emit(LecturePlayerLoaded());
  }

  Map<String, String>? _headersFor(String url) {
    try {
      final token = _tokenProvider.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final mediaUri = Uri.tryParse(url);
      final apiUri = Uri.tryParse(ApiUrls.baseUrl);
      if (mediaUri == null || apiUri == null) {
        return null;
      }

      final sameHost = mediaUri.host == apiUri.host;
      final protectedPath =
          mediaUri.path.startsWith('/api/') || mediaUri.path.startsWith('/media/');

      if (!sameHost || !protectedPath) {
        return null;
      }

      return {'Authorization': 'Bearer $token'};
    } catch (_) {
      return null;
    }
  }

  Future<bool> _tryLoadLocal(String path) async {
    try {
      if (path.isEmpty) {
        return false;
      }

      await _audioHandler.load(
        id: _currentLectureId ?? path,
        title: _currentTitle ?? 'Lecture Playback',
        summary: _currentSummary ?? 'AI narrated lesson',
        imageUrl: _currentImageUrl,
        filePath: path,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to load local audio [$path]: $e');
      return false;
    }
  }

  Future<bool> _tryLoadRemote(String url) async {
    try {
      if (url.isEmpty) {
        return false;
      }

      await _audioHandler.load(
        id: _currentLectureId ?? url,
        title: _currentTitle ?? 'Lecture Playback',
        summary: _currentSummary ?? 'AI narrated lesson',
        imageUrl: _currentImageUrl,
        url: url,
        headers: _headersFor(url),
      );
      return true;
    } catch (e) {
      debugPrint('Failed to load remote audio [$url]: $e');
      return false;
    }
  }

  Future<void> loadLectureAudio({
    required String lectureId,
    required String url,
    required String title,
    required String summary,
    String? localAudioPath,
    String? imageUrl,
  }) async {
    _currentLectureId = lectureId;
    _currentTitle = title;
    _currentSummary = summary;
    _currentImageUrl = imageUrl;

    if (url.isEmpty && (localAudioPath == null || localAudioPath.isEmpty)) {
      emit(LecturePlayerFailure());
      return;
    }

    try {
      playbackDuration = Duration.zero;
      playbackPosition = Duration.zero;
      await _audioHandler.stop();

      final offlineAudioService = sl<OfflineAudioService>();
      final resolvedLocalPath =
          (localAudioPath != null && localAudioPath.isNotEmpty)
              ? localAudioPath
              : await offlineAudioService.getLocalLecturePath(lectureId);

      var didLoad = false;
      if (resolvedLocalPath != null && resolvedLocalPath.isNotEmpty) {
        didLoad = await _tryLoadLocal(resolvedLocalPath);
      }

      if (!didLoad && url.isNotEmpty) {
        didLoad = await _tryLoadRemote(url);
      }

      if (!didLoad) {
        emit(LecturePlayerFailure());
        return;
      }

      emit(LecturePlayerLoaded());
    } catch (e, stackTrace) {
      debugPrint('Exception in loadLectureAudio: $e');
      debugPrintStack(stackTrace: stackTrace);
      emit(LecturePlayerFailure());
    }
  }

  Future<void> togglePlayback() async {
    try {
      if (audioPlayer.playing) {
        await _audioHandler.pause();
      } else {
        await _audioHandler.play();
      }
      emit(LecturePlayerLoaded());
    } catch (_) {
      emit(LecturePlayerFailure());
    }
  }

  Future<void> seekToFraction(double progress) async {
    final duration = playbackDuration;
    if (duration == Duration.zero) {
      return;
    }

    final clampedProgress = progress.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (duration.inMilliseconds * clampedProgress).round(),
    );
    await _audioHandler.seek(target);
    playbackPosition = target;
    emit(LecturePlayerLoaded());
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
