import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/domain/usecase/lecture/get_lecture_library.dart';
import 'package:sage/presentation/home/bloc/lecture_library_state.dart';
import 'package:sage/service_locator.dart';

class LectureLibraryCubit extends Cubit<LectureLibraryState> {
  LectureLibraryCubit() : super(LectureLibraryLoading());

  Future<void> getLectureLibrary() async {
    var returnedLectures = await sl<GetLectureLibraryUseCase>().call();

    returnedLectures.fold(
      (l) {
        emit(LectureLibraryLoadFailure());
      },
      (data) {
        emit(
          LectureLibraryLoaded(lectures: data),
        );
      },
    );
  }
}
