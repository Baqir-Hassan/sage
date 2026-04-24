import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sage/presentation/lecture_player/bloc/lecture_player_state.dart';

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
    required String url,
    required String title,
    required String summary,
    String? imageUrl,
  }) async {
    if (url.isEmpty) {
      emit(
        LecturePlayerFailure(),
      );
      return;
    }

    try {
      await audioPlayer.setAudioSource(
        AudioSource.uri(
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
        ),
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

  @override
  Future<void> close() {
    audioPlayer.dispose();
    return super.close();
  }
}
