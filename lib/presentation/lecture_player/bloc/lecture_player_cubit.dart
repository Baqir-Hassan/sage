import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/data/sources/offline/offline_audio_service.dart';
import 'package:sage/presentation/lecture_player/bloc/lecture_player_state.dart';
import 'package:sage/service_locator.dart';

class LecturePlayerCubit extends Cubit<LecturePlayerState> {
  final AudioPlayer audioPlayer = AudioPlayer();

  Duration playbackDuration = Duration.zero;
  Duration playbackPosition = Duration.zero;

  LecturePlayerCubit() : super(LecturePlayerLoading()) {
    audioPlayer.positionStream.listen((position) {
      playbackPosition = position;
      updateLecturePlayer();
    });

    audioPlayer.durationStream.listen((duration) {
      playbackDuration = duration ?? Duration.zero;
      updateLecturePlayer();
    });

    audioPlayer.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        playbackPosition = playbackDuration;
        await audioPlayer.pause();
        await audioPlayer.seek(Duration.zero);
      }
      updateLecturePlayer();
    });

    audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (error) {
        debugPrint('Audio playback error: $error');
        emit(
          LecturePlayerFailure(),
        );
      },
    );
  }

  void updateLecturePlayer() {
    emit(
      LecturePlayerLoaded(),
    );
  }

  Map<String, String>? _headersFor(String url) {
    try {
      final token = sl<SharedPreferences>().getString('auth_token');
      
      if (token == null || token.isEmpty) {
        debugPrint('[_headersFor] No auth token available');
        return null;
      }

      final mediaUri = Uri.tryParse(url);
      final apiUri = Uri.tryParse(ApiUrls.baseUrl);
      
      if (mediaUri == null || apiUri == null) {
        debugPrint('[_headersFor] Failed to parse URLs - mediaUri: $mediaUri, apiUri: $apiUri');
        return null;
      }

      debugPrint('[_headersFor] Media host: ${mediaUri.host}, API host: ${apiUri.host}');
      debugPrint('[_headersFor] Media path: ${mediaUri.path}');

      final sameHost = mediaUri.host == apiUri.host;
      final protectedPath =
          mediaUri.path.startsWith('/api/') || mediaUri.path.startsWith('/media/');

      if (!sameHost || !protectedPath) {
        debugPrint('[_headersFor] No auth headers needed (sameHost: $sameHost, protectedPath: $protectedPath)');
        return null;
      }

      debugPrint('[_headersFor] Adding auth headers for protected API resource');
      return {
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint('[_headersFor] Exception: $e');
      return null;
    }
  }

  Future<bool> _tryLoadLocal(String path) async {
    try {
      debugPrint('=== ATTEMPTING LOCAL LOAD ===');
      debugPrint('Raw path: $path');
      
      if (path.isEmpty) {
        debugPrint('Path is empty, skipping local load');
        return false;
      }
      
      // Try multiple path formats for Android compatibility
      final pathsToTry = [
        path, // Raw path as-is
        'file://$path', // With file:// scheme
        if (!path.startsWith('file://')) 'file://$path',
      ];
      
      for (final tryPath in pathsToTry) {
        try {
          debugPrint('Trying to load with path: $tryPath');
          await audioPlayer.setFilePath(tryPath);
          debugPrint('✓ Successfully loaded local audio with path: $tryPath');
          return true;
        } catch (e) {
          debugPrint('✗ Failed with path format $tryPath: $e');
        }
      }
      
      debugPrint('✗ All local path formats failed for: $path');
      return false;
    } catch (e, stackTrace) {
      debugPrint('✗ Exception in _tryLoadLocal: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _tryLoadRemote(String url) async {
    try {
      debugPrint('=== ATTEMPTING REMOTE LOAD ===');
      debugPrint('URL: $url');
      debugPrint('URL is empty: ${url.isEmpty}');
      
      if (url.isEmpty) {
        debugPrint('URL is empty, skipping remote load');
        return false;
      }
      
      // Check if this is an S3 URL that might need special handling
      final headers = _headersFor(url);
      if (headers != null) {
        debugPrint('Using auth headers - Bearer token included');
      } else {
        debugPrint('No auth headers needed for this URL');
      }
      
      debugPrint('Calling audioPlayer.setUrl()...');
      await audioPlayer.setUrl(
        url,
        headers: headers,
      );
      debugPrint('✓ Successfully loaded remote audio: $url');
      return true;
    } catch (e, stackTrace) {
      debugPrint('✗ Failed to load remote audio [$url]: $e');
      debugPrintStack(stackTrace: stackTrace);
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
    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║          LECTURE AUDIO LOADING STARTED                 ║');
    debugPrint('╚════════════════════════════════════════════════════════╝');
    debugPrint('Lecture ID: $lectureId');
    debugPrint('Title: $title');
    debugPrint('URL provided: ${url.isEmpty ? '(EMPTY)' : url}');
    debugPrint('Local audio path provided: ${localAudioPath?.isEmpty ?? true ? '(EMPTY)' : localAudioPath}');
    
    if (url.isEmpty && (localAudioPath == null || localAudioPath.isEmpty)) {
      debugPrint('✗ CRITICAL: Both url and localAudioPath are empty!');
      emit(LecturePlayerFailure());
      return;
    }

    try {
      playbackDuration = Duration.zero;
      playbackPosition = Duration.zero;
      await audioPlayer.stop();
      debugPrint('Audio player stopped and reset');

      final offlineAudioService = sl<OfflineAudioService>();
      final resolvedLocalPath =
          (localAudioPath != null && localAudioPath.isNotEmpty)
              ? localAudioPath
              : await offlineAudioService.getLocalLecturePath(lectureId);

      debugPrint('Resolved local path: ${resolvedLocalPath?.isEmpty ?? true ? '(NOT FOUND)' : resolvedLocalPath}');

      var didLoad = false;

      if (resolvedLocalPath != null && resolvedLocalPath.isNotEmpty) {
        debugPrint('\n→ Trying local playback first...');
        didLoad = await _tryLoadLocal(resolvedLocalPath);
      }

      if (!didLoad && url.isNotEmpty) {
        debugPrint('\n→ Local playback failed or unavailable, trying remote...');
        didLoad = await _tryLoadRemote(url);
      }

      if (!didLoad) {
        debugPrint('\n✗ FAILED: Could not load audio from any source');
        debugPrint('  - Local path available: ${resolvedLocalPath?.isNotEmpty ?? false}');
        debugPrint('  - Remote URL available: ${url.isNotEmpty}');
        emit(LecturePlayerFailure());
        return;
      }

      debugPrint('\n✓ SUCCESS: Audio loaded for lecture $lectureId');
      debugPrint('Emitting LecturePlayerLoaded state');
      emit(LecturePlayerLoaded());
    } catch (e, stackTrace) {
      debugPrint('\n✗ EXCEPTION in loadLectureAudio: $e');
      debugPrintStack(stackTrace: stackTrace);
      emit(LecturePlayerFailure());
    }
    
    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║          LECTURE AUDIO LOADING COMPLETED               ║');
    debugPrint('╚════════════════════════════════════════════════════════╝\n');
  }

  Future<void> togglePlayback() async {
    try {
      if (audioPlayer.playing) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }

      emit(
        LecturePlayerLoaded(),
      );
    } catch (_) {
      emit(
        LecturePlayerFailure(),
      );
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
    await audioPlayer.seek(target);
    playbackPosition = target;
    emit(
      LecturePlayerLoaded(),
    );
  }

  @override
  Future<void> close() {
    audioPlayer.dispose();
    return super.close();
  }
}
