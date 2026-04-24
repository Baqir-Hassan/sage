import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/domain/usecase/lecture/get_saved_lectures.dart';
import 'package:sage/presentation/profile/bloc/saved_lectures_state.dart';
import 'package:sage/service_locator.dart';

class SavedLecturesCubit extends Cubit<SavedLecturesState> {
  SavedLecturesCubit() : super(SavedLecturesLoading());

  List<LectureEntity> savedLectures = [];

  Future<void> getSavedLectures() async {
    final result = await sl<GetSavedLecturesUseCase>().call();

    result.fold(
      (_) {
        emit(
          SavedLecturesFailure(),
        );
      },
      (lectures) {
        savedLectures = lectures;
        emit(
          SavedLecturesLoaded(savedLectures: savedLectures),
        );
      },
    );
  }

  Future<void> removeLecture(int index) async {
    savedLectures.removeAt(index);

    emit(SavedLecturesLoaded(savedLectures: savedLectures));
  }
}
