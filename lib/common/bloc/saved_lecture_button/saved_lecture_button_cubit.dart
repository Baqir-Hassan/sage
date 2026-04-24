import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/bloc/saved_lecture_button/saved_lecture_button_state.dart';
import 'package:sage/domain/usecase/lecture/toggle_saved_lecture.dart';
import 'package:sage/service_locator.dart';

class SavedLectureButtonCubit extends Cubit<SavedLectureButtonState> {
  SavedLectureButtonCubit() : super(SavedLectureButtonInitial());

  Future<void> savedLectureButtonUpdated(String lectureId) async {
    var result = await sl<ToggleSavedLectureUseCase>().call(
      params: lectureId,
    );
    result.fold(
      (l) {},
      (isSaved) {
        emit(SavedLectureButtonUpdated(
          isSaved: isSaved,
        ));
      },
    );
  }
}
