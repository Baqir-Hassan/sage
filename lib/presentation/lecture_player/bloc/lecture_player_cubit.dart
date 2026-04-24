import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
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

  Future<void> loadLectureAudio(String url) async {
    if (url.isEmpty) {
      emit(
        LecturePlayerFailure(),
      );
      return;
    }

    try {
      await audioPlayer.setUrl(url);
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
      audioPlayer.stop();
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
