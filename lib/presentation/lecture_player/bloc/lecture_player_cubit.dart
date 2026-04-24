import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sage/data/sources/offline/offline_audio_service.dart';
import 'package:sage/presentation/lecture_player/bloc/lecture_player_state.dart';
import 'package:sage/service_locator.dart';

class LecturePlayerCubit extends Cubit<LecturePlayerState> {
  AudioPlayer audioPlayer = AudioPlayer();

  Duration playbackDuration = Duration.zero;
  Duration playbackPosition = Duration.zero;

  LecturePlayerCubit() : super(LecturePlayerLoading()) {
    audioPlayer.positionStream.listen((position) {
      playbackPosition = position;
      updateLecturePlayer();
    });

    audioPlayer.durationStream.listen((duration) {
      playbackDuration = duration ?? Duration.zero;
    });
  }

  void updateLecturePlayer() {
    emit(
      LecturePlayerLoaded(),
    );
  }

  Future<void> loadLectureAudio({
    required String lectureId,
    required String url,
    required String title,
    required String summary,
    String? localAudioPath,
    String? imageUrl,
  }) async {
    if (url.isEmpty && (localAudioPath == null || localAudioPath.isEmpty)) {
      emit(
        LecturePlayerFailure(),
      );
      return;
    }

    try {
      final offlineAudioService = sl<OfflineAudioService>();
      final resolvedLocalPath = (localAudioPath != null && localAudioPath.isNotEmpty)
          ? localAudioPath
          : await offlineAudioService.getLocalLecturePath(lectureId);

      final source = (resolvedLocalPath != null && resolvedLocalPath.isNotEmpty)
          ? AudioSource.file(
              resolvedLocalPath,
              tag: MediaItem(
                id: lectureId,
                title: title,
                album: 'Sage Lecture',
                artist: summary,
                artUri: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Uri.parse(imageUrl)
                    : null,
              ),
            )
          : AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: url,
                title: title,
                album: 'Sage Lecture',
                artist: summary,
                artUri: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Uri.parse(imageUrl)
                    : null,
              ),
            );

      await audioPlayer.setAudioSource(
        source,
      );
      emit(
        LecturePlayerLoaded(),
      );
    } catch (e) {
      emit(
        LecturePlayerFailure(),
      );
    }
  }

  void togglePlayback() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }

    emit(
      LecturePlayerLoaded(),
    );
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
